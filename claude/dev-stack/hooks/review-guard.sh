#!/usr/bin/env bash
# Stop hook (opt-in via .branch-guard): Gate OUT enforced in code. When the model
# is WRAPPING UP unreviewed changes on a fix branch, block ONCE and point it to
# /verified-review. This is the one gate git state can actually back — "unreviewed
# changes exist on a non-default branch" is unforgeable.
#
# Fail-open on every uncertainty: a spurious block (nagging a mid-work pause) is
# worse than a missed nudge. Kill-switch: ~/.claude/.dev-stack-no-review-guard

[ -f "$HOME/.claude/.dev-stack-no-review-guard" ] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=review-common.sh
. "$SCRIPT_DIR/review-common.sh" 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null || true)"

# Never loop: if we're already continuing because of a prior block, let go.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

# Opt-in repo, on a fix branch (never the default).
root="$(review_repo_root)"; [ -n "$root" ] || exit 0
[ -f "$root/.branch-guard" ] || exit 0
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
[ -z "$branch" ] && exit 0
[ "$branch" = "HEAD" ] && exit 0
[ "$branch" = "$(review_default_branch)" ] && exit 0

# There must be changes, and this exact state must be unreviewed.
review_has_changes || exit 0
m="$(review_marker_path)" || exit 0
if [ -n "$m" ] && [ -f "$m" ] && [ "$(cat "$m" 2>/dev/null)" = "$(review_fingerprint)" ]; then
  exit 0
fi

# Only nudge when the model is actually WRAPPING UP — a done-signal in its final
# message. A mid-work pause has none, so it is never blocked. Target the last
# assistant text precisely (not a raw byte grep) so earlier "done"s don't count.
tp="$(printf '%s' "$input" | jq -r '.transcript_path // ""' 2>/dev/null || true)"
[ -n "$tp" ] && [ -f "$tp" ] || exit 0
last="$(tail -n 800 "$tp" 2>/dev/null \
  | jq -rR 'fromjson? | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' 2>/dev/null \
  | tail -n 3)"
printf '%s' "$last" | grep -qiE '(^|[^a-z])(done|complete|completed|finished|fixed|resolved|готов|исправ|заверш|all set|wrapped up)([^a-z]|$)|should (now )?work|passing now|ready to (commit|merge|review|ship)' || exit 0

reason="dev-stack review gate — you're wrapping up unreviewed changes on '${branch}'. A change is not done until /verified-review has run: the reviewer runs the Verify command itself (red before, green after) and checks Standards + Spec. Run /verified-review now. If you are pausing mid-work and not done, say so and stop again — this fires once."
jq -cn --arg r "$reason" '{decision:"block", reason:$r}' 2>/dev/null || exit 0
exit 0
