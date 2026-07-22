#!/usr/bin/env bash
# Create a dedicated working branch off the default branch — the Tier 1
# isolation floor. Tier 2/3 use a worktree (/using-git-worktrees) instead.
#
# Usage: new-branch.sh <type> <slug>
#   type  fix | feat | chore | refactor | docs | perf  (default: chore)
#   slug  short description; sanitised to kebab-case
set -euo pipefail

type="${1:-chore}"
raw="${2:-}"
if [ -z "$raw" ]; then
  echo "usage: new-branch.sh <type> <slug>" >&2
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

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "note: uncommitted changes will move onto $branch" >&2
fi

if git show-ref --verify --quiet "refs/heads/$branch"; then
  git switch "$branch"
else
  git switch -c "$branch"
fi

echo "on branch: $branch (base: $def)"
