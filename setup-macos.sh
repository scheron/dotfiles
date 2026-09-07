#!/usr/bin/env bash
#
# Set macOS system preferences on a fresh machine.
#   ~/.dotfiles/setup-macos.sh
#
# Idempotent: a key already holding the wanted value is reported and skipped.
# Pass --check to print differences without changing anything.
# Nothing here is symlinked — `defaults` writes into ~/Library/Preferences,
# so this script is the only record of these settings. Add new ones here
# rather than running `defaults write` by hand, or the next fresh machine
# loses them.
#
# Deliberately NOT `set -e`, same as setup-brew.sh: one key that refuses to
# write must not take the rest of the run down. Failures are listed at the end.

set -uo pipefail

FAILED=()
CHANGED=0
DIFFERENT=0
CHECK_ONLY=0

case "${1:-}" in
  "") ;;
  --check) CHECK_ONLY=1 ;;
  *)
    echo "Usage: $0 [--check]" >&2
    exit 2
    ;;
esac

pref() {
  # pref <domain> <key> <type> <value>
  #
  # <domain> goes to `defaults` as-is: "-g" for the global domain, or a bundle
  # id. <type> is a defaults type flag without its dash: bool, int, float,
  # string.
  local domain="$1" key="$2" type="$3" value="$4" want current

  # `defaults read` prints booleans back as 1/0 and never true/false, so the
  # wanted value needs normalising first — otherwise every run reports a
  # change and rewrites the key.
  want="$value"
  if [ "$type" = bool ]; then
    case "$value" in
      true|yes|1) want=1 ;;
      false|no|0) want=0 ;;
    esac
  fi

  current="$(defaults read "$domain" "$key" 2>/dev/null)"
  if [ "$current" = "$want" ]; then
    printf '  ok      %s %s\n' "$domain" "$key"
    return
  fi

  DIFFERENT=$((DIFFERENT + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    [ -n "$current" ] || current='<unset>'
    printf '  differs %s %s: %s -> %s\n' "$domain" "$key" "$current" "$want"
    return
  fi

  if defaults write "$domain" "$key" "-$type" "$value"; then
    printf '  set     %s %s = %s\n' "$domain" "$key" "$value"
    CHANGED=$((CHANGED + 1))
  else
    printf '  FAILED  %s %s\n' "$domain" "$key"
    FAILED+=("$domain $key")
  fi
}

# --- Sound ---
# Silence the system alert beep and UI sound effects. The alert volume and UI
# effects are separate controls in macOS, so set both rather than muting the
# whole Mac.
echo "sound"
pref -g com.apple.sound.beep.volume float 0
pref -g com.apple.sound.beep.feedback bool false
pref -g com.apple.sound.uiaudio.enabled bool false

# --- Keyboard ---
echo "keyboard"
pref -g ApplePressAndHoldEnabled bool false
pref -g KeyRepeat int 2
pref -g InitialKeyRepeat int 25
pref -g NSAutomaticCapitalizationEnabled bool false
pref -g NSAutomaticDashSubstitutionEnabled bool false
pref -g NSAutomaticInlinePredictionEnabled bool false
pref -g NSAutomaticPeriodSubstitutionEnabled bool false
pref -g NSAutomaticQuoteSubstitutionEnabled bool false
pref -g NSAutomaticSpellingCorrectionEnabled bool false

# --- Windows ---
# Ctrl+Cmd+drag anywhere inside a window moves it, instead of having to grab
# the title bar; Ctrl+Cmd+right-drag resizes from any edge. The modifier is
# hardcoded in AppKit and cannot be remapped.
echo "windows"
pref -g NSWindowShouldDragOnGesture bool true
pref -g NSQuitAlwaysKeepsWindows bool false

# --- Dock and Spaces ---
# Keep the observed layout from this Mac and prevent Mission Control from
# reordering Spaces by recent use, otherwise numbered shortcuts become
# unpredictable.
echo "dock and spaces"
pref com.apple.dock autohide bool true
pref com.apple.dock orientation string right
pref com.apple.dock magnification bool true
pref com.apple.dock tilesize float 47
pref com.apple.dock largesize float 62
pref com.apple.dock launchanim bool false
pref com.apple.dock mru-spaces bool false

echo
if [ ${#FAILED[@]} -ne 0 ]; then
  echo "Done, with ${#FAILED[@]} failure(s):"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ "$DIFFERENT" -eq 0 ]; then
    echo "Check complete. Everything already matches."
  else
    echo "Check complete. $DIFFERENT preference(s) would change."
  fi
elif [ "$CHANGED" -eq 0 ]; then
  echo "Done. Everything was already set."
else
  echo "Done, $CHANGED preference(s) changed."
  echo "Apps read these at launch — log out and back in to apply everywhere."
fi
