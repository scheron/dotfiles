---
name: brief
description: Write the technical brief for one unit at pickup, inside the unit's worktree — Files, Interfaces, Verify, Sweep. For the brief-writer subagent the engine dispatches before the implementer; written to the worktree's .scratch/, ephemeral, dies with the worktree.
user-invocable: false
---

# Brief

A ticket says **what to build**. A brief says **where the code is, what it must call, and the command that proves it worked**. The ticket is durable and path-free; the brief is disposable and exact.

You — the **brief-writer** — are a fresh subagent dispatched into the unit's worktree at pickup: the first act after branching, before the implementer exists. You explore; the implementer builds. Your product is the compression that keeps its window clean — and a weak brief poisons everything downstream.

## Why at pickup, never at planning time

The old failure mode: an orchestrator writes briefs for the whole feature at planning time, and ticket 07's brief is a snapshot of the codebase taken before tickets 01–06 changed it. Staleness scales with depth in the dependency graph — and a stale brief is **worse than no brief**, because the implementer trusts it and the wrong path costs more than an absent one.

This topology makes that staleness impossible by construction: you write the brief against the exact commit the worktree branched from, in the same tree the implementer is about to change. The ticket has no paths *because* it must survive the gap between planning and pickup; the brief carries paths *because* for you there is no gap.

**Corollary:** everything this unit consumes is already merged code in the tree — a dependent ticket branches from the default branch after its blockers merged. If a signature the unit needs is missing, it was picked up too early: escalate as BLOCKED instead of briefing against paper.

## Where it lives

```
.scratch/brief-NN.md          in the unit's worktree — born and dying with the worktree
```

Never on the tracker, never committed to the repo. The technical bottom physically cannot reach a place where it would still be readable — and lying — in six months.

## Process

### 1. Read the durable layer first

It is already in your tree — the domain docs live on the default branch. Read `CONTEXT.md` for the domain vocabulary and any ADRs in the area you're touching **if they exist** (a small change may have neither), plus the ticket and its parent spec — specifically the spec's **Implementation Decisions** and **Testing Decisions** (the latter names the prior art for tests).

Names in the brief come from `CONTEXT.md` when it exists. If the glossary says `Order`, the interfaces say `Order` — not `Purchase`.

### 2. Walk the code yourself

You **are** the walk. Explore directly — greps, file reads, whatever the map needs: the raw dumps stay in your context and die with you; only the compressed brief reaches the implementer. Delegating exploration to yet another subagent adds a hop without protecting anyone — your window is disposable by design.

### 3. Fill the blocks

### 4. Run the Verify gate

Nothing leaves this skill without a verified `Verify` command. See below.

## The blocks

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — signatures this unit calls. Read them from the code in your tree: the real, already-merged code your worktree branched from. The contract is the code, not paper from a previous ticket — paste each signature as the file states it, with the path it came from. Recalled names drift (the code says `clearLayers`, memory offers `clearFullLayers`); pasted ones can't.

`Produces` — signatures this unit exposes. Later work will meet them as merged code; the reviewer checks you delivered exactly this surface.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it. It proves *this unit* is done: red-capable against the unit's acceptance.

### Sweep

The repo's verification directions — the commands the orchestrator hands to the test-runner and to `/verified-review`'s stage 0, beyond the focused `Verify`. One line per direction with its exact command: test, lint, typecheck, build, e2e, a `curl` smoke — whatever this repo actually uses to prove itself. Discover them by walking the repo (package scripts, CI, Makefile), never by assuming; a repo with only tests lists only tests.

## Global Constraints

Copy binding requirements from the spec **verbatim** — exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). Paraphrase loses the binding.

These bind the implementer and travel to the reviewer of this unit.

## No placeholders

Every value in the brief is the real one. No `TODO`, no `<your-value-here>`, no "something like". A placeholder in a brief becomes a placeholder in the code, and the review has to catch what the brief should have prevented.

If you don't know a value, that's the finding — resolve it before handing off, or escalate as BLOCKED.

## The Verify gate

`Verify` is a **named, agent-runnable command that you have already run at least once**. Paste the invocation and its output into the brief.

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
- Paraphrase a Global Constraint

**Related:** `/cold-read` checks the spec before any ticket is dispatched · `/to-implement` dispatches you first, then the implementer that reads your brief · `/verified-review` runs the `Verify` command this brief names
