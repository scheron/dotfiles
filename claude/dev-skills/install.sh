#!/usr/bin/env bash
# The installer. Symlinks every skill directory under skills/ into
# ~/.claude/skills and each agents/<name>.md into ~/.claude/agents, so an edit
# in this repo is picked up live — no reinstall. It only ever creates links
# under this repo's own skill and agent names, and never touches a real file or
# directory it didn't make. It does sweep away *any* dangling symlink in the
# destinations — one whose target is gone points at nothing and only confuses
# whoever reads the dir next, whether or not this repo put it there. Wire the
# hooks separately (see README).
#
# A skill is any directory holding a SKILL.md, at any depth: skills/ groups them
# into folders by pipeline stage, and the search is recursive so the grouping
# costs nothing. The install itself stays flat — one link per skill, named after
# its directory — which is what the harness reads and what the plugin format
# would later reproduce. Flat installs demand unique names, so a name used twice
# anywhere in the tree is an error rather than a silent last-one-wins.
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

linked=0 skipped=0 collided=0 replaced=0 pruned=0

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

skill_names=() skill_srcs=()
while IFS= read -r skill_md; do
  [[ -n "$skill_md" ]] || continue
  src="$(dirname "$skill_md")"
  skill_names+=("$(basename "$src")")
  skill_srcs+=("$src")
done < <(find "$SKILLS_SRC" -name SKILL.md 2>/dev/null | LC_ALL=C sort)

if [[ ${#skill_names[@]} -gt 0 ]]; then
  dupes="$(printf '%s\n' "${skill_names[@]}" | LC_ALL=C sort | uniq -d)"
  if [[ -n "$dupes" ]]; then
    echo "duplicate skill names — the install is flat, so a name must be unique across skills/:" >&2
    printf '  %s\n' $dupes >&2
    exit 3
  fi

  for i in "${!skill_names[@]}"; do
    link_one "${skill_srcs[$i]}" "$SKILLS_DEST/${skill_names[$i]}" "${skill_names[$i]}"
  done
fi

for file in "$AGENTS_SRC"/*.md; do
  [[ -e "$file" ]] || continue
  link_one "$file" "$AGENTS_DEST/$(basename "$file")" "$(basename "$file")"
done

prune_dangling() {
  local dest="$1" link
  for link in "$dest"/*; do
    [[ -L "$link" ]] || continue
    [[ -e "$link" ]] && continue
    if [[ $DRY -eq 1 ]]; then
      echo "  would prune $(basename "$link") -> $(readlink "$link") (target gone)"
    else
      rm "$link"
      echo "  pruned    $(basename "$link") (target gone)"
    fi
    pruned=$((pruned+1))
  done
}

prune_dangling "$SKILLS_DEST"
prune_dangling "$AGENTS_DEST"

echo
echo "linked: $linked  replaced: $replaced  pruned: $pruned  already-present: $skipped  collisions: $collided"
[[ $collided -gt 0 ]] && exit 2 || exit 0
