#!/usr/bin/env bash
# Record that the current working state has passed /verified-review, so the
# review-guard Stop hook knows this exact state was reviewed. Called by the
# verified-review skill on a PASS. Best-effort: never fail the caller.
#
#   review-mark.sh          write the marker for the current state
#   review-mark.sh --check  exit 0 if the current state is already marked reviewed
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=review-common.sh
. "$SCRIPT_DIR/review-common.sh" 2>/dev/null || exit 0

[ -n "$(review_repo_root)" ] || exit 0

case "${1:-write}" in
  --check|check)
    m="$(review_marker_path)" || exit 1
    [ -n "$m" ] && [ -f "$m" ] && [ "$(cat "$m" 2>/dev/null)" = "$(review_fingerprint)" ] && exit 0
    exit 1
    ;;
  *)
    m="$(review_marker_path)" || exit 0
    [ -n "$m" ] || exit 0
    mkdir -p "$(dirname "$m")" 2>/dev/null || exit 0
    review_fingerprint > "$m" 2>/dev/null || exit 0
    echo "review marker written for $(git rev-parse --abbrev-ref HEAD 2>/dev/null): $m"
    ;;
esac
