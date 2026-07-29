#!/usr/bin/env bash
# Shared helpers for the review gate (Stop hook + marker writer). Source only;
# never executed directly. Keeps the "reviewed?" fingerprint in ONE place so the
# writer and the guard can never disagree.

review_repo_root() { git rev-parse --show-toplevel 2>/dev/null; }
review_git_dir()   { git rev-parse --git-dir 2>/dev/null; }

# Default branch: origin/HEAD, else main, else master.
review_default_branch() {
  local d
  d="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  if [ -z "$d" ]; then
    if   git show-ref --verify --quiet refs/heads/main   2>/dev/null; then d="main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then d="master"
    else d="main"; fi
  fi
  printf '%s' "$d"
}

# Fingerprint the EXACT working state: current commit + changed-file list +
# tracked diff. Any commit, edit, stage or new file changes it. git hash-object
# is always present (git is required), so no shasum/sha1sum dependency.
review_fingerprint() {
  { git rev-parse HEAD          2>/dev/null
    git status --porcelain      2>/dev/null
    git diff HEAD               2>/dev/null
  } | git hash-object --stdin 2>/dev/null
}

review_marker_path() {
  local gd; gd="$(review_git_dir)" || return 1
  [ -n "$gd" ] || return 1
  printf '%s/dev-stack/reviewed' "$gd"
}

# Is there anything worth reviewing? dirty tree OR commits ahead of the base.
review_has_changes() {
  [ -n "$(git status --porcelain 2>/dev/null)" ] && return 0
  local def base
  def="$(review_default_branch)"
  base="$(git merge-base HEAD "$def" 2>/dev/null || true)"
  [ -n "$base" ] && [ -n "$(git rev-list "$base"..HEAD 2>/dev/null)" ] && return 0
  return 1
}
