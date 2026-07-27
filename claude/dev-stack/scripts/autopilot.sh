#!/usr/bin/env bash
# autopilot.sh — the dev-stack batch runner. Drives a set of tickets through the
# `/to-implement` engine one at a time, in dependency order, UNATTENDED: for each
# frontier ticket it spawns a fresh headless `claude -p "/to-implement <ticket>"`
# session under --permission-mode auto, advances when that session leaves a
# success sentinel, and HALTS on the first red. The loop is dumb on purpose — all
# durable truth lives on disk (sentinels), so a killed run resumes by re-running
# the same command: it recomputes the frontier and skips what already landed.
#
# The safety spine is DEV_STACK_AUTOPILOT=1, exported ONLY here. Every autopilot
# branch in the skills and hooks is gated on it, so with it unset the interactive
# pipeline behaves byte-for-byte as before.
#
# Usage:
#   autopilot.sh [--feature <slug>] [--integration-branch <b>] [--base <ref>]
#                [--dry-run] <N,N,...>
#
#   <N,N,...>  ticket numbers to run (e.g. 1,2,3 or 01,02,04). Order is ignored;
#              the runner topologically sorts by each ticket's "Blocked by" edges.
#   --dry-run  validate + print the plan (used to render the skill's STOP-gate),
#              spawn nothing.
set -uo pipefail

die() { printf 'autopilot: %s\n' "$*" >&2; exit 1; }

# ── args ─────────────────────────────────────────────────────────────────────
FEATURE=""; INTEGRATION=""; BASE=""; DRYRUN=0; BATCH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --feature)             FEATURE="${2:?}"; shift 2 ;;
    --integration-branch)  INTEGRATION="${2:?}"; shift 2 ;;
    --base)                BASE="${2:?}"; shift 2 ;;
    --dry-run)             DRYRUN=1; shift ;;
    -*)                    die "unknown flag: $1" ;;
    *)                     BATCH="$1"; shift ;;
  esac
done
[ -n "$BATCH" ] || die "no ticket batch given (e.g. autopilot.sh 1,2,3)"

# ── repo + feature + state locations ─────────────────────────────────────────
REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repo"
[ -z "$(git -C "$REPO" status --porcelain)" ] || die "working tree is dirty — commit or stash before an autopilot run"

# Feature dir under .scratch/<slug>/issues (the local-file ticket layout /to-tickets
# writes). Auto-detect when exactly one exists.
if [ -z "$FEATURE" ]; then
  _feats=()
  while IFS= read -r _f; do [ -n "$_f" ] && _feats+=("$_f"); done \
    < <(find "$REPO/.scratch" -maxdepth 2 -type d -name issues 2>/dev/null | sed -E 's#.*/\.scratch/([^/]+)/issues#\1#')
  [ "${#_feats[@]}" -eq 1 ] || die "found ${#_feats[@]} feature dirs under .scratch/*/issues — pass --feature <slug>"
  FEATURE="${_feats[0]}"
fi
ISSUES="$REPO/.scratch/$FEATURE/issues"
[ -d "$ISSUES" ] || die "no ticket dir at $ISSUES"

# State lives in the git COMMON dir — outside any worktree's working tree, so it
# survives the worktree churn (finish-branch deletes the ticket worktree + its
# .scratch) and anchors resume. Same idiom as the review marker.
GIT_COMMON="$(cd "$(git -C "$REPO" rev-parse --git-common-dir)" && pwd -P)" || die "cannot resolve git-common-dir"
STATEDIR="$GIT_COMMON/dev-stack/autopilot/$FEATURE"
mkdir -p "$STATEDIR"

INTEGRATION="${INTEGRATION:-autopilot/$FEATURE}"
BASE="${BASE:-$(git -C "$REPO" rev-parse --abbrev-ref HEAD)}"

# ── ticket model ─────────────────────────────────────────────────────────────
# Normalize a ticket token to the zero-padded 2-digit id used in filenames.
norm() { local n="$1"; n="${n#"${n%%[!0]*}"}"; [ -n "$n" ] || n=0; printf '%02d' "$n"; }

ticket_file() { local f; f=$(ls "$ISSUES/$1"-*.md 2>/dev/null | head -1); [ -n "$f" ] && printf '%s' "$f"; }
done_flag()   { [ -f "$STATEDIR/$1.done" ]; }

# Blockers of a ticket: the 2-digit numbers on its "Blocked by" line. "None" → none.
blockers() {
  local f; f="$(ticket_file "$1")" || return 0
  [ -n "$f" ] || return 0
  local line; line="$(grep -iE 'Blocked by' "$f" | head -1)"
  printf '%s' "$line" | grep -qi 'none' && return 0
  printf '%s' "$line" | grep -oE '[0-9]{1,2}' | while read -r n; do norm "$n"; printf '\n'; done
}

# Parse + validate the batch.
BATCH_IDS=()
IFS=',' read -ra _raw <<< "$BATCH"
for t in "${_raw[@]}"; do
  t="$(printf '%s' "$t" | tr -d '[:space:]')"; [ -n "$t" ] || continue
  id="$(norm "$t")"
  [ -n "$(ticket_file "$id")" ] || die "ticket $id not found under $ISSUES"
  BATCH_IDS+=("$id")
done
[ "${#BATCH_IDS[@]}" -gt 0 ] || die "no valid tickets parsed from batch '$BATCH'"
in_batch() { local x; for x in "${BATCH_IDS[@]}"; do [ "$x" = "$1" ] && return 0; done; return 1; }

# Closure: every blocker of a batch ticket must be in the batch OR already done.
for id in "${BATCH_IDS[@]}"; do
  while read -r b; do
    [ -n "$b" ] || continue
    if ! in_batch "$b" && ! done_flag "$b"; then
      die "ticket $id is blocked by $b, which is neither in the batch nor already landed — add it to the batch or run it first"
    fi
  done < <(blockers "$id")
done

# Frontier: batch tickets not yet done whose blockers are all done. Sequential
# policy takes the lowest id.
frontier() {
  local id ok b
  for id in $(printf '%s\n' "${BATCH_IDS[@]}" | sort -u); do
    done_flag "$id" && continue
    ok=1
    while read -r b; do [ -n "$b" ] || continue; done_flag "$b" || ok=0; done < <(blockers "$id")
    [ "$ok" = 1 ] && printf '%s\n' "$id"
  done
}

status_line() { done_flag "$1" && printf 'done' || printf 'pending'; }

print_plan() {
  printf '\nAutopilot plan — feature "%s"\n' "$FEATURE"
  printf '  integration branch : %s  (base: %s)\n' "$INTEGRATION" "$BASE"
  printf '  policy             : sequential · halt-on-red · permission-mode auto\n'
  printf '  state dir          : %s\n\n' "$STATEDIR"
  printf '  %-4s %-8s %-12s %s\n' "#" "status" "blocked-by" "ticket"
  local id bl
  for id in $(printf '%s\n' "${BATCH_IDS[@]}" | sort -u); do
    bl="$(blockers "$id" | tr '\n' ',' | sed 's/,$//')"; [ -n "$bl" ] || bl="—"
    printf '  %-4s %-8s %-12s %s\n' "$id" "$(status_line "$id")" "$bl" "$(basename "$(ticket_file "$id")")"
  done
  printf '\n'
}

# ── run-level config (readable log; sentinels remain the source of truth) ─────
write_runjson() {
  local halt="${1:-}"
  { printf '{\n  "feature": "%s",\n  "integration_branch": "%s",\n  "base": "%s",\n' "$FEATURE" "$INTEGRATION" "$BASE"
    printf '  "batch": [%s],\n' "$(printf '"%s",' "${BATCH_IDS[@]}" | sed 's/,$//')"
    printf '  "halt": %s\n}\n' "${halt:-null}"
  } > "$STATEDIR/run.json"
}

# ── dry run ──────────────────────────────────────────────────────────────────
print_plan
if [ "$DRYRUN" = 1 ]; then write_runjson; exit 0; fi

# ── integration branch ───────────────────────────────────────────────────────
if ! git -C "$REPO" show-ref --verify --quiet "refs/heads/$INTEGRATION"; then
  git -C "$REPO" branch "$INTEGRATION" "$BASE" || die "cannot create integration branch $INTEGRATION from $BASE"
  printf 'autopilot: created integration branch %s from %s\n' "$INTEGRATION" "$BASE"
fi
write_runjson

# ── the loop ─────────────────────────────────────────────────────────────────
while :; do
  # all batch tickets landed?
  remaining=0; for id in "${BATCH_IDS[@]}"; do done_flag "$id" || remaining=1; done
  [ "$remaining" = 0 ] && { printf '\nautopilot: batch complete — all tickets landed on %s\n' "$INTEGRATION"; exit 0; }

  ready=()
  while IFS= read -r _r; do [ -n "$_r" ] && ready+=("$_r"); done < <(frontier)
  if [ "${#ready[@]}" -eq 0 ]; then
    write_runjson "{\"reason\":\"deadlock — a remaining ticket has an unsatisfied blocker (cycle or missing)\"}"
    die "deadlock: no ticket is runnable but the batch is not complete. See $STATEDIR/run.json"
  fi

  N="${ready[0]}"
  TF="$(ticket_file "$N")"
  SENTINEL="$STATEDIR/$N.done"
  rm -f "$SENTINEL"
  TIP_BEFORE="$(git -C "$REPO" rev-parse "refs/heads/$INTEGRATION" 2>/dev/null || echo none)"

  printf '\n═══ ticket %s ▶ %s ═══\n' "$N" "$(basename "$TF")"

  # R1 — put the main repo on the integration branch before spawning: the child's
  # cwd is this repo, and branch-guard denies edits on the default branch. On a fix
  # branch the seats' edits pass; the worktree the child cuts uses its own ticket branch.
  git -C "$REPO" checkout -q "$INTEGRATION" || die "cannot checkout $INTEGRATION (dirty tree?)"

  PROMPT="/to-implement $TF

AUTOPILOT RUN (you were dispatched by autopilot.sh; DEV_STACK_AUTOPILOT=1). This unit is pre-approved — the ticket was approved at /to-tickets and the batch at /autopilot, so do NOT stop for plan-in.
- Cut the worktree from the tip of the integration branch: $INTEGRATION
- On green /verified-review, land via /finish-branch Option 1: squash-merge to $INTEGRATION (base branch = $INTEGRATION) so the ticket lands as one commit, delete the worktree — no menu, no questions.
- FINAL ACTION after the merge succeeds: write the landed commit SHA (the squash commit on $INTEGRATION) to this exact path, nothing else in the file:
    $SENTINEL
- If ANYTHING blocks (brief BLOCKED, implementer BLOCKED, three red sweep rounds, review not green after fixers, or a merge conflict you cannot resolve): do NOT write the sentinel. Stop and report the reason. The run will halt for a human."

  DEV_STACK_AUTOPILOT=1 \
  DEV_STACK_INTEGRATION_BRANCH="$INTEGRATION" \
  DEV_STACK_AUTOPILOT_SENTINEL="$SENTINEL" \
    claude -p "$PROMPT" --permission-mode auto < /dev/null
  child_rc=$?

  TIP_AFTER="$(git -C "$REPO" rev-parse "refs/heads/$INTEGRATION" 2>/dev/null || echo none)"
  if [ -f "$SENTINEL" ] && [ "$TIP_AFTER" != "$TIP_BEFORE" ]; then
    printf 'autopilot: ticket %s landed (sentinel %s, %s→%s)\n' "$N" "$(cat "$SENTINEL")" "${TIP_BEFORE:0:9}" "${TIP_AFTER:0:9}"
    continue
  fi

  # no sentinel (or branch didn't advance) → halt, leave everything for resume
  reason="ticket $N did not land: sentinel=$([ -f "$SENTINEL" ] && echo present || echo absent), branch_advanced=$([ "$TIP_AFTER" != "$TIP_BEFORE" ] && echo yes || echo no), child_rc=$child_rc"
  write_runjson "{\"ticket\":\"$N\",\"reason\":\"$reason\"}"
  printf '\nautopilot: HALT — %s\n' "$reason" >&2
  printf 'autopilot: fix it, then re-run the same command to resume (landed tickets are skipped).\n' >&2
  exit 2
done
