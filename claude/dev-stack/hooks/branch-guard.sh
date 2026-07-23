#!/usr/bin/env bash
# PreToolUse guard: in opt-in repos (a `.branch-guard` file at the repo root),
# deny file mutations and git commits while on the default branch, forcing a
# dedicated branch/worktree first. Fail-open on any uncertainty.

input="$(cat 2>/dev/null || true)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null || true)"

case "$tool" in
  Edit|MultiEdit|Write|NotebookEdit)
    path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null || true)"
    dir="$(dirname "$path" 2>/dev/null || true)"; [ -d "$dir" ] || dir="."
    ;;
  Bash)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)"
    printf '%s' "$cmd" | grep -qE 'git[[:space:]]+commit' || exit 0
    dir="."
    ;;
  *) exit 0 ;;
esac

root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && exit 0
[ -f "$root/.branch-guard" ] || exit 0

branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -z "$branch" ] && exit 0
[ "$branch" = "HEAD" ] && exit 0

def="$(git -C "$root" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
if [ -z "$def" ]; then
  if git -C "$root" show-ref --verify --quiet refs/heads/main 2>/dev/null; then def="main"
  elif git -C "$root" show-ref --verify --quiet refs/heads/master 2>/dev/null; then def="master"
  else def="main"; fi
fi

if [ "$branch" = "$def" ]; then
  jq -cn --arg b "$branch" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Blocked: on default branch (" + $b + ") in a dev-stack repo. Isolate before any work — /using-git-worktrees (every tier, Tier 1 included); /new-branch is the in-place fallback. Enforced, not advised.")}}' \
    2>/dev/null
fi
exit 0
