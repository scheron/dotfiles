#!/usr/bin/env bash
# Fallback isolation — cut a dedicated working branch in place. The primary
# path for every tier (Tier 1 included) is a worktree (/using-git-worktrees);
# reach here only when a worktree can't be made (sandbox denial) or is declined.
#
# Usage: new-branch.sh <type> <slug> [--from-here]
#   type        fix | feat | chore | refactor | docs | perf  (default: chore)
#   slug        short description; sanitised to kebab-case
#   --from-here branch off the CURRENT branch instead of refusing when it
#               isn't the default (ask the user before passing this)
set -euo pipefail

from_here=0
positional=()
for a in "$@"; do
  case "$a" in
    --from-here) from_here=1 ;;
    *) positional+=("$a") ;;
  esac
done
type="${positional[0]:-chore}"
raw="${positional[1]:-}"
if [ -z "$raw" ]; then
  echo "usage: new-branch.sh <type> <slug> [--from-here]" >&2
  exit 2
fi

slug="$(printf '%s' "$raw" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' _' '--' \
  | tr -cd '[:alnum:]-' \
  | sed -E 's/-+/-/g; s/^-+//; s/-+$//')"
[ -z "$slug" ] && { echo "slug is empty after sanitising: '$raw'" >&2; exit 2; }
branch="${type}/${slug}"

# Resolve the default branch (origin/HEAD, else main, else master).
def="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
if [ -z "$def" ]; then
  if git show-ref --verify --quiet refs/heads/main; then def="main"
  elif git show-ref --verify --quiet refs/heads/master; then def="master"
  else def="$(git rev-parse --abbrev-ref HEAD)"; fi
fi

# Branch-origin guard: refuse to branch off a non-default base unless told to.
cur="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
if [ "$cur" != "$def" ] && [ "$from_here" -ne 1 ]; then
  echo "refused: you are on '$cur', not the default branch '$def'." >&2
  echo "  ask the user: branch from here, or switch to '$def' first?" >&2
  echo "  then either 'git switch $def' and re-run, or re-run with --from-here." >&2
  exit 3
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "note: uncommitted changes will move onto $branch" >&2
fi

if git show-ref --verify --quiet "refs/heads/$branch"; then
  git switch "$branch"
else
  git switch -c "$branch"
fi

echo "on branch: $branch (base: $cur)"
