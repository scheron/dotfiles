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

hotkey() {
  # hotkey <symbolic-id> <label> <character-code> <key-code> <modifiers>
  #
  # AppleSymbolicHotKeys is a nested dictionary. Export/import lets plutil
  # replace one typed entry without turning booleans and integers into strings
  # or discarding shortcuts configured elsewhere on the machine.
  local id="$1" label="$2" character="$3" key_code="$4" modifiers="$5"
  local current expected temp_dir temp_plist rc

  current="$(
    defaults export com.apple.symbolichotkeys - 2>/dev/null |
      plutil -extract "AppleSymbolicHotKeys.$id" json -o - - 2>/dev/null
  )"
  expected="{\"enabled\":true,\"value\":{\"type\":\"standard\",\"parameters\":[$character,$key_code,$modifiers]}}"

  if [ "$current" = "$expected" ]; then
    printf '  ok      %s\n' "$label"
    return
  fi

  DIFFERENT=$((DIFFERENT + 1))
  if [ "$CHECK_ONLY" -eq 1 ]; then
    printf '  differs %s\n' "$label"
    return
  fi

  temp_dir="$(mktemp -d -t dotfiles-symbolichotkeys)" || {
    printf '  FAILED  %s (could not create temporary directory)\n' "$label"
    FAILED+=("hotkey $label")
    return
  }
  temp_plist="$temp_dir/preferences.plist"
  rc=0

  if ! defaults export com.apple.symbolichotkeys "$temp_plist" 2>/dev/null; then
    plutil -create xml1 "$temp_plist" || rc=$?
    if [ "$rc" -eq 0 ]; then
      plutil -insert AppleSymbolicHotKeys -dictionary "$temp_plist" || rc=$?
    fi
  fi
  if [ "$rc" -eq 0 ]; then
    if ! plutil -replace "AppleSymbolicHotKeys.$id" -json "$expected" \
        "$temp_plist" 2>/dev/null; then
      plutil -insert "AppleSymbolicHotKeys.$id" -json "$expected" \
        "$temp_plist" || rc=$?
    fi
  fi
  if [ "$rc" -eq 0 ]; then
    defaults import com.apple.symbolichotkeys "$temp_plist" || rc=$?
  fi
  rm -f "$temp_plist"
  rmdir "$temp_dir" 2>/dev/null || true

  if [ "$rc" -eq 0 ]; then
    printf '  set     %s\n' "$label"
    CHANGED=$((CHANGED + 1))
  else
    printf '  FAILED  %s\n' "$label"
    FAILED+=("hotkey $label")
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

# These are the current shortcuts under System Settings > Keyboard > Keyboard
# Shortcuts. IDs and key codes are Apple's stable-but-undocumented symbolic
# hotkey representation. Modifier 524288 is Option.
echo "keyboard shortcuts"
hotkey 9   "Option+N: focus active or next window" 110 45 524288
hotkey 118 "Option+1: switch to Desktop 1"          49 18 524288
hotkey 119 "Option+2: switch to Desktop 2"          50 19 524288
hotkey 120 "Option+3: switch to Desktop 3"          51 20 524288
hotkey 121 "Option+4: switch to Desktop 4"          52 21 524288
hotkey 122 "Option+5: switch to Desktop 5"          53 23 524288

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
pref com.apple.dock expose-group-apps bool true

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
