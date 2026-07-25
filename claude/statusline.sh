#!/bin/bash
input=$(cat)

# ── data ──────────────────────────────────────────────────────────────
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
MODEL=$(printf '%s' "$MODEL" | sed -E 's/ *\([^)]*\)$//')   # drop trailing "(1M context)"
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
FIVEH=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
FIVEH_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
WEEK_AT=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ── colors ────────────────────────────────────────────────────────────
RESET=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
BLUE=$'\033[34m'; CYAN=$'\033[36m'; YELLOW=$'\033[33m'; WHITE=$'\033[97m'
SEP=" ${DIM}·${RESET} "

# ── icons (Nerd Font, octal UTF-8 so bash 3.2 renders them; swap freely)
I_PROJ=$(printf '\357\201\273')    # nf-fa-folder     U+F07B
I_BRANCH=$(printf '\342\216\207')  # alt-key branch   U+2387
I_MODEL=$(printf '\357\213\233')   # nf-fa-microchip  U+F2DB
I_CTX=$(printf '\357\207\200')     # nf-fa-database   U+F1C0
I_5H=$(printf '\357\200\227')      # nf-fa-clock      U+F017
I_WEEK=$(printf '\357\201\263')    # nf-fa-calendar   U+F073
I_RESET=$(printf '\357\200\241')   # nf-fa-refresh    U+F021

pct_color() {
  if [ "$1" -ge 80 ]; then printf '\033[31m'; elif [ "$1" -ge 50 ]; then printf '\033[33m'; else printf '\033[32m'; fi
}

# context-specific ramp: green until 150k AND 20% (whichever comes first),
# then yellow <50%, orange <80%, red beyond.   $1=pct(int)  $2=used tokens
ctx_color() {
  if   [ "$2" -lt 150000 ] && [ "$1" -lt 20 ]; then printf '\033[32m'      # green
  elif [ "$1" -lt 50 ];                        then printf '\033[33m'      # yellow
  elif [ "$1" -lt 80 ];                        then printf '\033[38;5;208m' # orange
  else                                              printf '\033[31m'      # red
  fi
}

effort_label() {
  case "$1" in
    low) printf 'Low';; medium) printf 'Medium';; high) printf 'High';;
    xhigh) printf 'xHigh';; max) printf 'Max';; *) printf '%s' "$1";;
  esac
}

effort_color() {
  case "$1" in
    max) printf '\033[35m';;          # magenta — strongest
    xhigh|high) printf '\033[33m';;   # yellow
    medium) printf '\033[36m';;       # cyan
    *) printf '\033[32m';;            # green — light
  esac
}

fmt_reset() {
  local now diff d h m
  now=$(date +%s)
  diff=$(( $1 - now ))
  if [ "$diff" -lt 60 ]; then printf '<1m'; return; fi
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# ── line 1: project · branch · model ──────────────────────────────────
BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_SEG=""
if [ -n "$BRANCH" ]; then
  DIRTY=""
  [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ] && DIRTY="*"
  GIT_SEG="${SEP}${CYAN}${I_BRANCH} ${BRANCH}${DIRTY}${RESET}"
fi
MODEL_SEG="${YELLOW}${I_MODEL} ${MODEL}${RESET}"
if [ -n "$EFFORT" ]; then
  MODEL_SEG="${MODEL_SEG} ${BOLD}$(effort_color "$EFFORT")($(effort_label "$EFFORT"))${RESET}"
fi
LINE1="${BLUE}${I_PROJ} $(basename "$DIR")${RESET}${GIT_SEG}${SEP}${MODEL_SEG}"

# ── line 2: context (icon used (pct)) ─────────────────────────────────
CTXC=$(ctx_color "$PCT" "$USED")
USED_K=$((USED / 1000))
LINE2="${CTXC}${I_CTX} ${BOLD}${USED_K}k${RESET}${CTXC} (${PCT}%)${RESET}"

# ── row 2 pieces: limits (5h · week) and cost, kept separate ───────────
SEGMENTS=()
if [ -n "$FIVEH" ]; then
  seg="${I_5H} 5h $(pct_color "$FIVEH")${FIVEH}%${RESET}"
  [ -n "$FIVEH_AT" ] && seg="${seg} (${I_RESET} $(fmt_reset "$FIVEH_AT"))"
  SEGMENTS+=("$seg")
fi
if [ -n "$WEEK" ]; then
  seg="${I_WEEK} 1w $(pct_color "$WEEK")${WEEK}%${RESET}"
  [ -n "$WEEK_AT" ] && seg="${seg} (${I_RESET} $(fmt_reset "$WEEK_AT"))"
  SEGMENTS+=("$seg")
fi
LIMITS=""
for s in "${SEGMENTS[@]}"; do
  if [ -z "$LIMITS" ]; then LIMITS="$s"; else LIMITS="${LIMITS}${SEP}${s}"; fi
done
COST=""
[ -n "$COST_RAW" ] && COST="${WHITE}\$$(printf '%.2f' "$COST_RAW")${RESET}"

# visible column width (ANSI stripped) — to sit cost under the context group
vlen() {
  local s
  s=$(printf '%s' "$1" | sed $'s/\033\[[0-9;]*m//g')
  printf '%s' "$s" | LC_ALL=en_US.UTF-8 wc -m | tr -d '[:space:]'
}

# ── row1: model · context   row2: limits … cost (aligned under context)
printf "%s%s%s\n" "$LINE1" "$SEP" "$LINE2"
if [ -n "$COST" ]; then
  COL=$(( $(vlen "$LINE1") + $(vlen "$SEP") ))   # column where context begins on row1
  PAD=$(( COL - $(vlen "$LIMITS") ))
  [ "$PAD" -lt 1 ] && PAD=1
  printf "%s%*s%s\n" "$LIMITS" "$PAD" "" "$COST"
elif [ -n "$LIMITS" ]; then
  printf "%s\n" "$LIMITS"
fi
