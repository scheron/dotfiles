# My development stack

The decision record from the grilling session of 2026-07-20 (finalized 2026-07-22).

Starting problem: I had both Superpowers and Matt Pocock's skills installed; they partly conflicted, and I also sometimes work through specs. I needed one coherent setup.

**The dividing principle:** Pocock owns the conversation, the documents, and the judgement. Superpowers provides the parallel-execution machinery.

This file is the *why*. For the roster of skills and how to install, see [README.md](README.md); for the operational map, run `/route-me`.

---

## 1. Three tiers

The tier is chosen at the start of the work. Both toolkits assumed "every change passes the full gate" — that was the source of the friction, because a trivial fix had to pay the full price.

```
TIER 1 — FIX                                              minutes–hour
  bug / crashing / slow   ->  /diagnose
  small change            ->  straight to work
                          ->  /verified-review
  no spec, no tickets, no .scratch/

TIER 2 — FEATURE                                          one–two sessions
  the full chain, see section 2

TIER 3 — EFFORT                                           won't fit one session
  /wayfinder — a map of decision-tickets
  1 ticket = 1 session;  a decision -> an ADR
  each resolved ticket -> Tier 2
```

---

## 2. The Tier 2 chain

```
/grill-with-docs        Pocock
  = /grilling + /domain-modeling at once
  interview one question at a time; facts I look up, decisions are mine
  CONTEXT.md and ADRs written INLINE as we go, not after the fact
      -> GATE 1   "shared understanding?"

seams + verify
  "cut here, prove it with this"
      -> GATE 2   nothing to verify with -> a FINDING, not "I'll check by hand"

/to-spec                Pocock
  spec: Problem / Solution / User Stories / Implementation Decisions /
        Testing Decisions / Out of Scope
  NO paths, NO code — a human reads it
  carries Global Constraints for the tickets that follow
      -> GATE 3   proofread

/to-tickets             Pocock
  vertical tracer bullets + blocking edges
  each: a narrow but COMPLETE path through every layer, demoable on its own,
        sized to one fresh context window
  NO paths, NO code
      -> quiz     granularity and edges

brief                   (generated when a ticket is picked up)
  Files / Interfaces / Verify / Run as
  ALWAYS .scratch/, always ephemeral

execute                 (superpowers-derived)
  subagent-driven, one implementer per ticket
  Run as: [inline] | [subagent:cheap] | [subagent:standard]

/verified-review        forked from Pocock
  after EVERY ticket, a subagent with a CLEAN context
  Standards and Spec axes in parallel + RUNS Verify itself
```

---

## 3. Artifacts

The single rule: **volatile lives in the ephemeral, stable lives in the durable.**

This is the cure for spec-rot. The spec has no paths because a human reads it and volatile detail gets in the way. The brief has paths because it will be dead in a day and precision there is free.

### Durable — in the repo, outlives the task

```
CONTEXT.md        glossary. TERMS ONLY. No decisions, no implementations.
                  maintained inline via /domain-modeling
docs/adr/         decisions + rejected alternatives
                  test: irreversible + surprising + a real trade-off
AGENTS.md         the project constitution
                  ## Build & run    what the repo can honestly run,
                                    holes included  <- the verification contract
                  ## Known issues   "no seam" findings, if there's no tracker
```

### Ephemeral — dies at merge

```
.scratch/<feature>/
  brief-NN.md     Files / Interfaces / Verify / Run as
  review/
```

`.scratch/` is in `.gitignore`.

### Where tickets live — the repo decides

Follows `docs/agents/issue-tracker.md`, as Pocock intends.

```
TICKET and SPEC   what we build, acceptance criteria, blocking edges
                  -> Linear / GitHub / .scratch/  — the repo's choice
                  -> paths and code NEVER

BRIEF             the technical bottom
                  -> ALWAYS .scratch/, always local
```

The technical bottom physically cannot reach a tracker — so paths and signatures won't start lying six months later.

An example in both modes:

```
Chelsea (Linear)                    GrammarDiff (no tracker)
  SCH-291       spec                  .scratch/dedupe/spec.md
  SCH-292..295  tickets               .scratch/dedupe/issues/01..04.md
  .scratch/SCH-292/brief.md           .scratch/dedupe/brief-01.md
```

There is no separate `verification.md` — it would rot on its own, and the commands already live in `AGENTS.md ## Build & run`, which the agent reads first.

---

## 4. The unit of work

A vertical tracer bullet. A horizontal task has nothing to verify e2e — "add a validator" has no observable behaviour. A through-and-through slice is verifiable by definition, and only for that reason does the gate in section 5 work at all.

```
TICKET  (wherever issue-tracker.md says)
  What to build   behaviour from the user's perspective, through every layer
  Acceptance      acceptance criteria
  Blocked by      numbers/links of the blocking tickets

BRIEF  (.scratch/, ephemeral)
  Files       exact paths
  Interfaces  Consumes / Produces with signatures
  Verify      a named agent-runnable command
  Run as      [inline] | [subagent:cheap] | [subagent:standard]
```

The `Interfaces` block is mandatory: a subagent sees **only its own task**. Without it, slice 3 names a function `clearLayers` and slice 7 calls `clearFullLayers`, and nothing catches it.

Exception — the **wide refactor** (rename or retype of a shared symbol): it can't be squeezed into a vertical slice, because one correct commit breaks thousands of call sites. The sequence is expand -> migrate in batches -> contract, each batch its own ticket, `Verify: build` (behaviour doesn't change by definition).

---

## 5. Definition of Done

```
spec axis         matches the spec
Verify green      red BEFORE, green AFTER — RAN THE VERIFIER ITSELF
standards axis    matches the repo's conventions

discrepancy with the implementer's report  = a finding
no Verify command exists                    = a finding -> /improve-codebase-architecture
                                              NOT "I'll check by hand"
```

**The main departure from both toolkits.** In theirs, the reviewer audits the report and is explicitly forbidden to re-run tests:

> superpowers, `subagent-driven-development/SKILL.md:166` —
> *"Do not ask a reviewer to re-run tests the implementer already ran on the
> same code — the implementer's report carries the test evidence."*

Here it runs them itself. The implementer's report is a hypothesis, not proof. The contradiction is already inside superpowers: `verification-before-completion` names "trusting agent success reports" a red flag, and SDD is built on exactly that trust.

The agent-runnable-command criterion is taken from `diagnosing-bugs`, Phase 1, and lifted from the debugging level to a standing contract:

```
one command you have ALREADY RUN at least once (paste the invocation and output)
  red-capable      drives the real path, asserts the exact symptom
  deterministic    the same verdict every run
  fast             the tightest loop this repo's toolchain allows
  agent-runnable   runs unattended
```

**On `fast`:** the floor is per-repo, not an absolute. A pnpm/vitest suite is seconds; a compiled iOS target on a warm simulator is tens of seconds, and that is the honest floor there. "Fast" means "as tight as this toolchain permits, and no slower than necessary" — not a fixed second-count. What it rules out is a minutes-long or flaky loop, in any repo.

---

## 6. TDD — the Pocock way

```
tests only at AGREED seams — agreed at Gate 2
the ideal number of seams is one, the highest reachable
red -> green;  REFACTORING OUTSIDE THE LOOP, it goes to /verified-review
vertical slices, not a horizontal cut

anti-patterns:
  implementation-coupled  test breaks on refactor though behaviour is unchanged
  tautological            the expectation is computed the way the code computes it
  horizontal slicing      all tests first, then all implementation
```

The superpowers Iron Law (*no line of production code without a failing test; code written earlier is deleted*) is rejected: it produces tests against internals — exactly the first anti-pattern.

---

## 7. Debugging — diagnosing-bugs + grafts

```
P1   build a feedback loop         <- GATE, criterion from section 5
                                      no command -> no Phase 2
P2   reproduce + MINIMISE
       cut until every remaining element is load-bearing
P2.5 PATTERN ANALYSIS              <- grafted from superpowers
       find a working analogue in this repo, list EVERY difference
P3   3–5 RANKED hypotheses, each falsifiable with a prediction
       show me before testing
P4   instrument; one probe per prediction; debugger > logs
       tag [DEBUG-xxxx] — cleanup later by one grep
       perf: measure first, then bisect
P5   fix + regression test
       no correct seam -> THAT IS ITSELF THE FINDING
       3+ failed fixes -> STOP, architectural conversation  <- grafted
P6   cleanup + post-mortem: the correct hypothesis into the commit,
       "what would have prevented this?"
```

`systematic-debugging` is rejected as a whole: one hypothesis instead of ranked ones (anchoring on the first plausible idea), no Phase 1 completion criterion, no minimisation, and it drags in the rejected Iron Law.

Grafted from it: Pattern Analysis and the three-fix breaker — Pocock has neither.

---

## 8. What's rejected, and why

The full roster is in [README.md](README.md). What matters here is what was deliberately left out.

| Skill | Why |
|---|---|
| `brainstorming` | a HARD GATE on any trivial thing; `grill-with-docs` is sharper and keeps ADRs |
| `test-driven-development` | Iron Law -> implementation-coupled tests |
| `systematic-debugging` | see section 7 |
| `requesting-code-review` | replaced by the two-axis Pocock review |
| `executing-plans` | replaced by `execute-tickets` |
| `writing-plans` | `to-spec` + `to-tickets` cover it |
| `dispatching-parallel-agents` | baked into `verified-review` and `wayfinder` |
| `using-superpowers` + the SessionStart hook | its mandate fights everything decided above |
| the superpowers plugin as a whole | kept only for the hook; the needed skills are ported |

The hook lives inside the plugin (`hooks/hooks.json`, matcher `startup|clear|compact`) and injects `using-superpowers/SKILL.md` whole, wrapped in `<EXTREMELY_IMPORTANT>`. It can't be edited without being overwritten on update. So the plugin is disabled.

Ported from superpowers instead: `execute-tickets` (from `subagent-driven-development`, dropping the `task-brief` awk script — every ticket is already its own file), `finish-branch`, `using-git-worktrees`, `verification-before-completion`, `receiving-code-review`.

---

## 9. Remaining work

The stack itself is built and ships as the `dev-stack` plugin (§1–§8 realized; the ports, the `.scratch/` patches, `verified-review` running Verify, the `diagnose` grafts, and the `route-me` router are all in place). What remains is repo-side and obkatka.

### Obkatka (first real exercise)

Run **GrammarDiff first**, then Chelsea. GrammarDiff (Electron/Vue/TS) has clean agent-runnable checks (`pnpm test`, three typechecks, lint, `madge --circular`), so a first-run failure implicates the stack, not the substrate. Chelsea has no agent-runnable Verify today (see §9.4 below) — it goes second.

### Per repo

1. `## Build & run` in `AGENTS.md` — currently only Chelsea has it. GrammarDiff needs its `## Commands` renamed and a `CONTEXT.md` + `docs/adr/` created.
2. Chelsea: `AGENTS.md` describes Tier 1 as the whole process — rewrite.
3. Chelsea: 135 files under `docs/superpowers/{specs,plans}` — decide separately.
4. **Chelsea, the A11yID finding — reframed.** `A11yID.swift` is 183 lines of identifiers mandated by `AGENTS.md`, with no consumer: there is no UITests target that reads them. This is not a dead end — it's a half-built bridge. The identifiers are already written and maintained; a single UITests target lights up all of that infrastructure and gives every later Chelsea ticket a real `Verify`. **The first Chelsea feature is to stand up that target.** Until it exists, Chelsea's Verify ceiling is `xcodebuild build` plus an OSLog assertion (AppLogger mirrors to a known path, 11 categories) — real but limited; the one thing it can't cover is "looks and taps right", which is Chelsea's default acceptance shape.

---

## Why it converges

Vertical tickets make `Verify` possible. Gate 2 catches its absence before time is spent on the spec and the briefs. A finding goes to the architecture skill. The decision from there becomes an ADR that outlives the next spec.

And the spec and the briefs die at merge — so they don't lie to the next agent.
