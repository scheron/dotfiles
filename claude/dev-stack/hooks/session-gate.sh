#!/usr/bin/env bash
# SessionStart hook (opt-in via .branch-guard): re-inject the tier gate contract
# so the plan-in / review-out discipline survives startup, /clear and compaction
# (matcher startup|clear|compact). Superpowers' one real trick — text that gets
# re-pasted after the window resets instead of fading. Silent outside opt-in repos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Opt-in: only in repos that carry the branch-guard marker. Fail-open otherwise.
root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] && [ -f "$root/.branch-guard" ] || exit 0

gate="$SCRIPT_DIR/tier-gate.md"
[ -f "$gate" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

wrapped="$(printf '<dev-stack:tier-gate>\n%s\n</dev-stack:tier-gate>' "$(cat "$gate")")"
json_str="$(printf '%s' "$wrapped" | jq -Rs .)"
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' "$json_str"
exit 0
