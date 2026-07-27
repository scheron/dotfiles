---
name: brief
description: Write the closed technical execution contract for one unit at pickup, inside the unit's worktree — Files, Interfaces, Binding Decisions, Plan, Execution Boundary, Verify, Sweep. For the brief-writer subagent the engine dispatches before the implementer; written to the worktree's .scratch/, ephemeral, dies with the worktree.
user-invocable: false
---

# Brief

A ticket says **what to build**. A brief says **where the code is, what it must call, the decisions already made, the ordered steps that build it, what it must not touch, and the command that proves it worked** — everything the implementer needs so it *executes* instead of *exploring* or deciding. The ticket is durable and path-free; the brief is disposable and exact.

You — the **brief-writer** — are a fresh subagent dispatched into the unit's worktree at pickup: the first act after branching, before the implementer exists. You explore; the implementer builds. The walk you do is the walk the implementer must **not** have to redo — every location, name, and step you resolve here is context its window never spends. Your product is the compression that keeps its window clean — and a weak brief poisons everything downstream.

## The brief owns discovery

The implementer is weak by design — a fresh, cheap window that should *execute*, not investigate. Every location it has to grep for, every signature it has to recall, every ordering it has to infer is context spent re-doing the walk you already did — the failure mode that makes a brief only half a brief. So the rule: **you own discovery; the implementer owns typing.** If following the brief would send the implementer back into the code to find, name, or decide something, that gap is yours to close here — or, if it's an open decision with several valid answers, to escalate. A brief that describes the terrain but not the route hasn't finished the job.

## Why at pickup, never at planning time

The failure mode this avoids: an orchestrator writes briefs for the whole feature at planning time, and ticket 07's brief is a snapshot of the codebase taken before tickets 01–06 changed it. Staleness scales with depth in the dependency graph — and a stale brief is **worse than no brief**, because the implementer trusts it and the wrong path costs more than an absent one.

This topology makes that staleness impossible by construction: you write the brief against the exact commit the worktree branched from, in the same tree the implementer is about to change. The ticket has no paths *because* it must survive the gap between planning and pickup; the brief carries paths *because* for you there is no gap.

**Corollary:** everything this unit consumes is already merged code in the tree — a dependent ticket branches from the default branch after its blockers merged. If a signature the unit needs is missing, it was picked up too early: escalate as BLOCKED instead of briefing against paper.

## Where it lives

```
.scratch/brief-NN.md          in the unit's worktree — born and dying with the worktree
```

Never on the tracker, never committed to the repo. The technical bottom physically cannot reach a place where it would still be readable — and lying — in six months.

## Process

### 1. Read the durable layer first

It is already in your tree — the domain docs live on the default branch. Read `CONTEXT.md` for the domain vocabulary and any ADRs in the area you're touching **if they exist** (a small change may have neither), plus the ticket and its parent spec — specifically the spec's **Implementation Decisions** and **Testing Decisions**.

The spec's **Testing Decisions are binding**, not advisory. They name the test scope this unit must deliver — the acceptance / integration / e2e test that proves the feature works, not merely the prior art. Your job is to enumerate what tests are possible at the seams and resolve the spec's mandate into concrete commands and (new) test files. You do **not** get to decide that a mandated test — an e2e, a real-run acceptance — is unnecessary and quietly ship a couple of unit tests instead. If the mandate is unclear or seems wrong, that is a question for the user, not a licence to narrow it silently.

Names in the brief come from `CONTEXT.md` when it exists. If the glossary says `Order`, the interfaces say `Order` — not `Purchase`.

### 2. Walk the code yourself

You **are** the walk. Explore directly — greps, file reads, whatever the map needs: the raw dumps stay in your context and die with you; only the compressed brief reaches the implementer. Delegating exploration to yet another subagent adds a hop without protecting anyone — your window is disposable by design.

### 3. Fill the blocks

Terrain first — `Files`, `Interfaces`, the `Global Constraints` you copy verbatim. Then close the semantic decisions and scope: `Binding Decisions`, `Plan`, `Execution Boundary`. This is the step that separates a half-brief from a whole one — the terrain says what exists, the `Plan` says what the implementer does with it, in order, and the boundary says where it must stop.

### 4. Run the Verify gate

Nothing leaves this skill without a verified `Verify` command. See below.

## The blocks

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — signatures this unit calls. Read them from the code in your tree: the real, already-merged code your worktree branched from. The contract is the code, not paper from a previous ticket — paste each signature as the file states it, with the path it came from. Recalled names drift (the code says `clearLayers`, memory offers `clearFullLayers`); pasted ones can't.

`Produces` — signatures this unit exposes. Later work will meet them as merged code; the reviewer checks you delivered exactly this surface.

### Binding Decisions

**Mandatory. Never leave a semantic choice implicit.** Record the already-settled choices that are not fully expressed by `Interfaces` or `Global Constraints`: exact behaviour, values, error/result semantics, compatibility choices, and the intended viewpoint of the change. Include a decision only when a competent implementer could otherwise make a different locally-valid choice. These are decisions, not implementation prose: `empty input maps to null, never 0`; `preserve the existing public error text`; `do not add a public API`.

If `Interfaces` and `Global Constraints` genuinely settle every semantic choice, write `None — Interfaces and Global Constraints fully determine this unit's semantics.` Do not silently omit the block.

### Plan

**Mandatory. This is where your walk becomes the implementer's instructions.**

The ordered build steps — the route through the change, one TDD slice per step, in the sequence the implementer executes them. `Files` and `Interfaces` are the terrain; the `Plan` is the path across it. The implementer should never open a file to decide *what* to do or *where* — only to make the edit you already scoped.

Each step names:

- **the test** — the file (`(new)` if new) and the behaviour it pins, with the **real assertion values**: `parse("2h") → 7200`, not "test that it parses".
- **the change** — the exact location and what to write there, in terms of the `Interfaces` above: which function to call, what to return, where to insert. Concrete enough to type without searching.

Steps are red-green slices: write the failing test, make it pass, move on. Keep each to one behaviour, not a whole file — a step a reviewer could point at.

Pin **names, values, locations, and order** — not every line. The implementer is a competent coder working `/tdd`; paste a code snippet only where the shape is genuinely non-obvious and prose would be ambiguous. The bar is not "I wrote the code for them"; it is "no step forces a search." A step that needs a location, a signature, or an approach you left unresolved is a hole — resolve it, or, if it's an open design decision with several valid answers, escalate BLOCKED rather than guessing one into the `Plan`.

### Execution Boundary

**Mandatory. The route says what to do; this block says what the unit is not allowed to decide or expand.** It makes scope mechanically checkable instead of relying on an implementer's restraint.

- **Allowed changes** — the exact responsibilities and files this unit may change. `Files` is the inventory; here state the permitted change at each seam, especially when a named file has adjacent responsibilities that are out of scope.
- **Must not change** — ticket-specific non-goals and tempting adjacent surfaces: public API shape, schema, dependency set, caller behaviour, unrelated variants, formatting, or refactors, as applicable. Do not repeat generic YAGNI; name the real boundary you observed in this tree.
- **Escalate if** — concrete facts that require `NEEDS_CONTEXT` or `BLOCKED` rather than an implementation decision: a required edit outside the allowed files, a conflict with an existing public contract, a missing interface, a new dependency/schema/public API, or an unresolved semantic choice.

Every entry is specific to this unit. If a category does not apply, state that explicitly (`Must not change: no additional ticket-specific exclusions beyond the allowed changes above`), never leave the section incomplete.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it. It proves *this unit* is done: red-capable against the unit's acceptance.

### Sweep

The repo's verification directions — the commands the orchestrator hands to the test-runner and to `/verified-review`'s stage 0, beyond the focused `Verify`. One line per direction with its exact command: test, lint, typecheck, build, e2e, a `curl` smoke — whatever this repo actually uses to prove itself. Discover them by walking the repo (package scripts, CI, Makefile), never by assuming; a repo with only tests lists only tests.

**Plus every test the spec's Testing Decisions mandate** — including a gated e2e / live smoke: list it with its gate (e.g. `VIKING_LIVE=1 npm run test:e2e:live`) and mark it flake-tolerant so the runner retries rather than red-gates on a blip. A mandated test that the repo has no runnable form for yet is not a reason to drop it — it is work for this unit: name the (new) test file in `Files` and its command here, or, if the seam genuinely doesn't exist, escalate BLOCKED. Never silently narrow the mandate to whatever already runs.

The focused `Verify` is the fast inner-loop gate and **may fake external dependencies** to stay deterministic and quick; that is expected. But a fast fake `Verify` does **not** discharge the acceptance/e2e mandate — that lives here in `Sweep` and is driven for real at the review's real-run gate. A quick fake `Verify` **and** a mandated e2e is the normal shape; neither substitutes for the other.

## Global Constraints

Copy binding requirements from the spec **verbatim** — exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). Paraphrase loses the binding.

These bind the implementer and travel to the reviewer of this unit.

## No placeholders

Every value in the brief is the real one. No `TODO`, no `<your-value-here>`, no "something like". A placeholder in a brief becomes a placeholder in the code, and the review has to catch what the brief should have prevented.

If you don't know a value, that's the finding — resolve it before handing off, or escalate as BLOCKED.

## The Verify gate

`Verify` is a **named, agent-runnable command that you have already run at least once**. Paste the invocation and its output into the brief.

At pickup that output is normally **red** — the unit isn't built yet, and that red paste is the review's "before" evidence: `/verified-review` reads it instead of re-running the past. A green at pickup means the command cannot fail and is no Verify — except the wide-refactor case below, where a green build is the honest verdict.

- [ ] **Red-capable** — drives the real path and asserts the unit's exact acceptance criteria. Not "runs without erroring": it must be able to fail if the unit isn't done.
- [ ] **Deterministic** — same verdict every run.
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — runs unattended.

Prefer a command the repo already uses — a package script, a documented task — found by walking the repo, over one you invent.

**If no such command exists, that is a finding, not a footnote.** Stop and report it with the specifics — this is a finding for `/improve-codebase-architecture`. Do **not** write "verify manually" — a unit nobody can verify unattended cannot pass Definition of Done, and pretending otherwise moves the failure to review, where it costs more.

Wide refactors are the exception: behaviour doesn't change by definition, so `Verify: build` (or the typechecker) is the honest command.

## Template

```markdown
# Brief NN — <ticket title>

**Ticket:** <tracker ref or .scratch path>

## Files
- `path/to/thing.ts` — what changes here
- `path/to/thing.test.ts` (new) — tests at <seam>

## Interfaces
**Consumes**
- `foo(bar: Baz): Promise<Qux>` — from `path/to/module.ts`

**Produces**
- `renderLayer(layer: Layer, opts: RenderOpts): void`

## Binding Decisions
- `clip: true` clips to the layer bounds; it does not alter the source geometry.
- No new public API is introduced.

## Plan
1. **<slice>** — test: `path/to/thing.test.ts` (new) asserts `renderLayer(layer, {clip:true})` clips to bounds. Change: in `path/to/thing.ts`, add `renderLayer`; call `foo(bar)` from `Consumes`, return `void` after drawing.
2. **<slice>** — test: … asserts <behaviour with real values>. Change: in `path/to/thing.ts`, <concrete edit in terms of Interfaces>.

## Execution Boundary
**Allowed changes**
- `path/to/thing.ts` — add only the `renderLayer` behaviour described above.
- `path/to/thing.test.ts` — add focused coverage for that behaviour.

**Must not change**
- the `Layer` data shape, source geometry, or other rendering modes.
- public call sites or dependencies.

**Escalate if**
- clipping requires changing a caller, a public interface, or any file outside `Files`.
- the existing geometry contract conflicts with the binding decision above.

## Verify
```
<command>
```
Already run — output:
```
<paste>
```

## Sweep
- test: `<command>`
- lint: `<command>`
- (only the directions this repo actually has)

## Global Constraints
- <verbatim from spec>
```

## Red flags

**Never:**
- Write the brief outside the unit's worktree, or before it exists — only a brief born at pickup describes the commit the worktree branched from
- Put the brief anywhere but the worktree's `.scratch/`
- Hand the implementer anything beyond the brief — your exploration dies with you
- Put paths or signatures into the ticket or the spec instead
- Ship a brief whose `Verify` you have not personally run
- Write "verify manually" — that's a finding for `/improve-codebase-architecture`
- Fill `Consumes` from another ticket's brief or from memory — read it from the code in the tree
- Omit `Interfaces` because "the code is right there" — unpinned signatures get recalled, and recalled names drift
- Omit `Binding Decisions`, or leave a semantic choice to the implementer because it seems obvious — locally plausible behaviour can still be the wrong product behaviour
- Ship a brief with no `Plan`, or a `Plan` step that forces the implementer to search for a location, name, or approach — the walk is yours; a step it can't execute without re-exploring is a hole, not brevity
- Encode an open design decision (several valid answers) into the `Plan` as if it were settled — that's a BLOCK, not a guess
- Omit `Execution Boundary`, use it as a generic YAGNI reminder, or let it leave an adjacent public surface, schema, dependency, caller, or refactor decision to the implementer — name the actual unit-specific limits and escalation triggers
- Paraphrase a Global Constraint
- Drop or downgrade a test the spec's Testing Decisions mandate — you enumerate the tests and carry the spec's mandate down; deciding an e2e/acceptance test "isn't needed" is not yours to make. A missing runnable form is a finding to resolve or BLOCK on, never a silent omission.

**Related:** `/cold-read` checks the spec before any ticket is dispatched · `/to-implement` dispatches you first, then the implementer that reads your brief · `/verified-review` runs the `Verify` command this brief names
