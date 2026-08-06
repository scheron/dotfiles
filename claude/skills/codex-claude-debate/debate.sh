#!/usr/bin/env bash
#
# Спор двух агентов разных провайдеров через общий markdown-файл.
#
#   A — Claude Code (`claude -p`)
#   B — Codex       (`codex exec`)
#
# Общей сессии между провайдерами не существует. Единственная разделяемая
# память — доска: markdown-файл, который оба читают целиком каждый ход.
# Доску пишет ЭТОТ скрипт, а не агенты: они возвращают текст на stdout,
# скрипт его подшивает. Так ход одного не может затереть ход другого.
#
# Протокол:
#   раунд 1  — вслепую, оба пишут не видя друг друга (иначе второй заякорится)
#   раунд 2+ — по очереди, каждый читает доску и обязан возразить;
#              ход кончается строкой ВЕРДИКТ: СОГЛАСЕН | СПОР
#   финал    — согласие обоих → «Решение» (exit 0)
#              раунды кончились без согласия → «Эскалация» человеку (exit 2)
#
#   debate.sh "тема" [--rounds N] [--board PATH] [--repo DIR]
#                    [--model-a M] [--model-b M] [--synth a|b|none]
#                    [--timeout SEC] [--continue]

set -euo pipefail

TOPIC=""
ROUNDS=3
BOARD=""
REPO="$PWD"
MODEL_A=""
MODEL_B=""
SYNTH="a"
CONTINUE=0
TIMEOUT=900

die() { printf 'debate: %s\n' "$1" >&2; exit 1; }

# Один предикат пустоты на весь скрипт. Раньше параллельный путь раунда 1
# проверял `[ -s ]`, а turn() — пробельную пустоту: файл из одного \n проходил
# первую проверку, и на доску уходила пустая секция, с которой дальше спорили.
blank() { [ -z "${1//[[:space:]]/}" ]; }
say() { printf '\033[36m→\033[0m %s\n' "$1" >&2; }

usage() {
  awk 'NR<3 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "$0"
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --rounds)   ROUNDS="${2:?--rounds requires a value}"; shift 2 ;;
    --board)    BOARD="${2:?--board requires a value}"; shift 2 ;;
    --repo)     REPO="${2:?--repo requires a value}"; shift 2 ;;
    --model-a)  MODEL_A="${2:?--model-a requires a value}"; shift 2 ;;
    --model-b)  MODEL_B="${2:?--model-b requires a value}"; shift 2 ;;
    --synth)    SYNTH="${2:?--synth requires a value}"; shift 2 ;;
    --timeout)  TIMEOUT="${2:?--timeout requires a value}"; shift 2 ;;
    --continue) CONTINUE=1; shift ;;
    -h|--help)  usage 0 ;;
    -*)         die "unknown flag: $1 (try --help)" ;;
    *)          [ -z "$TOPIC" ] || die "more than one topic given"; TOPIC="$1"; shift ;;
  esac
done

[ -n "$TOPIC" ] || usage 1
command -v claude >/dev/null || die "claude CLI not on PATH"
command -v codex  >/dev/null || die "codex CLI not on PATH"
command -v jq     >/dev/null || die "jq not on PATH (нужен для разбора потока claude)"
[ -d "$REPO" ]                || die "no such directory: $REPO"
case "$SYNTH" in a|b|none) ;; *) die "--synth must be a, b or none" ;; esac
case "$ROUNDS" in ''|*[!0-9]*) die "--rounds must be a number" ;; esac
[ "$ROUNDS" -ge 1 ] || die "--rounds must be at least 1"
case "$TIMEOUT" in ''|*[!0-9]*) die "--timeout must be a number of seconds (0 = без лимита)" ;; esac

REPO="$(cd "$REPO" && pwd)"

if [ -z "$BOARD" ]; then
  slug="$(printf '%s' "$TOPIC" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9а-яё]\{1,\}/-/g; s/^-//; s/-$//' \
    | cut -c1-40)"
  [ -n "$slug" ] || slug="session"
  BOARD="$REPO/thoughts/debate-$(date +%Y-%m-%d)-$slug.md"
fi
mkdir -p "$(dirname "$BOARD")"

# Логи ходов живут рядом с доской, а не в $TMP: ход виден живьём, пока идёт,
# и остаётся для разбора после.
LOGDIR="${BOARD%.md}-log"
mkdir -p "$LOGDIR"

TMP="$(mktemp -d)"
# Убить фоновые ходы: если один участник упал в параллельном раунде, второй
# иначе продолжит работать и жечь токены уже после выхода скрипта.
# Бить нужно по дереву: `jobs -p` даёт сабшелл, а сам claude/codex — его
# потомок, и убийство сабшелла его только осиротит.
descendants() { # $1 = pid — весь потомственный список, сверху вниз
  local pid="$1" child
  for child in $(pgrep -P "$pid" 2>/dev/null || true); do
    printf '%s\n' "$child"
    descendants "$child"
  done
}

# Дерево собирается заранее и гибнет сверху вниз. Если бить снизу, сабшелл
# успевает заметить смерть своего конвейера и печатает "Terminated: 15 | tee ..."
# в stderr — поверх осмысленного вывода.
kill_tree() {
  local pid="$1" all p
  all="$(descendants "$pid")"
  kill "$pid" 2>/dev/null || true
  for p in $all; do kill "$p" 2>/dev/null || true; done
}

cleanup() {
  local pids pid
  pids="$(jobs -p 2>/dev/null || true)"
  if [ -n "$pids" ]; then
    disown -a 2>/dev/null || true   # снять с учёта, чтобы не печаталось "Terminated"
    for pid in $pids; do kill_tree "$pid"; done
  fi
  rm -rf "$TMP"
  return 0
}
trap cleanup EXIT

# Зависание — класс отказов, где ненулевого кода не будет никогда: `wait` ждёт
# повисший CLI вечно. Таймаут это не проверка после вызова, а ограничитель
# самого выполнения, поэтому он здесь, а не среди guard'ов.
# На macOS нет ни timeout, ни gtimeout, так что сторож — на bash.
with_timeout() { # $1 = секунды (0 = без лимита), $2 = флаг-файл, далее команда
  local secs="$1" flag="$2"; shift 2
  rm -f "$flag"
  if [ "$secs" -eq 0 ]; then "$@"; return $?; fi

  # Весь блок — в сабшелле, чей stderr уходит в лог рядом с ходом. Там оседает
  # отчёт шелла о снятом задании ("Terminated: 15 ..."), который иначе печатался
  # бы поверх осмысленного вывода; настоящие ошибки конвейера туда же, а не в
  # /dev/null — терминал чистый, диагностика сохранена.
  ( set +e
    "$@" & cmd_pid=$!
    # Сторож помечает флагом, что убил именно он — иначе таймаут неотличим
    # от обычного падения, и в сообщении об ошибке будет враньё.
    ( sleep "$secs"; : >"$flag"; kill_tree "$cmd_pid" ) >/dev/null 2>&1 & wd_pid=$!
    rc=0
    wait "$cmd_pid" || rc=$?
    kill_tree "$wd_pid"
    exit "$rc"
  ) 2>>"${flag%.timeout}.wt.err"
}

timed_out() { [ -f "$1" ]; }

# Почему ход не состоялся — таймаут или падение. Нужен и в turn(), и в
# параллельном раунде 1, поэтому отдельно.
fail_why() { # $1 = a|b, $2 = tag
  if timed_out "$(flag_of "$1" "$2")"; then
    printf 'не уложился в %ss' "$TIMEOUT"
  else
    printf 'упал'
  fi
}

# ── участники ────────────────────────────────────────────────────────────────
#
# Каждый возвращает свой ход текстом на stdout. Оба ограничены чтением:
# доску ведёт скрипт, трогать репозиторий участникам спора незачем.

ask_a() { # $1 = prompt, $2 = tag
  local extra=() log="$LOGDIR/$2-a.jsonl"
  [ -n "$MODEL_A" ] && extra+=(--model "$MODEL_A")
  # stream-json + partial-messages — чтобы ход был виден потокенно, пока идёт.
  # Финальный текст лежит в событии result. Фильтр is_error сам ничего НЕ
  # останавливает: jq отдаёт 0 и при совпадении, и без него — ответ-ошибка
  # превращается в пустой stdout, а ловит его уже проверка blank() выше по стеку.
  # ${a[@]+"${a[@]}"} — иначе bash 3.2 под set -u падает на пустом массиве.
  # --allowedTools РАЗРЕШАЕТ, но ничего не запрещает: без денилиста Bash
  # доступен и выполняется. Codex при этом заперт в --sandbox read-only,
  # так что без этой строки гарантия «оба только читают» держалась только у B.
  ( cd "$REPO" && printf '%s' "$1" | claude -p \
      --output-format stream-json --verbose --include-partial-messages \
      --allowedTools "Read,Grep,Glob" \
      --disallowedTools "Bash,Edit,Write,NotebookEdit,Task,WebFetch,WebSearch" \
      ${extra[@]+"${extra[@]}"} 2>>"$LOGDIR/$2-a.err" ) \
    | tee "$log" \
    | jq -r 'select(.type=="result" and .is_error==false) | .result'
}

ask_b() { # $1 = prompt, $2 = tag
  local extra=() out="$LOGDIR/$2-b.out"
  [ -n "$MODEL_B" ] && extra+=(--model "$MODEL_B")
  # Свой файл на вызов: иначе упавший codex отдал бы cat на прошлый ход,
  # и повтор проехал бы как новый ответ.
  rm -f "$out"
  printf '%s' "$1" | codex exec \
    --sandbox read-only \
    --skip-git-repo-check \
    -C "$REPO" \
    -o "$out" \
    ${extra[@]+"${extra[@]}"} - >"$LOGDIR/$2-b.log" 2>&1
  cat "$out"
}

# Флаг таймаута кладём рядом с логами, а не в $TMP: turn() читает его уже
# после того, как command substitution завершилась и её сабшелл умер.
flag_of() { printf '%s/%s-%s.timeout' "$LOGDIR" "$2" "$1"; }

ask() { # $1 = a|b, $2 = prompt, $3 = tag
  local flag; flag="$(flag_of "$1" "$3")"
  case "$1" in
    a) with_timeout "$TIMEOUT" "$flag" ask_a "$2" "$3" ;;
    b) with_timeout "$TIMEOUT" "$flag" ask_b "$2" "$3" ;;
  esac
}

name_of() { case "$1" in a) echo "A · Claude" ;; b) echo "B · Codex" ;; esac; }

# ── ходы ─────────────────────────────────────────────────────────────────────

turn() { # $1 = a|b, $2 = round number, $3 = heading suffix, $4 = prompt
  local who="$1" round="$2" suffix="$3" prompt="$4" out tag="r$2"
  say "раунд $round · $(name_of "$who")$suffix   [$LOGDIR/$tag-$who-*]"
  if ! out="$(ask "$who" "$prompt" "$tag")" || blank "$out"; then
    local why="вернул пусто"
    if timed_out "$(flag_of "$who" "$tag")"; then why="$(fail_why "$who" "$tag")"; fi
    printf '\n## Раунд %s — %s%s\n\n_(ход не состоялся: %s — см. %s)_\n' \
      "$round" "$(name_of "$who")" "$suffix" "$why" "$LOGDIR" >>"$BOARD"
    die "ход $(name_of "$who") в раунде $round $why; логи: $LOGDIR, доска: $BOARD"
  fi
  printf '\n## Раунд %s — %s%s\n\n%s\n' \
    "$round" "$(name_of "$who")" "$suffix" "$out" >>"$BOARD"
  LAST_TURN_OUT="$out"
}

# Согласие засчитывается только по явной последней строке. Модели любят
# соглашаться прозой — «в целом ты прав» не должно закрывать спор.
agreed() { # $1 = текст хода
  printf '%s\n' "$1" | grep -qiE '^[[:space:]]*[*_]{0,2}ВЕРДИКТ[*_]{0,2}[[:space:]]*:[[:space:]]*[*_]{0,2}СОГЛАСЕН'
}

blind_prompt() {
  cat <<EOF
Ты участник спора двух моделей разных провайдеров. Тема:

$TOPIC

Рабочий каталог: $REPO — читай файлы, чтобы опираться на факты, а не на догадки.

Это первый ход. Позицию оппонента ты не видишь, и это намеренно: два независимых
взгляда полезнее, чем один взгляд в двух формулировках.

Дай свою позицию — от трёх до пяти конкретных тезисов. Для каждого:
на чём он держится (файл, строка, наблюдаемый факт) и при каких условиях он неверен.

Без вступления и без выводов, только тезисы. До 400 слов.
Твой текст будет вставлен в общий файл как есть — заголовок секции не добавляй.
EOF
}

round_prompt() {
  cat <<EOF
Ты участник спора двух моделей разных провайдеров. Тема:

$TOPIC

Рабочий каталог: $REPO. Ниже — доска целиком: твои прошлые ходы и ходы оппонента.

--- ДОСКА ---
$(cat "$BOARD")
--- КОНЕЦ ДОСКИ ---

Цель спора — не победить, а прийти к ОДНОМУ согласованному решению. У вас на
это $ROUNDS раундов; если согласия не будет, вопрос уйдёт человеку, и это
худший исход из трёх: он означает, что вы не смогли ни договориться, ни
внятно сформулировать, из-за чего именно.

Твой ход. Ровно в таком порядке:

1. **Где оппонент неправ.** Минимум одно конкретное возражение с обоснованием.
   Если возразить действительно нечего — напиши «возражений нет» и объясни, что
   именно тебя переубедило. Вежливое согласие без разбора — худший возможный ход.
2. **Что я меняю у себя.** Что забираешь назад или уточняешь после хода оппонента.
3. **Что осталось открытым.** Вопрос, который ход оппонента не закрыл.
4. **Решение, которое я готов подписать** — одной фразой, в текущей редакции.

Не повторяй то, что уже есть на доске. До 400 слов.
Твой текст будет вставлен в общий файл как есть — заголовок секции не добавляй.

Последняя строка хода — ровно одна из двух, без ничего после неё:

ВЕРДИКТ: СОГЛАСЕН
ВЕРДИКТ: СПОР — <что осталось нерешённым, одной фразой>

СОГЛАСЕН ставится только если выполнено всё сразу: у тебя не осталось
возражений, которые изменили бы итоговое решение; ты можешь сформулировать это
решение одной фразой; и оно совпадает с тем, к чему пришёл оппонент. Иначе —
СПОР. Согласиться раньше времени хуже, чем потратить лишний раунд: ложное
согласие даст на выходе решение, которое ни один из вас на самом деле не держит.
EOF
}

decision_prompt() {
  cat <<EOF
Ниже — доска спора двух моделей по теме:

$TOPIC

--- ДОСКА ---
$(cat "$BOARD")
--- КОНЕЦ ДОСКИ ---

Обе стороны поставили ВЕРДИКТ: СОГЛАСЕН. Запиши согласованное решение так,
чтобы по нему мог действовать человек, который спор не читал. Ровно четыре секции:

1. **Решение** — что именно решено. Конкретно и в повелительном наклонении.
2. **Почему так** — доводы, которые решение выдержало, и что было отвергнуто.
3. **Условия, при которых решение неверно** — что должно оказаться правдой,
   чтобы к нему пришлось возвращаться.
4. **Осталось открытым, но не блокирует** — что вы сознательно не решали.

Если, перечитав доску, ты видишь, что согласие было формальным и решения
на самом деле нет, — не выдумывай его. Напиши одной строкой
«СОГЛАСИЕ ЛОЖНОЕ» и объясни, что именно разошлось.

До 600 слов. Заголовок секции не добавляй.
EOF
}

escalate_prompt() {
  cat <<EOF
Ниже — доска спора двух моделей по теме:

$TOPIC

--- ДОСКА ---
$(cat "$BOARD")
--- КОНЕЦ ДОСКИ ---

Раунды кончились, согласия нет. Дальше решает человек, и он не читал спор.
Твоя задача — не пересказать спор, а подготовить решение. Ровно четыре секции:

1. **Что решено и не обсуждается** — коротко, чтобы человек не переоткрывал.
2. **Развилка** — в чём именно расхождение. Позиция A, позиция B, и цена
   ошибки в каждую сторону. Не сглаживай и не объявляй победителя.
3. **Что закрыло бы вопрос** — конкретный факт, замер или проверка, после
   которых спор решается сам. Если такое есть — это главное в документе.
4. **Вопрос человеку** — один-два вопроса, на которые нужен ответ, чтобы
   двинуться. Сформулируй так, чтобы на них можно было ответить словом.

До 600 слов. Заголовок секции не добавляй.
EOF
}

# ── прогон ───────────────────────────────────────────────────────────────────

say "доска: $BOARD"
say "логи:  $LOGDIR"
say "следить:  tail -f '$BOARD'"

start_round=1

if [ "$CONTINUE" -eq 1 ]; then
  [ -f "$BOARD" ] || die "--continue, но доски нет: $BOARD"
  last="$(grep -o '^## Раунд [0-9]\{1,\}' "$BOARD" | grep -o '[0-9]\{1,\}$' | sort -n | tail -1 || true)"
  [ -n "$last" ] || die "в доске нет ни одного раунда: $BOARD"
  start_round=$((last + 1))
  ROUNDS=$((last + ROUNDS))
  say "продолжаю $BOARD с раунда $start_round"
else
  [ ! -e "$BOARD" ] || die "доска уже существует: $BOARD (--continue, или --board с другим путём)"
  cat >"$BOARD" <<EOF
# Спор: $TOPIC

| | |
|---|---|
| A | Claude Code — \`claude -p\`${MODEL_A:+ ($MODEL_A)} |
| B | Codex — \`codex exec\`${MODEL_B:+ ($MODEL_B)} |
| Репозиторий | \`$REPO\` |
| Раундов | $ROUNDS |
| Начато | $(date '+%Y-%m-%d %H:%M') |

Первый раунд — вслепую: участники не видят друг друга. Дальше по очереди,
каждый читает доску целиком и обязан возразить. Доску ведёт скрипт;
участники только возвращают свой ход.

Каждый ход со второго раунда кончается строкой \`ВЕРДИКТ: СОГЛАСЕН\` или
\`ВЕРДИКТ: СПОР\`. Согласие обоих в одном раунде → согласованное решение.
Раунды кончились без согласия → эскалация человеку.
EOF
  # Раунд 1 — вслепую. Оба стартуют от одной темы и ничего не знают друг о друге,
  # поэтому их можно пустить параллельно.
  say "раунд 1 · вслепую, оба параллельно"
  bp="$(blind_prompt)"
  with_timeout "$TIMEOUT" "$(flag_of a r1)" ask_a "$bp" r1 >"$TMP/a1.txt" & pid_a=$!
  with_timeout "$TIMEOUT" "$(flag_of b r1)" ask_b "$bp" r1 >"$TMP/b1.txt" & pid_b=$!
  wait "$pid_a" || die "ход A в раунде 1 $(fail_why a r1) (лог: $LOGDIR/r1-a.jsonl)"
  wait "$pid_b" || die "ход B в раунде 1 $(fail_why b r1) (лог: $LOGDIR/r1-b.log)"
  a1="$(cat "$TMP/a1.txt")"; b1="$(cat "$TMP/b1.txt")"
  if blank "$a1"; then die "ход A в раунде 1 вернул пусто (лог: $LOGDIR/r1-a.jsonl)"; fi
  if blank "$b1"; then die "ход B в раунде 1 вернул пусто (лог: $LOGDIR/r1-b.log)"; fi
  printf '\n## Раунд 1 — A · Claude (вслепую)\n\n%s\n' "$a1" >>"$BOARD"
  printf '\n## Раунд 1 — B · Codex (вслепую)\n\n%s\n'  "$b1" >>"$BOARD"
  start_round=2
fi

# Дальше строго по очереди: B должен видеть свежее возражение A, а не прошлый раунд.
r="$start_round"
converged=0
agreed_at=""
while [ "$r" -le "$ROUNDS" ]; do
  turn a "$r" "" "$(round_prompt)"; out_a="$LAST_TURN_OUT"
  turn b "$r" "" "$(round_prompt)"; out_b="$LAST_TURN_OUT"

  if agreed "$out_a" && agreed "$out_b"; then
    converged=1
    agreed_at="$r"
    say "раунд $r: оба поставили СОГЛАСЕН — перехожу к решению"
    break
  fi

  if agreed "$out_a" || agreed "$out_b"; then
    say "раунд $r: согласие одностороннее, спор продолжается"
  else
    say "раунд $r: согласия нет"
  fi
  r=$((r + 1))
done

if [ "$SYNTH" = "none" ]; then
  if [ "$converged" -eq 1 ]; then
    say "согласие в раунде $agreed_at; итог не пишу (--synth none)"
  else
    say "согласия за $ROUNDS раундов нет; итог не пишу (--synth none)"
  fi
  say "готово"
  printf '%s\n' "$BOARD"
  exit 0
fi

if [ "$converged" -eq 1 ]; then
  say "решение · $(name_of "$SYNTH")   [$LOGDIR/decision-$SYNTH-*]"
  if out="$(ask "$SYNTH" "$(decision_prompt)" decision)" && ! blank "$out"; then
    printf '\n---\n\n## Решение — согласовано в раунде %s, записал %s\n\n%s\n' \
      "$agreed_at" "$(name_of "$SYNTH")" "$out" >>"$BOARD"
  else
    die "оба согласились, но решение записать не удалось; доска цела: $BOARD"
  fi
  say "готово · согласовано в раунде $agreed_at"
  printf '%s\n' "$BOARD"
  exit 0
fi

# Эскалация. Отдельный код возврата, чтобы вызывающий скрипт или ты сам
# отличили «договорились» от «не смогли» без чтения доски.
say "эскалация · $(name_of "$SYNTH")   [$LOGDIR/escalation-$SYNTH-*]"
if out="$(ask "$SYNTH" "$(escalate_prompt)" escalation)" && ! blank "$out"; then
  printf '\n---\n\n## Эскалация — за %s раундов согласия нет, решает человек\n\n%s\n' \
    "$ROUNDS" "$out" >>"$BOARD"
else
  printf '\n---\n\n## Эскалация — за %s раундов согласия нет, решает человек\n\n_(сводку записать не удалось — читай раунды выше)_\n' \
    "$ROUNDS" >>"$BOARD"
fi

printf '\n\033[33m╭─ ЭСКАЛАЦИЯ ─────────────────────────────────────────╮\033[0m\n' >&2
printf '\033[33m│\033[0m За %s раундов согласия нет. Нужно твоё решение.\n' "$ROUNDS" >&2
printf '\033[33m│\033[0m %s\n' "$BOARD" >&2
printf '\033[33m╰─────────────────────────────────────────────────────╯\033[0m\n' >&2
printf '%s\n' "$BOARD"
exit 2
