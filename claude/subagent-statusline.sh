#!/bin/bash
# Subagent status line — one row per running task, below the prompt.
# Surfaces resolved model + elapsed time + token burn for every subagent, so a
# mis-pinned model (esp. Fable, which should never be an implementer) is
# obvious at a glance — Fable is flagged red AND with a ⚠ marker.
# Requires Claude Code >= v2.1.205 (per-task .model field).
# Emits one JSON line per row: {"id": "<task_id>", "content": "<row_body>"}.
#
# Note: the per-task payload has no .effort field (as of CC 2.1.212), so effort
# cannot be shown per-subagent. The guard below lights up automatically if a
# future version starts emitting it.
input=$(cat)
NOW=$(date +%s)

# ── colors (mirror statusline.sh) ─────────────────────────────────────
RESET=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'; CYAN=$'\033[36m'; WHITE=$'\033[97m'
SEP=" ${DIM}·${RESET} "

I_MODEL=$(printf '\357\213\233')   # nf-fa-microchip  U+F2DB
I_TIME=$(printf '\357\200\227')    # nf-fa-clock      U+F017
DOT=$(printf '\342\227\217')       # ● U+25CF
WARN=$(printf '\342\232\240')      # ⚠ U+26A0

echo "$input" | jq -rc \
  --argjson now "$NOW" \
  --arg reset "$RESET" --arg dim "$DIM" --arg bold "$BOLD" \
  --arg opus "$MAGENTA" --arg sonnet "$CYAN" --arg haiku "$GREEN" \
  --arg fable "$RED" --arg mgen "$WHITE" \
  --arg emax "$MAGENTA" --arg ehigh "$YELLOW" --arg emed "$CYAN" --arg elow "$GREEN" \
  --arg drun "$GREEN" --arg dfail "$RED" --arg ddone "$DIM" --arg dwait "$YELLOW" --arg dgen "$CYAN" \
  --arg imodel "$I_MODEL" --arg itime "$I_TIME" --arg sep "$SEP" --arg dot "$DOT" --arg warn "$WARN" '

  def mname: (. // "") as $m
    | if   ($m|test("opus";"i"))   then "Opus"
      elif ($m|test("sonnet";"i")) then "Sonnet"
      elif ($m|test("haiku";"i"))  then "Haiku"
      elif ($m|test("fable";"i"))  then "Fable"
      elif $m == "" then "?"
      else ($m|sub("^claude-";"")) end;

  def mcolor: (. // "") as $m
    | if   ($m|test("opus";"i"))   then $opus
      elif ($m|test("sonnet";"i")) then $sonnet
      elif ($m|test("haiku";"i"))  then $haiku
      elif ($m|test("fable";"i"))  then $fable
      else $mgen end;

  # ⚠ marker on Fable only — a mis-pinned implementer should be unmistakable
  # even in themes that render magenta (Opus) as reddish.
  def mmark: (. // "") | if test("fable";"i") then ($warn + " ") else "" end;

  def elabel: (. // "")
    | if   . == "low"    then "Low"
      elif . == "medium" then "Medium"
      elif . == "high"   then "High"
      elif . == "xhigh"  then "xHigh"
      elif . == "max"    then "Max"
      else . end;

  def ecolor: (. // "")
    | if   . == "max"                  then $emax
      elif . == "high" or . == "xhigh" then $ehigh
      elif . == "medium"               then $emed
      else $elow end;

  def scolor: (. // "")
    | if   test("run";"i")             then $drun
      elif test("fail|error";"i")      then $dfail
      elif test("done|complet";"i")    then $ddone
      elif test("pend|queue|wait";"i") then $dwait
      else $dgen end;

  def elapsed($st):
    (($now - (($st // 0)/1000)) | floor) as $d
    | if   ($st // 0) <= 0 then ""
      elif $d < 0     then ""
      elif $d < 60    then "\($d)s"
      elif $d < 3600  then "\(($d/60)|floor)m"
      else "\(($d/3600)|floor)h\((($d%3600)/60)|floor)m" end;

  def tok($n; $win):
    (if $n >= 1000 then "\(($n/1000)|floor)k" else ($n|tostring) end) as $t
    | if ($win // 0) > 0 then "\($t) (\((($n/$win)*100)|floor)%)" else $t end;

  .tasks[]?
  | (.label // .description // .type // "task") as $raw
  | (if ($raw|length) > 24 then ($raw[0:23] + "…") else $raw end) as $lbl
  | (.tokenCount // 0)  as $tc
  | (.model | mmark)    as $mk
  | (elapsed(.startTime)) as $el
  | {
      id: (.id // ""),
      content: (
        (.status | scolor) + $dot + $reset + " "
        + $dim + $lbl + $reset
        + $sep + $imodel + " " + (.model | mcolor) + $bold + $mk + (.model | mname) + $reset
        + (if (.effort // "") != ""
           then " " + (.effort | ecolor) + "(" + (.effort | elabel) + ")" + $reset
           else "" end)
        + (if $el != "" then $sep + $dim + $itime + " " + $el + $reset else "" end)
        + $sep + $dim + tok($tc; .contextWindowSize) + $reset
      )
    }
'
