---
name: brief
description: Generate the technical brief for your ticket at pickup, inside your own worktree — Files, Interfaces, Verify, Model. Written to the spoke's .scratch/, ephemeral, dies with the worktree. Use as the first act after branching, before writing any code.
---

# Brief

A ticket says **what to build**. A brief says **where the code is, what it must call, and the command that proves it worked**. The ticket is durable and path-free; the brief is disposable and exact.

You — the implementer — write the brief **yourself, at pickup, inside your own worktree**: the first act after branching, before any code.

## Why at pickup, never at planning time

The old failure mode: an orchestrator writes briefs for the whole feature at planning time, and ticket 07's brief is a snapshot of the codebase taken before tickets 01–06 changed it. Staleness scales with depth in the dependency graph — and a stale brief is **worse than no brief**, because the implementer trusts it and the wrong path costs more than an absent one.

This topology makes that staleness impossible by construction: you write the brief against the exact commit your spoke branched from, in the same tree you are about to change. The ticket has no paths *because* it must survive the gap between planning and pickup; the brief carries paths *because* for you there is no gap.

**Corollary:** everything your ticket consumes is already merged code in your tree — dependent tickets launch from the merged result of their blockers. If a signature you need is missing, the ticket was dispatched too early: escalate as BLOCKED instead of briefing against paper.

## Where it lives

```
.scratch/brief-NN.md          in your worktree — born and dying with the spoke
```

Never on the tracker, never on the hub. The technical bottom physically cannot reach a place where it would still be readable — and lying — in six months.

## Process

### 1. Read the durable layer first

It is already in your tree — durable docs are committed to the hub before dispatch. `CONTEXT.md` for the domain vocabulary, ADRs in the area you're touching, the ticket, and its parent spec — specifically the spec's **Implementation Decisions** and **Testing Decisions** (the latter names the prior art for tests).

Names in the brief come from `CONTEXT.md`. If the glossary says `Order`, the interfaces say `Order` — not `Purchase`.

### 2. Delegate the walk

Dispatch an `Explore` subagent to map the code. It returns the map; the raw greps and file dumps stay in its context, not yours. Your window is for building the ticket — spend it on the compression, not the exploration.

### 3. Fill the four blocks

### 4. Run the Verify gate

Nothing leaves this skill without a verified `Verify` command. See below.

## The four blocks

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — signatures this ticket calls. Read them from the code in your tree: the real, already-merged code your spoke branched from. The contract is the code, not paper from a previous ticket — paste each signature as the file states it, with the path it came from. Recalled names drift (the code says `clearLayers`, memory offers `clearFullLayers`); pasted ones can't.

`Produces` — signatures this ticket exposes. Later tickets will meet them as merged code; the reviewer checks you delivered exactly this surface.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it.

### Model

`cheap` | `standard` — the one dispatch knob left (every unit is a subagent in a worktree; there is nothing else to choose).

Turn count beats token price: a cheap model that takes three times the turns costs more. `cheap` only when the brief leaves nothing to decide — pure transcription plus tests; `standard` otherwise.

## Global Constraints

Copy binding requirements from the spec **verbatim** — exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). Paraphrase loses the binding.

These bind you now and travel to the reviewer of this ticket.

## No placeholders

Every value in the brief is the real one. No `TODO`, no `<your-value-here>`, no "something like". A placeholder in a brief becomes a placeholder in the code, and the review has to catch what the brief should have prevented.

If you don't know a value, that's the finding — resolve it before writing code, or escalate as BLOCKED.

## The Verify gate

`Verify` is a **named, agent-runnable command that you have already run at least once**. Paste the invocation and its output into the brief.

- [ ] **Red-capable** — drives the real path and asserts the ticket's exact acceptance criteria. Not "runs without erroring": it must be able to fail if the ticket isn't done.
- [ ] **Deterministic** — same verdict every run.
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — runs unattended.

Prefer a command `AGENTS.md` `## Build & run` already documents. If you invent one, add it there.

**If no such command exists, that is a finding, not a footnote.** Stop and report it with the specifics — this is a finding for `/improve-codebase-architecture`. Do **not** write "verify manually" — a ticket nobody can verify unattended cannot pass Definition of Done, and pretending otherwise moves the failure to review, where it costs more.

Wide refactors are the exception: behaviour doesn't change by definition, so `Verify: build` (or the typechecker) is the honest command.

## Template

```markdown
# Brief NN — <ticket title>

**Ticket:** <tracker ref or hub .scratch path>
**Model:** cheap | standard

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

## Global Constraints
- <verbatim from spec>
```

## Red flags

**Never:**
- Accept a brief written for you outside the spoke, or write one before your worktree exists — only a brief born at pickup describes the commit you branched from
- Put the brief anywhere but your worktree's `.scratch/`
- Put paths or signatures into the ticket or the spec instead
- Ship a brief whose `Verify` you have not personally run
- Write "verify manually" — that's a finding for `/improve-codebase-architecture`
- Fill `Consumes` from another ticket's brief or from memory — read it from the code in your tree
- Omit `Interfaces` because "the code is right there" — unpinned signatures get recalled, and recalled names drift
- Paraphrase a Global Constraint

**Related:** `/cold-read` checks the spec before any ticket is dispatched · `/to-implementation` dispatches the implementer that writes this brief · `/verified-review` runs the `Verify` command this brief names
