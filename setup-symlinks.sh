#!/usr/bin/env bash
#
# Symlink dotfiles from ~/.dotfiles into their live locations.
# Idempotent: safe to re-run. An existing real file/dir at a target is
# moved aside to "<target>.backup" before the symlink is created.
#
# Re-run after any `git pull` that adds a new tracked config — pull updates
# files already symlinked, but only this script links newly added ones.
#
#   ~/.dotfiles/setup-symlinks.sh

set -euo pipefail

DOTFILES="$HOME/.dotfiles"
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"

link_abs() {
  # link_abs <absolute-source> <absolute-target>
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    printf '  skip  %s (no source: %s)\n' "$dest" "$src"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    printf '  ok    %s\n' "$dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    # Never reuse an existing backup name: `mv dir dir.backup` would move the
    # directory *inside* the old backup instead of alongside it.
    local backup="$dest.backup" n=2
    while [ -e "$backup" ] || [ -L "$backup" ]; do
      backup="$dest.backup.$n"
      n=$((n + 1))
    done
    mv "$dest" "$backup"
    printf '  bak   %s -> %s\n' "$dest" "$backup"
  fi
  ln -s "$src" "$dest"
  printf '  link  %s\n' "$dest"
}

link() {
  # link <path-inside-dotfiles> <absolute-target>
  link_abs "$DOTFILES/$1" "$2"
}

prune_dangling() {
  # prune_dangling <root> <maxdepth>
  # This script only ever creates links, so a config that moves to .archive/
  # leaves its old symlink behind pointing at nothing. Remove only links that
  # point back into this repo — a broken link owned by something else is not
  # ours to delete. Keep maxdepth tight: walking all of $HOME is slow and
  # trips macOS privacy errors on Library, Photos and Trash.
  [ -d "$1" ] || return 0
  find "$1" -maxdepth "$2" -type l | while read -r l; do
    if [ -e "$l" ]; then continue; fi
    case "$(readlink "$l")" in
      "$DOTFILES"/*)
        rm "$l"
        printf '  prune %s\n' "$l"
        ;;
    esac
  done
}

echo "shell";     link zsh/.zshrc "$HOME/.zshrc"
                  link zsh/.zprofile "$HOME/.zprofile"
echo "git";       link .gitconfig "$HOME/.gitconfig"
                  link .gitconfig-personal "$HOME/.gitconfig-personal"
                  link .gitconfig-private "$HOME/.gitconfig-private"
                  link .gitconfig-work "$HOME/.gitconfig-work"
echo "starship";  link starship/starship.toml "$HOME/.config/starship.toml"
echo "ghostty";   link ghostty/config "$HOME/.config/ghostty/config"
echo "herdr";     link herdr/config.toml "$HOME/.config/herdr/config.toml"
echo "hunk";      link hunk/config.toml "$HOME/.config/hunk/config.toml"
echo "aerospace"; link aerospace/aerospace.toml "$HOME/.aerospace.toml"
echo "karabiner"; link karabiner/karabiner.json "$HOME/.config/karabiner/karabiner.json"
echo "nvim";      link nvim "$HOME/.config/nvim"
echo "lazygit";   link lazygit/config.yml "$HOME/.config/lazygit/config.yml"
echo "gh";        link gh/config.yml "$HOME/.config/gh/config.yml"
echo "claude";    for f in settings.json CLAUDE.md RTK.md statusline.sh subagent-statusline.sh rtk-rewrite.sh; do
                    link "claude/$f" "$HOME/.claude/$f"
                  done
echo "claude skills"
                  # Standalone skills bucket — every claude/skills/<name> is
                  # linked into ~/.claude/skills. Drop a new skill dir here and
                  # re-run; it gets picked up with no edit to this script.
                  for d in "$DOTFILES/claude/skills"/*/; do
                    [ -d "$d" ] || continue
                    name="$(basename "$d")"
                    link "claude/skills/$name" "$HOME/.claude/skills/$name"
                  done
                  # hunk ships its own review skill inside the Homebrew keg.
                  # Link from `brew --prefix` (the version-independent opt path,
                  # not the Cellar path) so a `brew upgrade hunk` cannot leave
                  # this pointing at a version that no longer exists.
                  if hunk_prefix="$(brew --prefix hunk 2>/dev/null)"; then
                    link_abs "$hunk_prefix/libexec/skills/hunk-review" \
                             "$HOME/.claude/skills/hunk-review"
                  else
                    printf '  skip  %s (hunk not installed — run setup-brew.sh)\n' \
                           "$HOME/.claude/skills/hunk-review"
                  fi
echo "cursor";    link Cursor/settings.json "$CURSOR_USER/settings.json"
                  link Cursor/keybindings.json "$CURSOR_USER/keybindings.json"
                  link Cursor/snippets "$CURSOR_USER/snippets"
echo "prune";     prune_dangling "$HOME" 1
                  prune_dangling "$HOME/.config" 3
                  prune_dangling "$HOME/.claude" 2
                  prune_dangling "$CURSOR_USER" 1

echo
echo "Done. Per-machine secrets (SSH keys, npm, gh, Claude) are set up manually — see README."
