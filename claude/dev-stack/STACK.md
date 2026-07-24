# My development stack

The decision record from the grilling sessions of 2026-07-20 (finalized 2026-07-22) and **2026-07-23 — the two-tier redesign**; amended 2026-07-24 (the brief-writer split and the model ladder, §6).

Starting problem (2026-07-20): I had both Superpowers and Matt Pocock's skills installed; they partly conflicted, and I also sometimes work through specs. I needed one coherent setup.

The 2026-07-23 redesign: three tiers collapsed into two; driving skills became model-invocable behind STOP-gates; execution moved into one engine (`to-implementation`) that runs every ticket as a subagent in its own worktree.

**The dividing principle:** Pocock owns the conversation, the documents, and the judgement. Superpowers provides the parallel-execution machinery.

**The packaging principle (2026-07-23):** a skill earns its file by being an *addressable unit of logic* — edited in one known place, dispatched by reference rather than pasted inline, or invoked conditionally ("if X → `/skill`"). A skill must never duplicate an entity that already lives elsewhere; when logic already has a home, other skills point at it with one line.

This file is the *why*. For the roster of skills and how to install, see [README.md](README.md); for the operational map, run `/route-me`.

---

## 1. Two tiers

The tier is chosen by the scout, never from the armchair. The criterion is binary: **does this fit an inline solution right now?** Yes → Tier 1. No → Tier 2.

```
TIER 1 — FIX                     fits an inline solution right now
  gate IN:   plan inline + approval BEFORE any edit  (in chat, never an artifact)
  bug / crashing / slow   ->  /diagnose
  body:      to-implementation with ONE unit (the plan from chat)
  gate OUT:  /verified-review — mandatory, reviewer runs Verify itself

TIER 2 — FEATURE                 everything else
  the full chain, section 4
  body:      to-implementation over the tickets
```

**The recursion is the model:** Tier 1 *is* the execution of one unit. Tier 2 is orchestration over Tier 1 runs — split the feature into tickets, run each as a Tier 1 lifecycle in its own worktree. One engine, two entry weights.

**Tier 3 is gone.** `wayfinder`'s essence survives in two places: the scout's *list of open decisions* (§2) and the `/decision-map` phase (§4) — an optional front phase of Tier 2 that `route-me` *proposes* (never launches) when the fog exceeds one grill session. A decision map is not a tier; it is how Tier 2 opens when decisions outnumber a session.

**Isolation floor — all tiers.** No tier works on the default branch. Every unit of work isolates in a worktree (`/using-git-worktrees`; its in-place branch fallback covers sandbox denial). In a dev-stack repo the `branch-guard` hook denies edits and commits on `main`/`master`, so isolation is enforced, not advised.

---

## 2. The scout

Always runs, read-only, on the current branch, before any tier talk — it is the first act of `/route-me`. It returns three things and keeps the file dumps in its own context:

```
1. map of the code        where it lives, how far it spreads, what constrains it
2. tier signal            "does this fit an inline solution right now?"
3. open decisions         questions the code cannot answer — decisions are the user's
```

The third output is new (2026-07-23) and does double duty:

- **few decisions** (fit one grill session) → `/grilling` starts with a **pre-seeded agenda** — the grill is a consequence of data, not a ritual to remember;
- **many decisions** (exceed one session) → `route-me` proposes `/decision-map` first.

The scout *measures* fog; it never resolves it. Facts are looked up, decisions are put to the user — the same contract the grill runs on.

---

## 3. Invocation policy — STOP-gates instead of flags

`disable-model-invocation` is removed from the driving skills. The flag was the crudest possible implementation of "the wheel stays in the user's hand": not "the model must ask" but "the model physically cannot". It broke legitimate chains — a `/tier-2` driver that cannot raise `/grilling` degrades to *describing* what it would do (the exact failure the 2026-07-22 vendoring pass caught in three skills).

What replaces it:

- **Every driving skill opens with a STOP-gate.** First act: present intent, wait for the explicit "go". Not mid-way, not after the fact — the first line of the skill. ("Scout says Tier 2, four open decisions — start the grill?")
- **The lint is repurposed.** `check-upstream.sh` no longer checks "no skill invokes a user-invoked skill"; it checks **"every driving skill opens with a STOP-gate"** — a mechanical check of the textual contract.
- **`user-invocable: false` marks the internal five** — `brief`, `codebase-design`, `domain-modeling`, `resolving-merge-conflicts`, `receiving-code-review` — hidden from the `/` menu, reachable by skills and the model. Criterion: internal = meaningless without the context another skill provides.
- **Mechanical enforcement is unchanged** and carries the real weight: `branch-guard`, `commit-guard`, `session-gate` (gate contract survives compaction), `review-guard` (unreviewed changes block wrap-up). Text gates steer; hooks enforce.

The risk ledger of lifting the flag: a self-started grill is harmless (a grill's first act is a question — it cannot run away); an unasked-for spec costs tokens and is caught at its approval gate; unasked-for *code* is the real hazard and stays hook-blocked.

---

## 4. One engine, thin drivers

```
/route-me        scout → "Tier N, here's why + open decisions. Launch /tier-N?" ⏸
/tier-1          plan inline ⏸ → to-implementation(chat plan, one unit)
/tier-2          [/decision-map ⏸ if the scout flagged fog]
                 → /grill-with-docs   (= /grilling + /domain-modeling; agenda from
                     the scout; CONTEXT.md and ADRs written inline, committed)
                 → /to-spec ⏸ → /to-tickets ⏸ → /cold-read
                 → to-implementation(tickets)
/to-implementation   THE ENGINE — input: spec | ticket | tickets | nothing (chat)
```

`/decision-map` (replaces `wayfinder`): materialize the scout's open-decision list as decision tickets on the tracker; burn them down — `/research` subagents in parallel, `/prototype` where a question needs a runnable answer, a grill where it needs the user; every resolution → an ADR. When the fog clears, the chain continues into the normal grill.

Per unit, the engine runs the Tier 1 lifecycle down the model ladder (§6):

```
spoke worktree off the approved hub tip
  → brief-writer (top tier, fresh)   writes .scratch/brief-NN.md IN the spoke
  → implementer (standard tier)      reads the brief, works /tdd
  → engine: test-runner sweep        red summary → same implementer
                                     ⛔ 3 reds in a row → BLOCKED
  → /verified-review                 stage 0 → axes → adr-candidate  (§8–9)
  → integration STOP-gate ⏸          merge + ADR + next wave  (§5)
```

**The drivers are a convenience, never a requirement.** The classic chain stays drivable by hand — `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/to-implementation` — which is also why `/grill-with-docs` survives: it is the one addressable home of the grill+docs composition, referenced by the tier-2 driver and typed by the hand-driver, never re-composed in two places.

---

## 5. Execution topology — hub and spoke

The feature branch is the **hub**. Every unit is a spoke.

```
feature (hub) ──o──────────m──────────m────────►
                \         /  \       /
      ticket-01  o──o──o─┘    \     /    ← worktree: brief, tdd, runner, review
      ticket-02   (same tip)   o──o┘        merge only when green, then teardown
```

- **Branch first, then ephemera.** Durable docs (ADRs, `CONTEXT.md`) are committed to the hub *before* dispatch — every spoke sees them through git for free. Ephemera (`brief`, `report`, `.scratch/`) are born *inside* the ticket worktree, after branching — the brief by the brief-writer, the report by the implementer (§6).
- **All spokes of a batch start from one point** — the hub tip the user approved. The starting point is always the user's call.
- **The paper interface chain is dead.** The old rule carried ticket N's `Produces` into N+1's `Consumes` verbatim — a crutch for subagents that cannot see each other. Now a dependent ticket launches *from the merged code*: its `Consumes` is read from reality, not from paper. The contract is the code.
- **Batch overlap is the user's risk.** Briefs are born inside the spokes, so no disjoint-files check exists at dispatch time. Conflicts surface at merge into the hub and are handled by `/resolving-merge-conflicts` — the honest price of the simpler topology.
- **Integration rides a STOP-gate.** The orchestrator proposes, the user approves: "01 and 02 are green. Merge into the hub and launch 03 from the new tip? Plus one adr-candidate — record it?" Merges, ADRs, and the next wave all share the same pause — no extra interrupts.
- **A failed spoke is discarded with its worktree.** The hub stays clean; no resets, no pollution.
- The **ledger** stays with the orchestrator (its `.scratch/<feature>/ledger.md`): one line per closed ticket carrying all three verdicts. Per-spoke ephemera dies with the spoke; the ledger line is what survives. After compaction, trust the ledger and `git log` over recollection.

---

## 6. The unit pipeline — the model ladder

Amended 2026-07-24. Two forces shape the pipeline. **Context hygiene**: the implementer's window never holds exploration (the brief-writer's job) or stacktraces (the runner's job) — it holds the brief and the build. And the **snowball rule**: a better spec makes a better plan, a better plan a better brief, a better brief a near-mechanical implementation — so intelligence sits where it compresses, and execution runs below it.

```
opus    orchestrator   gates, dispatches, integration, the final review
opus    brief-writer   one per unit, fresh context, IN the spoke: explores the
                       code itself (it IS the walk — no Explore sub-dispatch),
                       writes .scratch/brief-NN.md, returns only the path;
                       the exploration dies with it
sonnet  implementer    reads the brief, works /tdd at the agreed seams,
                       runs focused tests inline; never the full sweep
sonnet  test-runner    dispatched by the ORCHESTRATOR once the implementer
                       reports done: the repo's verification directions →
                       summary only
                       (counts, failing names, one line per failure) — never
                       stacktraces. Sonnet, not the cheapest tier: the summary
                       IS the product, and a poor one re-imports the noise
```

The brief-writer's tier is **load-bearing, not preference**: a weak brief poisons everything downstream, and the implementer tier is affordable *because* the brief left nothing to decide. There is no per-unit model knob — the ladder is fixed by decision (the brief's old `Model:` field is gone with it).

Fix rounds: a red sweep summary goes back to the **same implementer** — its context is alive, it pays only for the summary — never to a fresh dispatch. Three red rounds in a row → BLOCKED, escalate to the user (the three-fix breaker of `/diagnose`, held by the orchestrator).

Every dispatched seat below the orchestrator is an **agent definition** in `agents/` — not a skill, not an inline prompt: the model is pinned once in the frontmatter, the role rides in the body, and dispatches reference the name in one line (the packaging principle at work). Where a protocol already has a skill for a home, the agent body points at it instead of restating it — the brief-writer follows `/brief`. `install.sh` links `agents/` alongside `skills/`.

**A green sweep is a working signal, not evidence.** The only receipt is stage 0 of `/verified-review` (§8), run by the reviewer itself. STACK's oldest rule is untouched: the implementer's report is a hypothesis.

---

## 7. Artifacts

The single rule stands: **volatile lives in the ephemeral, stable lives in the durable.**

### Durable — in the repo, outlives the task

```
CONTEXT.md        glossary. TERMS ONLY. Maintained inline via /domain-modeling
docs/adr/         decisions + rejected alternatives
                  test: irreversible + surprising + a real trade-off
                  written DURING the run (adr-candidate, §9), not only at harvest
AGENTS.md         the project constitution
                  ## Build & run    the verification contract
                  ## Known issues   "no seam" findings, if there's no tracker
```

### Ephemeral — dies at merge (or with its spoke)

```
hub  .scratch/<feature>/     spec, tickets (if no tracker), ledger.md
spoke .scratch/              brief-NN.md, report-NN.md — born and dying with
                             the ticket worktree; the ledger line survives
```

The brief is written **by the brief-writer, inside the unit's worktree, at pickup** (§6) — it cannot be stale by construction: it is written against the exact commit the spoke branched from, and the implementer reads it as its first act. The `Run as` and `Model:` knobs are both gone — the ladder fixes every tier by decision.

Tickets and specs live where `docs/agents/issue-tracker.md` says — tracker or `.scratch/` — and carry **no paths, no code**, as before. If `issue-tracker.md` is missing, the tier-2 driver asks once at preflight (the one live duty inherited from `setup-matt-pocock-skills`).

---

## 8. Definition of Done

Every tier clears this — a Tier 1 one-line fix is reviewed on the same bar as a Tier 2 ticket. The tier scales the *process* in front of the change, never the gate behind it.

`/verified-review` runs in the ticket's worktree, in two stages:

```
STAGE 0 — cheap, early-exit                     (2026-07-23)
  runs Verify + lint + type/compile checks ITSELF
  red → return immediately; the command output is the only finding;
        the Standards/Spec axes never launch on broken code
  red where the implementer reported green → that discrepancy is a
        finding in its own right; the report's other claims are suspect

STAGE 1 — the axes, in parallel
  spec axis         matches the ticket
  standards axis    matches the repo's conventions
  + the adr-candidate check (§9)
```

The agent-runnable-command contract is unchanged:

```
one command you have ALREADY RUN at least once (paste invocation and output)
  red-capable / deterministic / fast (per-repo floor) / agent-runnable
no Verify command exists  =  a FINDING → /improve-codebase-architecture
                             never "verify manually"
```

**A ticket is closed by `/verified-review` passing — nothing else.** The ledger line carries all three verdicts or the ticket isn't closed. When the frontier is empty: one `/verified-review` over the whole branch (fixed point = merge-base, strongest model), then `/finish-branch`.

Fix dispatches carry one conditional line: *findings received → follow `/receiving-code-review`* — verify a finding against the code before implementing it; a finding is a hypothesis too. One fixer per findings list, never one per finding.

---

## 9. ADR mid-flight — adr-candidate

Harvest-at-the-end was the chain's only silent failure: nothing breaks, you just pay again in three weeks — and it was the *only* moment ADRs got written. Now:

- `/verified-review` carries one conditional line: **the change passes the ADR test from `/domain-modeling`** (irreversible + surprising + a real trade-off) **→ finding class `adr-candidate`**. The criteria live once, where ADRs live; the review points at them.
- Candidates ride the **integration STOP-gate** (§5) — zero extra interrupts.
- Approved → `/domain-modeling` writes the ADR into the hub → later spokes see it through git, by construction.
- `finish-branch`'s harvest becomes the **final sweep** for what slipped through, no longer the only chance.

---

## 10. TDD — the Pocock way

```
tests only at AGREED seams — agreed at the grill's seams+verify gate
the ideal number of seams is one, the highest reachable
red -> green;  REFACTORING OUTSIDE THE LOOP, it goes to /verified-review
vertical slices, not a horizontal cut

anti-patterns:
  implementation-coupled  test breaks on refactor though behaviour is unchanged
  tautological            the expectation is computed the way the code computes it
  horizontal slicing      all tests first, then all implementation
```

The superpowers Iron Law (*no line of production code without a failing test*) stays rejected: it produces tests against internals — exactly the first anti-pattern.

---

## 11. Debugging — diagnosing-bugs + grafts

```
P1   build a feedback loop         <- GATE, criterion from section 8
P2   reproduce + MINIMISE
P2.5 PATTERN ANALYSIS              <- grafted from superpowers
P3   3–5 RANKED hypotheses, each falsifiable with a prediction
P4   instrument; one probe per prediction; debugger > logs
P5   fix + regression test;  3+ failed fixes -> STOP, architectural conversation
P6   cleanup + post-mortem
```

`systematic-debugging` stays rejected as a whole; Pattern Analysis and the three-fix breaker are the grafts kept.

---

## 12. What's rejected, and why

The 2026-07-20 rejections stand (see git history for the full original table): `brainstorming` (heavy artifact gate on trivial work), `test-driven-development` (Iron Law), `systematic-debugging` (§11), `requesting-code-review`, `executing-plans`, `writing-plans`, `dispatching-parallel-agents`, `using-superpowers` and its SessionStart hook, the superpowers plugin as a whole.

Added 2026-07-23 — retired from dev-stack itself:

| Skill | Why |
|---|---|
| `wayfinder` | Tier 3 is gone; the essence split into the scout's open-decisions list (§2) and `/decision-map` (§4) |
| `execute-tickets` | superseded by `to-implementation` — one engine for both tiers (§4–5) |
| `new-branch` | not a separate logic unit — the in-place fallback path of `/using-git-worktrees`; folded in, script kept |
| `setup-matt-pocock-skills` | dead in a self-contained setup; its one live duty (missing `issue-tracker.md` → ask once) moved to the tier-2 preflight (§7) |
| `verification-before-completion` | its job became structural: `verified-review` runs Verify itself, `review-guard` blocks unreviewed wrap-up. Prose duplicating the DoD — deleted |

Two skills were on the kill list and came back — the packaging principle overruled both. `receiving-code-review` is conditionally-invoked logic ("findings received → follow it"), not a duplicate; it lives as an internal skill, referenced by fix dispatches (§8). `grill-with-docs` is the one addressable home of the grill+docs composition — deleting it would have re-composed the same pair in two places, the driver and the hand-driven chain (§4).

Kept deliberately: `handoff` (the only tool for context exhaustion mid-grill), `improve-codebase-architecture` and `codebase-design` (an act and a vocabulary — merging them would blur roles, not save an entity).

---

## 13. Roster delta (2026-07-23)

```
retired  (5)   execute-tickets, wayfinder, new-branch,
               setup-matt-pocock-skills, verification-before-completion
new      (4)   to-implementation, tier-1, tier-2, decision-map
new agents (3) test-runner (sonnet — the summary is the product),
               brief-writer (opus — follows /brief), implementer (sonnet);
               models pinned in frontmatter, install.sh links agents/
internal (5)   user-invocable: false — brief, codebase-design,
               domain-modeling, resolving-merge-conflicts, receiving-code-review
```

The repo layout stays flat — one level under `skills/`; visibility is frontmatter's job, not the filesystem's.

The memorised surface after the redesign: **`/route-me`** — plus `/tier-1` and `/tier-2` for the impatient. Everything else is either raised by a driver behind a STOP-gate or reachable "the old way" by hand — the classic chain `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/to-implementation` included: `/grilling`, `/cold-read`, `/diagnose`, `/verified-review`, `/finish-branch`, `/tdd`, `/using-git-worktrees`, `/prototype`, `/research`, `/handoff`, `/decision-map`, `/improve-codebase-architecture`, `/commit-work` + the setup utilities.

---

## 14. Remaining work

1. **Rewrite the skills to this record** — the redesign itself is the first Tier 2 exercise: spec in `.scratch/`, tickets, `to-implementation` built by the flow it implements (bootstrapped manually the first time).
2. `README.md`, `INSTALL.md`, `route-me`'s map and cheat sheet — re-point at the two-tier model.
3. `check-upstream.sh` — swap the invocation lint for the STOP-gate lint (§3); drop retired skills from the drift list.
4. Obkatka order unchanged: **GrammarDiff first** (clean agent-runnable checks — a failure implicates the stack, not the substrate), then Chelsea. Chelsea's first feature is still the UITests target that lights up `A11yID.swift` — until then its Verify ceiling is `xcodebuild build` + OSLog assertions.

---

## Why it converges

Vertical tickets make `Verify` possible. The scout catches missing decisions before the grill; the grill's seams gate catches a missing Verify before the spec. A finding goes to the architecture skill; the decision becomes an ADR — now *during* the run, where the next spoke can see it. And the spec and the briefs die at merge — so they don't lie to the next agent.
