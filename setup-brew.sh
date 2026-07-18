#!/usr/bin/env bash
#
# Install Homebrew formulae, casks and fonts on a fresh machine.
#   ~/.dotfiles/setup-brew.sh

set -euo pipefail

brew update
brew upgrade

# --- CLI tools ---
brew install \
  git gh lazygit \
  neovim \
  eza fd fzf ripgrep z \
  starship \
  zsh-autosuggestions zsh-syntax-highlighting \
  node pnpm yarn n \
  python@3.14 uv \
  jq make websocat \
  tree-sitter-cli \
  podman

# --- Swift / iOS toolchain (drop this line if not doing Swift dev) ---
brew install swift-format swiftformat xcbeautify xcode-build-server

# --- Apps ---
brew install --cask \
  ghostty \
  aerospace swipeaerospace \
  karabiner-elements \
  zed visual-studio-code \
  raycast \
  claude-code codex \
  logi-options+ \
  numi spotify vlc

# --- Fonts ---
brew install --cask \
  font-fira-code-nerd-font \
  font-symbols-only-nerd-font \
  font-fragment-mono
# "Dank Mono" (editor font referenced in configs) is a paid font — install it manually.

# --- Personal tools (need their own taps; uncomment after adding the tap) ---
# brew install rtk           # token-killer CLI proxy
# brew install --cask daily  # scheron/tap

brew cleanup
