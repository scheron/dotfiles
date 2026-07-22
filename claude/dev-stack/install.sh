#!/usr/bin/env bash
# Dev-only linker. NOT the supported install path.
#
# The supported install is the plugin: add this repo as a marketplace and
# install it, so the set lives in your settings.json enabledPlugins and can't
# be clobbered by an external skills manager.
#
#   claude marketplace add .      # or: /plugin marketplace add <path>
#   claude plugin install dev-stack@dev-stack
#
# This script is for iterating on skills *live* — it symlinks each skills/<name>
# into ~/.claude/skills so an edit here is picked up without reinstalling the
# plugin. It only ever manages this repo's own skill names; it never touches
# anything else already in ~/.claude/skills.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/skills" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

DRY=0 REPLACE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --replace) REPLACE=1 ;;
    *) echo "usage: $0 [--dry-run] [--replace]" >&2; exit 64 ;;
  esac
done

mkdir -p "$DEST"

linked=0 skipped=0 collided=0 replaced=0
for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  target="$DEST/$name"

  if [[ -L "$target" ]] \
     && [[ "$(cd "$target" && pwd -P)" == "$(cd "${dir%/}" && pwd -P)" ]]; then
    echo "  ok        $name (already linked here)"
    skipped=$((skipped+1))
    continue
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ $REPLACE -eq 1 ]]; then
      if [[ $DRY -eq 1 ]]; then
        echo "  would replace $name"
      else
        rm -rf "$target"
        ln -s "${dir%/}" "$target"
        echo "  replaced  $name"
      fi
      replaced=$((replaced+1))
      continue
    fi
    echo "  COLLIDE   $name (exists and isn't our link — use --replace)" >&2
    collided=$((collided+1))
    continue
  fi

  if [[ $DRY -eq 1 ]]; then
    echo "  would link $name"
  else
    ln -s "${dir%/}" "$target"
    echo "  linked    $name"
  fi
  linked=$((linked+1))
done

echo
echo "linked: $linked  replaced: $replaced  already-present: $skipped  collisions: $collided"
[[ $collided -gt 0 ]] && exit 2 || exit 0
