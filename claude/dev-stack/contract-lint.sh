#!/usr/bin/env bash
# The invocation-contract lint (offline, deterministic). Asserts the textual
# contract the two-tier stack stands on — STOP-gates on the driving set, no
# model-invocation flag, exactly five internal skills, retired skills gone.
# Non-zero exit on ANY violation. No network. This is the stack's own Verify.
#
# Usage:
#   contract-lint.sh [DIR]   run the contract lint over DIR (default: this dir).
#                            Exit 1 on any violation, else 0.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── the contract's fixed rosters ─────────────────────────────────────────────
# The driving set: every one must open its body with a <STOP-GATE> block.
DRIVING=(
  route-me tier-1 tier-2 to-implement decision-map grill-me
  to-spec to-tickets cold-read handoff improve-codebase-architecture finish-branch
  autopilot
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
# documents the policy (README, writing-great-skills) — those are not
# violations and must not trip the lint.
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

# ── entry point ──────────────────────────────────────────────────────────────
root="${1:-$HERE}"
root="$(cd "$root" && pwd)"
if contract_lint "$root"; then exit 0; else exit 1; fi
