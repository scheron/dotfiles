#!/usr/bin/env bash
#
# Install the herdr plugins this config binds keys to.
#   ~/.dotfiles/setup-herdr-plugins.sh
#
# herdr keeps plugins under ~/.config/herdr/plugins, which is not symlinked
# and does not come back from a `git pull`. Without this step herdr/config.toml
# binds prefix+d and prefix+shift+e to plugins that are not installed, and the
# keys silently do nothing. This script is the only record of which plugins
# those are.
#
# Idempotent: an already-installed plugin is reported and skipped.
#
# Deliberately NOT `set -e`, same as setup-brew.sh: one plugin that fails to
# build must not take the rest of the run down. Failures are listed at the end.

set -uo pipefail

FAILED=()
INSTALLED=0

MIN_HERDR=0.8.2   # auto-title's min_herdr_version, the highest of the three

# --- Preconditions ---

if ! command -v herdr >/dev/null; then
  echo "herdr is not on PATH — run setup-brew.sh first." >&2
  exit 1
fi

# auto-title's [[build]] step is a bare `go build`. The other two download a
# prebuilt binary from their GitHub release instead, so go is the only
# toolchain needed here.
if ! command -v go >/dev/null; then
  echo "go is not on PATH — run setup-brew.sh first." >&2
  exit 1
fi

have="$(herdr --version | awk '{print $2}')"
oldest="$(printf '%s\n%s\n' "$have" "$MIN_HERDR" \
  | sort -t. -k1,1n -k2,2n -k3,3n | head -1)"
if [ "$oldest" != "$MIN_HERDR" ]; then
  echo "herdr $have is too old; auto-title needs $MIN_HERDR." >&2
  echo "Run: brew upgrade herdr" >&2
  exit 1
fi

# A herdr CLI newer than the running server refuses every plugin command with
# a protocol error, so check once here rather than three times below.
LIST="$(herdr plugin list 2>&1)"
case "$LIST" in
  *protocol_mismatch*)
    echo "The running herdr server is older than the herdr CLI." >&2
    echo "Stop it, start herdr again, then re-run this script:" >&2
    echo "  herdr server stop" >&2
    exit 1
    ;;
esac

install_plugin() {
  # install_plugin <plugin-id> <owner/repo>
  #
  # The id is the one in herdr-plugin.toml, which is not derivable from the
  # repo name — herdr-reviewr installs as persiyanov.reviewr and
  # herdr-auto-title as herdr.auto-title.
  local id="$1" repo="$2" out
  if printf '%s\n' "$LIST" | grep -qF -- "- $id ("; then
    printf '  ok       %s\n' "$id"
    return
  fi
  # The install prints a manifest preview on its way through; hold it back
  # unless something fails, or it lands between the report lines.
  if out="$(herdr plugin install "$repo" -y 2>&1)"; then
    printf '  install  %s\n' "$id"
    INSTALLED=$((INSTALLED + 1))
  else
    printf '  FAILED   %s (%s)\n' "$id" "$repo"
    printf '%s\n' "$out" | sed 's/^/           /'
    FAILED+=("$id")
  fi
}

echo "plugins"
install_plugin persiyanov.reviewr persiyanov/herdr-reviewr    # prefix+d
install_plugin chmarax.herdr-nvim ChmaraX/herdr-nvim          # prefix+shift+e
install_plugin herdr.auto-title   kryptamine/herdr-auto-title # tab titles

echo
if [ ${#FAILED[@]} -ne 0 ]; then
  echo "Done, with ${#FAILED[@]} failure(s):"
  printf '  - %s\n' "${FAILED[@]}"
  exit 1
fi

if [ "$INSTALLED" -eq 0 ]; then
  echo "Done. Every plugin was already installed."
else
  echo "Done, $INSTALLED plugin(s) installed."
  echo "Startup hooks only run on a fresh server, so restart herdr:"
  echo "  herdr server stop     (then start herdr again)"
fi
