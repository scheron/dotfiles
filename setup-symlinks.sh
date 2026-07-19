#!/usr/bin/env bash
#
# Symlink dotfiles from ~/.dotfiles into their live locations.
# Idempotent: safe to re-run. An existing real file/dir at a target is
# moved aside to "<target>.backup" before the symlink is created.
#
#   ~/.dotfiles/setup-symlinks.sh

set -euo pipefail

DOTFILES="$HOME/.dotfiles"
CODE_USER="$HOME/Library/Application Support/Code/User"

link() {
  # link <path-inside-dotfiles> <absolute-target>
  local src="$DOTFILES/$1" dest="$2"
  if [ ! -e "$src" ]; then
    printf '  skip  %s (no source: %s)\n' "$dest" "$1"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    printf '  ok    %s\n' "$dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup"
    printf '  bak   %s -> %s.backup\n' "$dest" "$dest"
  fi
  ln -s "$src" "$dest"
  printf '  link  %s\n' "$dest"
}

echo "shell";     link zsh/.zshrc "$HOME/.zshrc"
                  link zsh/.zprofile "$HOME/.zprofile"
echo "git";       link .gitconfig "$HOME/.gitconfig"
                  link .gitconfig-personal "$HOME/.gitconfig-personal"
                  link .gitconfig-private "$HOME/.gitconfig-private"
echo "starship";  link starship/starship.toml "$HOME/.config/starship.toml"
echo "ghostty";   link ghostty/config "$HOME/.config/ghostty/config"
echo "aerospace"; link aerospace/aerospace.toml "$HOME/.aerospace.toml"
echo "karabiner"; link karabiner/karabiner.json "$HOME/.config/karabiner/karabiner.json"
echo "nvim";      link nvim "$HOME/.config/nvim"
echo "zed";       link zed/settings.json "$HOME/.config/zed/settings.json"
                  link zed/keymap.json "$HOME/.config/zed/keymap.json"
echo "lazygit";   link lazygit/config.yml "$HOME/.config/lazygit/config.yml"
echo "yazi";      link yazi "$HOME/.config/yazi"
echo "gh";        link gh/config.yml "$HOME/.config/gh/config.yml"
echo "claude";    for f in settings.json CLAUDE.md RTK.md statusline.sh rtk-rewrite.sh; do
                    link "claude/$f" "$HOME/.claude/$f"
                  done
echo "vscode";    link VSCode/settings.json "$CODE_USER/settings.json"
                  link VSCode/keybindings.json "$CODE_USER/keybindings.json"
                  link VSCode/snippets "$CODE_USER/snippets"

echo
echo "Done. Per-machine secrets (SSH keys, npm, gh, Claude) are set up manually — see README."
