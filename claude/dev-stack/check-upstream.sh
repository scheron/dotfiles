#!/usr/bin/env bash
# Two jobs, deliberately separate:
#
#   1. The invocation-contract lint (offline, deterministic). Asserts the
#      textual contract the two-tier redesign stands on — STOP-gates on the
#      driving set, no model-invocation flag, exactly five internal skills,
#      retired skills gone. Non-zero exit on ANY violation. No network. This is
#      the feature's Verify.
#
#   2. The upstream-drift check (needs network). Diffs the vendored skills
#      against current upstream so you find out what vendoring froze.
#
# Usage:
#   check-upstream.sh --contract [DIR]   run ONLY the contract lint, offline,
#                                        over DIR (default: this plugin dir).
#                                        Exit 1 on any violation, else 0.
#   check-upstream.sh                    contract lint first (hard gate), then
#                                        the network drift check (advisory).
#                                        Exit reflects the contract even when
#                                        the network part can't run.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── the contract's fixed rosters (spec Global Constraints) ───────────────────
# The driving set: every one must open its body with a <STOP-GATE> block.
DRIVING=(
  route-me tier-1 tier-2 to-implementation decision-map grill-with-docs
  to-spec to-tickets cold-read handoff improve-codebase-architecture finish-branch
)
# The internal five: exactly these carry `user-invocable: false` — no more, no
# fewer. Hidden from the slash menu, reachable by skills and the model.
INTERNAL_FIVE=(
  brief codebase-design domain-modeling resolving-merge-conflicts receiving-code-review
)
# Retired: these skill directories must not exist in the tree.
RETIRED=(
  execute-tickets wayfinder new-branch setup-matt-pocock-skills verification-before-completion
)

# ── contract-lint primitives ─────────────────────────────────────────────────

# gate_ok FILE — 0 if the body opens with a <STOP-GATE> block. The gate must be
# the first body content; a single leading H1 (`# Title`) is permitted before
# it. Any prose before the gate — or a second heading — is a violation.
gate_ok() {
  awk '
    NR==1 && $0 ~ /^---[[:space:]]*$/ { infm=1; next }        # open frontmatter
    infm==1 { if ($0 ~ /^---[[:space:]]*$/) infm=0; next }    # skip to its close
    done==1 { next }
    /^[[:space:]]*$/ { next }                                 # skip blank lines
    sawh1==0 && /^# / { sawh1=1; next }                       # allow ONE leading H1
    { if ($0 ~ /^<STOP-GATE>/) rc=0; else rc=1; done=1 }      # first substantive line
    END { if (done==1) exit rc; else exit 1 }                 # empty body = no gate
  ' "$1"
}

# fm_has_flag FILE — 0 if the frontmatter DECLARES disable-model-invocation.
# Scoped to frontmatter on purpose: the flag as an active directive is what the
# contract forbids. The string still appears legitimately in prose that
# documents the policy (STACK.md §3, README, writing-great-skills) — those are
# not violations and must not trip the lint.
fm_has_flag() {
  awk '
    NR==1 && $0 !~ /^---[[:space:]]*$/ { exit 1 }             # no frontmatter
    NR==1 { infm=1; next }
    infm==1 && /^---[[:space:]]*$/ { exit 1 }                 # end of frontmatter, absent
    infm==1 && /disable-model-invocation/ { exit 0 }          # declared -> violation
    { next }
  ' "$1"
}

# contract_lint DIR — run all four checks over DIR/skills. Prints a PASS/FAIL
# line per check plus any offenders. Returns non-zero if ANY check failed.
contract_lint() {
  local root="$1"
  local sk="$root/skills"
  local total=0

  echo "══ invocation contract lint (offline, deterministic) ══"
  echo "target: $root"
  echo

  # [1/4] STOP-gate opens each driving skill's body.
  local v=0 s f
  local out=""
  for s in "${DRIVING[@]}"; do
    f="$sk/$s/SKILL.md"
    if [[ ! -f "$f" ]]; then
      out+="        - $s: SKILL.md missing"$'\n'; v=$((v+1)); continue
    fi
    if ! gate_ok "$f"; then
      out+="        - $s: body does not open with <STOP-GATE>"$'\n'; v=$((v+1))
    fi
  done
  if [[ $v -eq 0 ]]; then
    printf "  [1/4] STOP-gate opens each driving skill (%d) .......... PASS\n" "${#DRIVING[@]}"
  else
    printf "  [1/4] STOP-gate opens each driving skill (%d) .......... FAIL\n" "${#DRIVING[@]}"
    printf "%s" "$out"
  fi
  total=$((total+v))

  # [2/4] disable-model-invocation declared by no skill.
  v=0; out=""
  for f in "$sk"/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    if fm_has_flag "$f"; then
      out+="        - $(basename "$(dirname "$f")"): declares disable-model-invocation"$'\n'; v=$((v+1))
    fi
  done
  if [[ $v -eq 0 ]]; then
    echo "  [2/4] no skill declares disable-model-invocation ....... PASS"
  else
    echo "  [2/4] no skill declares disable-model-invocation ....... FAIL"
    printf "%s" "$out"
  fi
  total=$((total+v))

  # [3/4] exactly the five internals carry user-invocable: false.
  local actual=()
  for f in "$sk"/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    if grep -q '^user-invocable: false' "$f"; then
      actual+=("$(basename "$(dirname "$f")")")
    fi
  done
  local expected_sorted actual_sorted
  expected_sorted="$(printf '%s\n' "${INTERNAL_FIVE[@]}" | sort)"
  actual_sorted="$(printf '%s\n' ${actual[@]+"${actual[@]}"} | sort)"
  if [[ "$expected_sorted" == "$actual_sorted" ]]; then
    echo "  [3/4] exactly the five internals are user-invocable ... PASS"
  else
    echo "  [3/4] exactly the five internals are user-invocable ... FAIL"
    local extra missing
    extra="$(comm -13 <(printf '%s\n' "$expected_sorted") <(printf '%s\n' "$actual_sorted") | grep -v '^$' || true)"
    missing="$(comm -23 <(printf '%s\n' "$expected_sorted") <(printf '%s\n' "$actual_sorted") | grep -v '^$' || true)"
    [[ -n "$extra" ]]   && while IFS= read -r x; do echo "        - unexpected: $x"; done <<< "$extra"
    [[ -n "$missing" ]] && while IFS= read -r x; do echo "        - missing:    $x"; done <<< "$missing"
    total=$((total+1))
  fi

  # [4/4] retired skills absent from the tree.
  v=0; out=""
  local r
  for r in "${RETIRED[@]}"; do
    if [[ -d "$sk/$r" ]]; then
      out+="        - $r: directory still present"$'\n'; v=$((v+1))
    fi
  done
  if [[ $v -eq 0 ]]; then
    echo "  [4/4] retired skills absent from the tree ............. PASS"
  else
    echo "  [4/4] retired skills absent from the tree ............. FAIL"
    printf "%s" "$out"
  fi
  total=$((total+v))

  echo
  if [[ $total -eq 0 ]]; then
    echo "contract: PASS (0 violations)"
    return 0
  fi
  echo "contract: FAIL ($total violation(s))"
  return 1
}

# ── the upstream-drift check (needs network) ─────────────────────────────────
network_drift() {
  local TMP
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' RETURN

  # Pocock, vendored verbatim. Forks and originals are excluded: they differ by
  # design.
  local POCOCK=(
    codebase-design domain-modeling grill-with-docs grilling handoff
    improve-codebase-architecture prototype research
    tdd to-spec to-tickets writing-great-skills
    resolving-merge-conflicts setup-pre-commit git-guardrails-claude-code
  )
  # Intentionally patched by the v2 redesign — a diff is EXPECTED, not drift.
  # These carry dev-stack changes (a STOP-gate prepended, the model-invocation
  # flag dropped, and/or `user-invocable: false` added for the internal five),
  # each marked with an <!-- dev-stack: … --> comment. They stay in POCOCK so a
  # GONE-UPSTREAM is still caught; PATCHED just stops the expected diff counting
  # as drift. The remainder of POCOCK is still verbatim and diff-checked.
  local PATCHED=(
    to-spec to-tickets grill-with-docs handoff improve-codebase-architecture
    codebase-design domain-modeling resolving-merge-conflicts writing-great-skills
  )

  local drift=0 s mine theirs

  echo "cloning mattpocock/skills…"
  if git clone -q --depth 1 https://github.com/mattpocock/skills "$TMP/mp" 2>/dev/null; then
    for s in "${POCOCK[@]}"; do
      mine="$HERE/skills/$s"
      theirs="$(find "$TMP/mp/skills" -maxdepth 2 -type d -name "$s" | head -1)"
      if [[ -z "$theirs" ]]; then
        printf "  %-32s GONE UPSTREAM\n" "$s"; drift=$((drift+1)); continue
      fi
      # agents/ is upstream harness metadata we deliberately dropped (Claude-only)
      if diff -rq --exclude=agents "$mine" "$theirs" >/dev/null 2>&1; then
        printf "  %-32s same\n" "$s"
      elif printf '%s\n' "${PATCHED[@]}" | grep -qx "$s"; then
        printf "  %-32s differs (expected — patched by dev-stack)\n" "$s"
      else
        printf "  %-32s DRIFTED\n" "$s"; drift=$((drift+1))
      fi
    done
  else
    echo "  (clone failed — Pocock skills frozen; check drift by hand)"
  fi

  # ── superpowers, ports (from anthropics/claude-plugins-official) ────────────
  # Verbatim ports differ only by one attribution line (contains "dev-stack");
  # strip it before diffing. Adapted ports carry bounded dev-stack additions and
  # forks are expected to differ — neither is diff-checked automatically.
  local SP_VERBATIM=()
  # Ported then adapted (bounded additions, not verbatim). The base still tracks
  # upstream, so it's worth a manual glance — but no automatic diff.
  local SP_ADAPTED=(using-git-worktrees receiving-code-review)
  local SP_FORKS=(finish-branch)

  echo
  echo "cloning anthropics/claude-plugins-official (superpowers)…"
  if git clone -q --depth 1 https://github.com/anthropics/claude-plugins-official "$TMP/sp" 2>/dev/null; then
    for s in ${SP_VERBATIM[@]+"${SP_VERBATIM[@]}"}; do
      theirs="$(find "$TMP/sp" -path '*superpowers*' -type d -name "$s" | head -1)"
      if [[ -z "$theirs" ]]; then
        printf "  %-32s NOT FOUND upstream (check the path)\n" "$s"; drift=$((drift+1)); continue
      fi
      if diff -q \
          <(grep -v 'dev-stack' "$HERE/skills/$s/SKILL.md") \
          <(grep -v 'dev-stack' "$theirs/SKILL.md") >/dev/null 2>&1; then
        printf "  %-32s same (bar attribution)\n" "$s"
      else
        printf "  %-32s DRIFTED\n" "$s"; drift=$((drift+1))
      fi
    done
    for s in "${SP_ADAPTED[@]}"; do
      printf "  %-32s adapted — dev-stack additions, not verbatim (glance upstream by hand)\n" "$s"
    done
    for s in "${SP_FORKS[@]}"; do
      printf "  %-32s fork — intentional divergence, not diff-checked\n" "$s"
    done
  else
    echo "  (clone failed — superpowers ports frozen at plugin 6.1.1, check by hand)"
  fi

  echo
  if [[ $drift -eq 0 ]]; then
    echo "no unexpected drift."
  else
    echo "$drift skill(s) drifted. Re-vendor by copying upstream over skills/<name>,"
    echo "re-applying any dev-stack patch (marked with an <!-- dev-stack: … --> comment),"
    echo "and deleting the copied agents/ directory (this set is Claude-only)."
  fi
  # Drift stays advisory: offline the clone legitimately fails, so it must not
  # decide the exit code. The contract lint is the hard gate.
}

# ── entry point ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--contract" ]]; then
  root="${2:-$HERE}"
  root="$(cd "$root" && pwd)"
  if contract_lint "$root"; then exit 0; else exit 1; fi
fi

# Plain run: contract lint FIRST (hard gate) so its verdict survives even when
# the network part below can't run, THEN the advisory drift check.
contract_failed=0
if ! contract_lint "$HERE"; then contract_failed=1; fi
echo
network_drift || true

echo
if [[ $contract_failed -ne 0 ]]; then
  echo "FAIL — the invocation contract is violated (see the contract lint above)."
  exit 1
fi
exit 0
