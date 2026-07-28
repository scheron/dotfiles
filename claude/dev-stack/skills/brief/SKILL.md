---
name: brief
description: Write the closed technical execution contract for one unit at pickup, inside the unit's worktree — cutting the ticket's vertical slice into horizontal tasks, each with its files, declared interfaces, fence and proof. For the brief-writer subagent the engine dispatches before the implementer; written to the worktree's .scratch/, ephemeral, dies with the worktree.
user-invocable: false
---

# Brief

A brief is the **closed technical execution contract** for one ticket on one exact worktree commit. It supplies the files, interfaces, binding decisions, bounded tasks, and proof commands needed to implement without discovery or product decisions.

The **brief-writer** explores the worktree; the **implementer** executes only the resulting brief. Any required location, interface, semantic decision, or proof strategy that is not explicit is `NEEDS_CONTEXT` / `BLOCKED`, not implementer discretion.

## The one cut this document makes

The ticket is a **vertical slice** — a narrow but complete path through every layer it touches, ending in behaviour someone can observe. The brief cuts that slice into **horizontal tasks**, one per layer, and that cut is the whole reason this document exists.

Write for **a skilled developer who knows almost nothing about this toolset or problem domain, and does not know good test design well.** That is the calibration for every line below: exact values, named seams, no inference required. Each task's implementer sees *only its own task* — never the ticket, never its neighbours' code.

Both directions of getting the cut wrong have a cost, and the second is the one that actually happens:

- too fine — a task per function; the reviewer has nothing meaningful to reject and the overhead swamps the work;
- **too coarse — one task for the whole slice; the implementer attempts everything at once, drifts out of scope, and the work is redone.** This is the failure mode. Do not resolve doubt by merging.

## Freshness

Write the brief only at pickup, in the unit's worktree. It is valid only for that worktree base; consume interfaces from merged code in the tree. If a required signature is absent, stop as `BLOCKED`.

## Where it lives

```
.scratch/brief-NN.md          in the unit's worktree — born and dying with the worktree
```

Never commit it or put it on the tracker.

## Process

### 1. Read the durable inputs

Read `CONTEXT.md` and relevant ADRs when present, then the ticket and parent spec. Carry the spec's **Implementation Decisions**, terminology, and Global Constraints into concrete brief content.

Four fields of the ticket are load-bearing here:

- **Observable behaviour** — becomes `The slice` at the top of the brief, and the target the review drives.
- **Layers crossed** — your starting proposal for the task cut. Verify it against the tree; it is domain names, not a guarantee.
- **Acceptance** — behaviour-level, so it binds the slice, not a task.
- **Slice acceptance** — the spec's slice-level mandate; it becomes `Verify`.

**Testing Decisions are binding, and they arrive at two heights.** Task-level mandates become each task's `Proof` — focused, fast, allowed to fake dependencies. The slice-level mandate becomes `Verify` and, where the repo has one, a `Sweep` entry — real dependencies, no fakes. Resolve each into named test files and runnable commands, or stop as `BLOCKED` if no valid seam exists. Never satisfy a slice-level mandate with a task-level command.

### 2. Inspect the current tree

Read the exact files and interfaces in this worktree. Record only the locations, signatures, values, and constraints the implementer needs.

### 3. Write the contract

Fill `The slice`, `Files`, `Interfaces`, `Binding Decisions`, `Plan`, `Execution Boundary`, `Verify`, `Sweep`, and `Global Constraints`. Do not leave placeholders or open design choices.

### 4. Run Verify

Run the focused `Verify` command and paste the invocation and result.

### 5. Self-check the task graph

Three passes over what you just wrote — cheap now, expensive once tasks are running in parallel against each other:

- **Names** — does a signature named in one task's `Consumes` match, character for character, the `Produces` that declares it? `clearLayers()` in task 2 against `clearFullLayers()` in task 4 is a defect that only surfaces when both have already been built.
- **Edges** — does every `Consumes` from a sibling task have a matching `Blocked by`? An undeclared edge is a task built against something that does not exist yet.
- **Files** — do two tasks with no edge between them name the same file? If so, either the edge is missing or the cut is wrong. Fix it here.

## The blocks

### The slice

**Mandatory.** One or two lines: the sweep-through behaviour this whole ticket delivers, and how it is observed — the command, the screen, the request, the build. Copied from the ticket's `Observable behaviour`.

It does two jobs. Every task's implementer reads it, so none of them loses what its layer is part of. And the review drives it — this is the flow it observes, so a slice with nothing here has no runtime gate.

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

**This block is load-bearing, not an inventory.** Downstream it is used mechanically: a task's diff is scoped to the files its own task declares, so the reviewer sees that task and not its neighbours' work in the same tree; and anything modified outside the union of every task's declared files belongs to no task, which is a boundary violation caught without an agent looking for it. A path missing here is a change nobody reviews.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — exact signatures this unit calls, copied verbatim from merged code in this worktree, with their source paths.

`Produces` — exact signatures this unit exposes.

### Binding Decisions

**Mandatory.** Record every settled semantic choice not fully expressed by `Interfaces` or `Global Constraints`: behaviour, values, errors/results, compatibility, and public API. Include a decision whenever a competent implementer could otherwise choose a different locally-valid behaviour.

If none remain, write `None — Interfaces and Global Constraints fully determine this unit's semantics.`

### Plan

**Mandatory.** The ticket stays the vertical delivery slice and the review unit; the `Plan` cuts it into **tasks**. Tasks create no tracker tickets and no worktrees — they are dispatch units inside this one.

#### What makes a valid task

Three tests, all of which must pass:

- it is **one functionally whole horizontal layer** of the slice — the transport, the types, the client wiring;
- it is **provable by its own command**, without a neighbour's code existing yet: either it is a leaf, or it works against signatures its `Consumes` declares;
- **a reviewer could meaningfully reject it while approving its neighbour.**

Not a task: two functions, a rename, a config tweak — those fold into the task whose deliverable needs them, along with setup, scaffolding, and docs. Also not a task: the whole slice.

#### Declare the truth about independence

Every task carries `Blocked by` and `Files`, and downstream they decide what runs beside what. So declare what **is**, never what would be convenient:

- a task that consumes a sibling's `Produces` **is blocked by it** — say so;
- two tasks that touch the same file are **not** independent — either declare the edge or cut differently.

**A fully sequential chain is a correct brief.** Layers usually do chain — types, then transport, then UI — and a chain declared honestly is worth more than a false claim of independence, which puts two writers in one file. Never reshape the truth to look parallel.

#### Per task

```
### Task N — <goal in one line>
Blocked by:   <task numbers, or none>
Files:        <exact paths from Files above; the diff is scoped to these>
Consumes:     <exact signatures, with where they come from — a sibling task or merged code>
Produces:     <exact signatures this task exposes>
Acceptance:   <how to tell it is done>
Out of scope: <what not to touch; siblings' files by default>
Proof:        <the exact focused command + expected result>
```

`Consumes` / `Produces` at task level is what makes the cut work at all: **a task's implementer never sees its neighbours, so this block is how it learns the names and types they use.** A declared signature is enough to build against — the neighbour's code does not have to exist yet.

`Out of scope` is per task on purpose. A slice-wide `Execution Boundary` does not tell task 2 to stay out of task 1's files.

Then the steps: focused failing test → run it, record the expected failure → minimum change → run the focused test green. Name real values (`parse("2h") → 7200`, not "test that it parses") and real locations. Omit a step only when it does not apply, and say why.

**No step may require searching for a location, interface, or approach.** If one does, that gap is yours to close. If a task needs a design choice, a new public interface, or an edit outside the boundary, stop with `NEEDS_CONTEXT` / `BLOCKED`.

### Execution Boundary

**Mandatory.** The limits for the **slice as a whole** — each task's own fence is its `Out of scope`, and this block is what neither task may cross:

- **Allowed changes** — exact responsibilities and files.
- **Must not change** — ticket-specific excluded surfaces.
- **Escalate if** — concrete facts requiring `NEEDS_CONTEXT` / `BLOCKED`: an edit outside allowed files, contract conflict, missing interface, new dependency/schema/public API, or unresolved decision.

State a category explicitly even when it has no extra exclusions.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it. It proves *the slice* is done: red-capable against the ticket's acceptance, and resolved from the ticket's `Slice acceptance` where the spec named one.

A task's `Proof` is not this. `Proof` clears one layer and may fake dependencies; `Verify` is the slice's gate and may not use a fake to stand in for the thing the slice exists to deliver.

### Sweep

List every repo-level verification command required beyond `Verify` (test, lint, typecheck, build, e2e, smoke), using commands discovered from the current repo. Include every test required by the spec's Testing Decisions, including gated live/e2e commands. If a mandated test has no runnable seam, name the new test work or stop as `BLOCKED`.

## Global Constraints

Copy binding requirements from the spec verbatim: values, formats, and component relationships. Verbatim because paraphrase loses the binding — and copy only what binds, since this block is handed to every task's reviewer as well as every implementer.

## No placeholders

Use real values only: no `TODO`, `<your-value-here>`, or "something like". Resolve unknowns or stop as `BLOCKED`.

## The Verify gate

`Verify` is one named, deterministic, agent-runnable, focused command that has already run. Paste the invocation and result. It must be red-capable against this unit's acceptance; for behaviour-neutral wide refactors, build/typecheck is valid. If no unattended command exists, stop and report the finding; never write `verify manually`.

## Template

```markdown
# Brief NN — <ticket title>

**Ticket:** <tracker ref or .scratch path>

## The slice
`renderLayer` clips to layer bounds end to end — observed by running
`npm run demo -- --clip` and seeing the shape cropped at the bounds.

## Files
- `path/to/geometry.ts` — the bounds intersection helper
- `path/to/geometry.test.ts` (new) — tests at <seam>
- `path/to/thing.ts` — `renderLayer` consumes the helper
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

### Task 1 — Bounds intersection
Blocked by:   none
Files:        `path/to/geometry.ts`, `path/to/geometry.test.ts` (new)
Consumes:     —
Produces:     `intersect(a: Bounds, b: Bounds): Bounds`
Acceptance:   disjoint bounds return the empty rect; overlap returns the overlap.
Out of scope: `path/to/thing.ts` and anything rendering — task 2 owns those.
Proof:        `npm test -- geometry.test.ts` → PASS

- [ ] failing test: `intersect({0,0,10,10}, {5,5,10,10})` → `{5,5,5,5}`
- [ ] run it; expect failure because `intersect` does not exist
- [ ] implement the minimum in `path/to/geometry.ts`
- [ ] run it green

### Task 2 — Clip a layer within its bounds
Blocked by:   Task 1
Files:        `path/to/thing.ts`, `path/to/thing.test.ts` (new)
Consumes:     `intersect(a: Bounds, b: Bounds): Bounds` — from Task 1
              `foo(bar: Baz): Promise<Qux>` — from `path/to/module.ts`
Produces:     `renderLayer(layer: Layer, opts: RenderOpts): void`
Acceptance:   `renderLayer(layer, {clip: true})` crops output; source geometry untouched.
Out of scope: `path/to/geometry.ts` — task 1 owns it. Other rendering modes.
Proof:        `npm test -- thing.test.ts` → PASS with the clipping assertion

- [ ] failing test: assert `renderLayer(layer, {clip: true})` clips to the layer bounds
- [ ] run it; expect failure because `renderLayer` does not exist
- [ ] implement the minimum: call `intersect`, then `foo(bar)`, return after drawing
- [ ] run it green

## Execution Boundary
**Allowed changes**
- `path/to/geometry.ts` — add only `intersect`.
- `path/to/thing.ts` — add only the `renderLayer` behaviour described above.
- both `.test.ts` files — focused coverage for those behaviours.

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
- Ship without a personally run `Verify`, or write `verify manually`.
- Copy `Consumes` from memory or another brief instead of the code in this worktree.
- Omit `The slice`, `Interfaces`, `Binding Decisions`, `Execution Boundary`, a task's `Proof`, or a mandated test.
- Ship one task for a slice that has layers, or resolve doubt about the cut by merging.
- Declare two tasks independent when they share a file or a signature — say what is, not what would run faster.
- Leave a step that requires searching for a location, interface, or approach.
- Treat an open design choice as settled; stop as `NEEDS_CONTEXT` / `BLOCKED`.
- Paraphrase Global Constraints, or satisfy a slice-level test mandate with a task-level command.

**Related:** `/cold-read` checks the spec before any ticket is dispatched · `/to-implement` dispatches you first, then the implementer that reads your brief · `/verified-review` runs the `Verify` command this brief names
