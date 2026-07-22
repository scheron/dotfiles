#!/usr/bin/env bash
# PreToolUse(Bash) — enforce the commit-work skill on git commits.
#   * deny blanket staging (git add . / -A / --all)
#   * deny commits carrying banned trailers or a non-Conventional subject
#   * inject the commit-work rules as context on every git commit
# Fail-open: on any parsing error the command is allowed (never blocks work by accident).

input="$(cat 2>/dev/null || true)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

deny() {
  jq -cn --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}' \
    2>/dev/null
  exit 0
}

# 1) Blanket staging — commit-work: stage intentionally, never `git add .`/`-A`/`--all`.
if printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+add[[:space:]]+(-A|--all|\.)($|[[:space:]]|[;&|])'; then
  deny "Blocked by commit-work: blanket staging (git add . / -A / --all). Stage intentionally with 'git add -p' or explicit paths so only intended changes land."
fi

# Everything below concerns git commit only.
printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit' || exit 0

# 2) Banned trailers anywhere in the command (case-insensitive).
if printf '%s' "$cmd" | grep -qiE 'Co-Authored-By|Generated with Claude Code|Claude-Session:|🤖'; then
  deny "Blocked by commit-work: banned trailer present (Co-Authored-By / 'Generated with Claude Code' / Claude-Session). Remove it and retry."
fi

# 3) Conventional Commits subject — only when a -m message is cleanly extractable.
msg="$(printf '%s' "$cmd" | grep -oE "\-m[[:space:]]+\"[^\"]*\"|\-m[[:space:]]+'[^']*'" | head -1 | sed -E "s/^-m[[:space:]]+[\"']//; s/[\"']$//" 2>/dev/null || true)"
if [ -n "$msg" ]; then
  if ! printf '%s' "$msg" | grep -qE '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9._/-]+\))?!?: .+'; then
    deny "Blocked by commit-work: subject is not Conventional Commits ('$msg'). Use 'type(scope): summary' — type in feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert."
  fi
fi

# 4) Clean git commit — inject the commit-work rules as context.
jq -cn '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:"commit-work rules in force: stage only intended changes (verify with git diff --cached), Conventional Commits subject, body says what & why (not a diary), run the fastest relevant check. No Co-Authored-By / Claude footnote / Claude-Session trailer."}}' 2>/dev/null
exit 0
