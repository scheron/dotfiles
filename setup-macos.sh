#!/usr/bin/env bash
#
# Set macOS system preferences on a fresh machine.
#   ~/.dotfiles/setup-macos.sh
#
# Idempotent: a key already holding the wanted value is reported and skipped.
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

  if defaults write "$domain" "$key" "-$type" "$value"; then
    printf '  set     %s %s = %s\n' "$domain" "$key" "$value"
    CHANGED=$((CHANGED + 1))
  else
    printf '  FAILED  %s %s\n' "$domain" "$key"
    FAILED+=("$domain $key")
  fi
}

# --- Windows ---
# Ctrl+Cmd+drag anywhere inside a window moves it, instead of having to grab
# the title bar; Ctrl+Cmd+right-drag resizes from any edge. The modifier is
# hardcoded in AppKit and cannot be remapped. AeroSpace opens every window
# floating (see aerospace/aerospace.toml), which is what makes this useful.
echo "windows"
pref -g NSWindowShouldDragOnGesture bool true

echo
if [ ${#FAILED[@]} -ne 0 ]; then
  echo "Done, with ${#FAILED[@]} failure(s):"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi

if [ "$CHANGED" -eq 0 ]; then
  echo "Done. Everything was already set."
else
  echo "Done, $CHANGED preference(s) changed."
  echo "Apps read these at launch — log out and back in to apply everywhere."
fi
