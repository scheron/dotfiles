#!/usr/bin/env bash
# The installer. Symlinks each skills/<name> into ~/.claude/skills and each
# agents/<name>.md into ~/.claude/agents, so an edit in this repo is picked up
# live — no reinstall. It only ever manages this repo's own skill and agent
# names; it never touches anything else already in ~/.claude/skills or
# ~/.claude/agents. Wire the hooks separately (see README).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$ROOT/skills"
AGENTS_SRC="$ROOT/agents"
SKILLS_DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
AGENTS_DEST="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"

DRY=0 REPLACE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --replace) REPLACE=1 ;;
    *) echo "usage: $0 [--dry-run] [--replace]" >&2; exit 64 ;;
  esac
done

mkdir -p "$SKILLS_DEST" "$AGENTS_DEST"

linked=0 skipped=0 collided=0 replaced=0

link_one() {
  local src="$1" target="$2" name="$3"

  if [[ -L "$target" && "$target" -ef "$src" ]]; then
    echo "  ok        $name (already linked here)"
    skipped=$((skipped+1))
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ $REPLACE -eq 1 ]]; then
      if [[ $DRY -eq 1 ]]; then
        echo "  would replace $name"
      else
        rm -rf "$target"
        ln -s "$src" "$target"
        echo "  replaced  $name"
      fi
      replaced=$((replaced+1))
      return
    fi
    echo "  COLLIDE   $name (exists and isn't our link — use --replace)" >&2
    collided=$((collided+1))
    return
  fi

  if [[ $DRY -eq 1 ]]; then
    echo "  would link $name"
  else
    ln -s "$src" "$target"
    echo "  linked    $name"
  fi
  linked=$((linked+1))
}

for dir in "$SKILLS_SRC"/*/; do
  [[ -e "${dir%/}" ]] || continue
  link_one "${dir%/}" "$SKILLS_DEST/$(basename "$dir")" "$(basename "$dir")"
done

for file in "$AGENTS_SRC"/*.md; do
  [[ -e "$file" ]] || continue
  link_one "$file" "$AGENTS_DEST/$(basename "$file")" "$(basename "$file")"
done

echo
echo "linked: $linked  replaced: $replaced  already-present: $skipped  collisions: $collided"
[[ $collided -gt 0 ]] && exit 2 || exit 0
