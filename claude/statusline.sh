#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
FIVEH=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
RESET_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
BLUE=$'\033[34m'
CYAN=$'\033[36m'
SEP=" ${DIM}·${RESET} "

pct_color() {
  if [ "$1" -ge 80 ]; then printf '\033[31m'; elif [ "$1" -ge 50 ]; then printf '\033[33m'; else printf '\033[32m'; fi
}

fmt_reset() {
  local now diff h m
  now=$(date +%s)
  diff=$(( $1 - now ))
  if [ "$diff" -lt 60 ]; then printf '<1м'; return; fi
  h=$(( diff / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then printf '%dч %dм' "$h" "$m"; else printf '%dм' "$m"; fi
}

BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
  DIRTY=""
  [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ] && DIRTY="*"
  GIT_SEG="${SEP}${CYAN}⎇ ${BRANCH}${DIRTY}${RESET}"
else
  GIT_SEG=""
fi
PROJECT_LINE="${BLUE}$(basename "$DIR")${RESET}${GIT_SEG}"

if [ "$PCT" -ge 80 ]; then CTXC=$'\033[31m'; elif [ "$PCT" -ge 50 ]; then CTXC=$'\033[33m'; else CTXC=$'\033[32m'; fi
USED_K=$((USED / 1000))
SIZE_K=$((SIZE / 1000))
CTX_LINE="${DIM}[${MODEL}]${RESET} ${CTXC}${PCT}%${RESET} ${DIM}(${RESET}${BOLD}${USED_K}k${RESET}${DIM}/${SIZE_K}k)${RESET}"

SEGMENTS=()
[ -n "$COST_RAW" ] && SEGMENTS+=("${DIM}\$$(printf '%.2f' "$COST_RAW")${RESET}")
[ -n "$FIVEH" ] && SEGMENTS+=("⏳ $(pct_color "$FIVEH")${FIVEH}%${RESET}${DIM} 5h${RESET}")
[ -n "$RESET_AT" ] && SEGMENTS+=("${DIM}↻${RESET} $(fmt_reset "$RESET_AT")")

USAGE_LINE=""
for seg in "${SEGMENTS[@]}"; do
  if [ -z "$USAGE_LINE" ]; then USAGE_LINE="$seg"; else USAGE_LINE="${USAGE_LINE}${SEP}${seg}"; fi
done

printf "%s\n" "$PROJECT_LINE"
printf "%s\n" "$CTX_LINE"
if [ -n "$USAGE_LINE" ]; then printf "%s\n" "$USAGE_LINE"; fi
