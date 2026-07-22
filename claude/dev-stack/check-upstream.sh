#!/usr/bin/env bash
# Diff the vendored skills against current upstream, and lint invocation.
# Vendoring froze them; this is how you find out what you froze.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ── Pocock, vendored verbatim ────────────────────────────────────────────────
# Forks and originals are excluded: they are supposed to differ.
POCOCK=(
  codebase-design domain-modeling grill-with-docs grilling handoff
  improve-codebase-architecture prototype research setup-matt-pocock-skills
  tdd to-spec to-tickets wayfinder writing-great-skills
  resolving-merge-conflicts setup-pre-commit git-guardrails-claude-code
)
# Intentionally patched — diff is expected, shown separately.
PATCHED=(to-spec to-tickets)

drift=0

echo "cloning mattpocock/skills…"
git clone -q --depth 1 https://github.com/mattpocock/skills "$TMP/mp"
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

# ── superpowers, ports (from anthropics/claude-plugins-official) ──────────────
# Verbatim ports differ only by one attribution line (contains "dev-stack");
# strip it before diffing. Forks are expected to differ — not diff-checked.
SP_VERBATIM=(using-git-worktrees verification-before-completion)
SP_FORKS=(execute-tickets finish-branch)

echo
echo "cloning anthropics/claude-plugins-official (superpowers)…"
if git clone -q --depth 1 https://github.com/anthropics/claude-plugins-official "$TMP/sp" 2>/dev/null; then
  for s in "${SP_VERBATIM[@]}"; do
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

# ── invocation lint ──────────────────────────────────────────────────────────
# A user-invoked skill (disable-model-invocation: true) can't be reached by
# another skill. Flag any OTHER skill that imperatively invokes one. route-me
# is the router — it names everything by design, so it is exempt. Heuristic:
# advisory, not a hard gate.
echo
echo "invocation lint (user-invoked skills named imperatively by another skill):"
user_invoked=()
for f in "$HERE"/skills/*/SKILL.md; do
  grep -q '^disable-model-invocation: true' "$f" && user_invoked+=("$(basename "$(dirname "$f")")")
done
flagged=0
verbs='Run|run|Invoke|invoke|Call|call|Drive|drive|Fire|fire'
for u in "${user_invoked[@]}"; do
  while IFS= read -r f; do
    [[ "$f" == *"/skills/$u/SKILL.md" ]] && continue
    [[ "$f" == *"/skills/route-me/SKILL.md" ]] && continue
    # backtick-required + exclude temporal ("Use after"), human prereqs
    # ("run X if not"), and frontmatter description lines
    hits="$(grep -nE "($verbs)\b[^.]*\`/$u\`" "$f" | grep -vE 'Related:|description:|if not|should have been provided' || true)"
    if [[ -n "$hits" ]]; then
      printf "  %-28s → /%s\n" "$(basename "$(dirname "$f")")" "$u"
      flagged=$((flagged+1))
    fi
  done < <(grep -rlE "/$u\b" "$HERE"/skills/*/SKILL.md)
done
[[ $flagged -eq 0 ]] && echo "  clean — no user-invoked skill is imperatively invoked by another."

exit 0
