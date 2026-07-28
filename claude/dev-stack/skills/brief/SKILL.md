---
name: brief
description: Write the closed technical execution contract for one unit at pickup, inside the unit's worktree — Files, Interfaces, Binding Decisions, Plan, Execution Boundary, Verify, Sweep. For the brief-writer subagent the engine dispatches before the implementer; written to the worktree's .scratch/, ephemeral, dies with the worktree.
user-invocable: false
---

# Brief

A brief is the **closed technical execution contract** for one ticket on one exact worktree commit. It supplies the files, interfaces, binding decisions, bounded tasks, and proof commands needed to implement without discovery or product decisions.

The **brief-writer** explores the worktree; the **implementer** executes only the resulting brief. Any required location, interface, semantic decision, or proof strategy that is not explicit is `NEEDS_CONTEXT` / `BLOCKED`, not implementer discretion.

## Freshness

Write the brief only at pickup, in the unit's worktree. It is valid only for that worktree base; consume interfaces from merged code in the tree. If a required signature is absent, stop as `BLOCKED`.

## Where it lives

```
.scratch/brief-NN.md          in the unit's worktree — born and dying with the worktree
```

Never commit it or put it on the tracker.

## Process

### 1. Read the durable inputs

Read `CONTEXT.md` and relevant ADRs when present, then the ticket and parent spec. Carry the spec's **Implementation Decisions**, **Testing Decisions**, terminology, and Global Constraints into concrete brief content. Testing Decisions are binding: name the required test files and runnable commands, or stop as `BLOCKED` if no valid seam exists.

### 2. Inspect the current tree

Read the exact files and interfaces in this worktree. Record only the locations, signatures, values, and constraints the implementer needs.

### 3. Write the contract

Fill `Files`, `Interfaces`, `Binding Decisions`, `Plan`, `Execution Boundary`, `Verify`, `Sweep`, and `Global Constraints`. Do not leave placeholders or open design choices.

### 4. Run Verify

Run the focused `Verify` command and paste the invocation and result.

## The blocks

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — exact signatures this unit calls, copied verbatim from merged code in this worktree, with their source paths.

`Produces` — exact signatures this unit exposes.

### Binding Decisions

**Mandatory.** Record every settled semantic choice not fully expressed by `Interfaces` or `Global Constraints`: behaviour, values, errors/results, compatibility, and public API. Include a decision whenever a competent implementer could otherwise choose a different locally-valid behaviour.

If none remain, write `None — Interfaces and Global Constraints fully determine this unit's semantics.`

### Plan

**Mandatory.** The ticket remains the vertical delivery slice and the dispatch/review unit. The brief may decompose that slice into ordered **brief tasks** so the implementer does not attempt the whole change at once. Brief tasks do not create tracker tickets, worktrees, or separate agent dispatches.

A brief task is the smallest independently testable deliverable that a reviewer could meaningfully reject while approving its neighbour. Fold setup, configuration, scaffolding, and documentation into the task whose deliverable needs them; split only at a real reviewable boundary. Each task ends with its focused verification command and expected result.

For each task, state:

- **Goal** — one observable behaviour or deliverable.
- **Files and interfaces** — the exact named seams from the blocks above.
- **Actions** — each action is one 2–5 minute operation: write the failing test; run it and record the expected failure; implement the minimum change; run the focused test and expect success. Omit an action only when it does not apply, and say why.
- **Proof** — the exact focused command, assertion values, and expected result.

Use real names, paths, and values. An action must not require searching for a location, interface, or approach. If a task needs a design choice, a new public interface, or an edit outside the boundary, stop with `NEEDS_CONTEXT` / `BLOCKED`.

### Execution Boundary

**Mandatory.** State the explicit limits for this unit:

- **Allowed changes** — exact responsibilities and files.
- **Must not change** — ticket-specific excluded surfaces.
- **Escalate if** — concrete facts requiring `NEEDS_CONTEXT` / `BLOCKED`: an edit outside allowed files, contract conflict, missing interface, new dependency/schema/public API, or unresolved decision.

State a category explicitly even when it has no extra exclusions.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it. It proves *this unit* is done: red-capable against the unit's acceptance.

### Sweep

List every repo-level verification command required beyond `Verify` (test, lint, typecheck, build, e2e, smoke), using commands discovered from the current repo. Include every test required by the spec's Testing Decisions, including gated live/e2e commands. If a mandated test has no runnable seam, name the new test work or stop as `BLOCKED`.

## Global Constraints

Copy binding requirements from the spec verbatim: values, formats, and component relationships.

## No placeholders

Use real values only: no `TODO`, `<your-value-here>`, or "something like". Resolve unknowns or stop as `BLOCKED`.

## The Verify gate

`Verify` is one named, deterministic, agent-runnable, focused command that has already run. Paste the invocation and result. It must be red-capable against this unit's acceptance; for behaviour-neutral wide refactors, build/typecheck is valid. If no unattended command exists, stop and report the finding; never write `verify manually`.

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

### Task 1 — Clip a layer within its existing bounds
**Goal:** `renderLayer(layer, {clip: true})` clips output to the layer bounds without changing source geometry.

**Files and interfaces**
- `path/to/thing.ts` — add `renderLayer` using `foo(bar)` from `Consumes`.
- `path/to/thing.test.ts` (new) — focused coverage.

- [ ] **Action 1 — write the failing test:** assert `renderLayer(layer, {clip: true})` clips to the layer bounds.
- [ ] **Action 2 — verify red:** run `npm test -- thing.test.ts`; expect failure because `renderLayer` does not exist.
- [ ] **Action 3 — implement minimum:** add `renderLayer(layer: Layer, opts: RenderOpts): void`; call `foo(bar)` and return after drawing.
- [ ] **Action 4 — verify green:** run `npm test -- thing.test.ts`; expect the clipping assertion to pass.

**Proof:** `npm test -- thing.test.ts` → PASS with the clipping assertion.

Add a second `### Task N` only when it is independently testable and reviewable.

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
- Write the brief before the worktree exists or outside its `.scratch/`.
- Commit the brief, put it on the tracker, or hand the implementer uncompressed exploration.
- Put paths or signatures in the ticket/spec instead of the brief.
- Ship without a personally run `Verify`, or write `verify manually`.
- Copy `Consumes` from memory or another brief instead of merged code in this worktree.
- Omit `Interfaces`, `Binding Decisions`, `Execution Boundary`, task proof, or mandated tests.
- Leave an action that requires searching for a location, interface, or approach.
- Treat an open design choice as settled; stop as `NEEDS_CONTEXT` / `BLOCKED`.
- Paraphrase Global Constraints or narrow the spec's Testing Decisions.

**Related:** `/cold-read` checks the spec before any ticket is dispatched · `/to-implement` dispatches you first, then the implementer that reads your brief · `/verified-review` runs the `Verify` command this brief names
