#!/usr/bin/env bash
#
# Install Homebrew taps, formulae, casks and fonts on a fresh machine.
#   ~/.dotfiles/setup-brew.sh
#
# Idempotent: already-installed packages are reported and skipped.
#
# Deliberately NOT `set -e`. Packages are installed one at a time and a
# failure is recorded and stepped over, so one unavailable cask can no longer
# take the rest of the run down with it. Whatever failed is listed at the end.

set -uo pipefail

FAILED=()

tap() {
  local t="$1"
  if brew tap | grep -qx "$t"; then
    printf '  ok      tap %s\n' "$t"
  elif brew tap "$t"; then
    printf '  tap     %s\n' "$t"
  else
    printf '  FAILED  tap %s\n' "$t"
    FAILED+=("tap $t")
  fi
}

trust() {
  # trust <tap/cask>...
  #
  # Homebrew 6 refuses to load a cask from a non-official tap until it is
  # trusted, so this must run after `tap` and before `install`. Trust is
  # per-cask rather than per-tap (`brew trust <tap>` also covers whatever is
  # added to that tap later). Re-trusting is a no-op that exits 0.
  local c
  for c in "$@"; do
    if brew trust --cask "$c"; then
      printf '  trust   %s\n' "$c"
    else
      printf '  FAILED  trust %s\n' "$c"
      FAILED+=("trust $c")
    fi
  done
}

install() {
  # install <formula|cask> <pkg>...
  #
  # Casks get --adopt: an app installed by hand (dragged into /Applications) is
  # invisible to `brew list`, and a plain `brew install --cask` then dies on
  # "It seems there is already an App at ...". --adopt makes Homebrew take the
  # existing app over instead, so a machine that predates this script installs
  # cleanly. The two branches are spelled out rather than built into an options
  # array because macOS ships bash 3.2, where expanding an empty array under
  # `set -u` is an unbound-variable error.
  local kind="$1"; shift
  local pkg rc
  for pkg in "$@"; do
    if brew list "--$kind" "$pkg" >/dev/null 2>&1; then
      printf '  ok      %s\n' "$pkg"
      continue
    fi
    rc=0
    if [ "$kind" = cask ]; then
      brew install --cask --adopt "$pkg" || rc=$?
    else
      brew install --formula "$pkg" || rc=$?
    fi
    if [ "$rc" -eq 0 ]; then
      printf '  install %s\n' "$pkg"
    else
      printf '  FAILED  %s\n' "$pkg"
      FAILED+=("$pkg")
    fi
  done
}

brew update || printf '  warn    brew update failed, continuing\n'

# --- Taps ---
# These must come before the packages that live in them, or the install below
# fails with "No available formula/cask". This was the single biggest
# fresh-machine failure: aerospace and daily are both tapped.
echo "taps"
tap nikitabobko/tap   # aerospace
tap scheron/tap       # daily

echo "trust"
trust nikitabobko/tap/aerospace
trust scheron/tap/daily

# --- CLI tools ---
# go builds the herdr auto-title plugin, whose `[[build]]` step is a bare
# `go build` — the other herdr plugins fetch a prebuilt binary instead.
echo "cli"
install formula \
  git gh lazygit hunk \
  neovim \
  eza fd fzf ripgrep z \
  starship herdr \
  zsh-autosuggestions zsh-syntax-highlighting \
  fnm pnpm yarn \
  python@3.14 uv \
  jq make websocat \
  tree-sitter-cli \
  rtk \
  go

# --- Swift / iOS toolchain (drop this block if not doing Swift dev) ---
echo "swift"
install formula swift-format swiftformat xcbeautify xcode-build-server

# --- Apps ---
echo "casks"
install cask \
  ghostty \
  aerospace \
  karabiner-elements \
  cursor \
  raycast \
  claude-code codex \
  daily \
  numi spotify vlc

# --- Fonts ---
echo "fonts"
install cask \
  font-fira-code-nerd-font \
  font-geist-mono-nerd-font \
  font-iosevka-nerd-font \
  font-victor-mono-nerd-font \
  font-zed-mono-nerd-font \
  font-symbols-only-nerd-font \
  font-fragment-mono

brew cleanup || true

echo
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "Done. Everything installed."
else
  echo "Done, with ${#FAILED[@]} failure(s):"
  printf '  - %s\n' "${FAILED[@]}"
  echo "Re-run this script after fixing them; installed packages are skipped."
  exit 1
fi
