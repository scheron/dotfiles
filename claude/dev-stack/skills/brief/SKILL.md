---
name: brief
description: Generate the technical brief for one ticket at the moment it is picked up — Files, Interfaces, Verify, Run as. Written to .scratch/, ephemeral, dies at merge. Use when starting work on a ticket, before dispatching an implementer.
---

# Brief

A ticket says **what to build**. A brief says **where the code is, what it must call, and the command that proves it worked**. The ticket is durable and path-free; the brief is disposable and exact.

The brief is generated **at pickup**, for **one ticket on the frontier**, and never earlier.

## Why at pickup, never at planning time

Write briefs for the whole feature during `/to-tickets` and ticket 07's brief is a snapshot of the codebase taken before tickets 01–06 changed it. Staleness scales with depth in the dependency graph — and a stale brief is **worse than no brief**, because the implementer trusts it and the wrong path costs more than an absent one.

The ticket has no paths *because* it must survive that gap. The brief carries paths *because* it won't have to.

**Corollary:** never write a brief for a ticket whose blockers aren't all closed. If you want one, the ticket isn't ready — work the frontier.

## Where it lives

```
.scratch/<feature>/brief-NN.md          always local, always gitignored
```

Never on the tracker. The technical bottom physically cannot reach a place where it would still be readable — and lying — in six months.

## Process

### 1. Read the durable layer first

`CONTEXT.md` for the domain vocabulary, ADRs in the area you're touching, the ticket, and its parent spec — specifically the spec's **Implementation Decisions** and **Testing Decisions** (the latter names the prior art for tests).

Names in the brief come from `CONTEXT.md`. If the glossary says `Order`, the interfaces say `Order` — not `Purchase`.

### 2. Delegate the walk

Dispatch an `Explore` subagent to map the code. It returns the map; the raw greps and file dumps stay in its context, not yours.

You are about to hand the implementer a fresh window — don't spend your own filling it with the exploration you're supposed to be compressing.

### 3. Fill the four blocks

### 4. Run the Verify gate

Nothing leaves this skill without a verified `Verify` command. See below.

## The four blocks

### Files

Exact paths, each with one clause on what changes there. New files marked `(new)`.

### Interfaces

**Mandatory. Never omit this block.**

`Consumes` — signatures this ticket calls that already exist or come from an earlier ticket.
`Produces` — signatures this ticket exposes that later tickets will call.

A subagent sees **only its own task**. Without this block, slice 3 writes `clearLayers` and slice 7 calls `clearFullLayers`, and nothing catches it until integration. The `Produces` block of ticket N is the `Consumes` block of ticket N+1 — carry it forward verbatim.

### Verify

**One named command.** Not a description of testing — the command, and the evidence you already ran it.

### Run as

`[inline]` — you do it in this session. Cross-cutting, or judgement-heavy.
`[subagent:cheap]` — 1–2 files, complete spec, transcription plus tests.
`[subagent:standard]` — multiple files, integration concerns, pattern matching.

Turn count beats token price: a cheap model that takes three times the turns costs more. Cheap tier only when the brief leaves nothing to decide.

## Global Constraints

Copy binding requirements from the spec **verbatim** — exact values, exact formats, stated relationships between components ("same layout as X", "matches Y"). Paraphrase loses the binding.

These travel to every implementer and every reviewer working this feature.

## No placeholders

Every value in the brief is the real one. No `TODO`, no `<your-value-here>`, no "something like". A placeholder in a brief becomes a placeholder in the code, and the review has to catch what the brief should have prevented.

If you don't know a value, that's the finding — resolve it before dispatch, or mark the ticket blocked.

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

**Ticket:** <tracker ref or .scratch path>
**Run as:** [inline] | [subagent:cheap] | [subagent:standard]

## Files
- `path/to/thing.ts` — what changes here
- `path/to/thing.test.ts` (new) — tests at <seam>

## Interfaces
**Consumes**
- `foo(bar: Baz): Promise<Qux>` — from ticket 03

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
- Write a brief for a ticket that still has open blockers
- Put a brief anywhere but `.scratch/`
- Put paths or signatures into the ticket or the spec instead
- Ship a brief whose `Verify` you have not personally run
- Write "verify manually" — that's a finding for `/improve-codebase-architecture`
- Omit `Interfaces` because "it's obvious" — the subagent cannot see the other tickets
- Paraphrase a Global Constraint

**Related:** `/cold-read` checks the spec before any brief exists · `/execute-tickets` consumes briefs · `/verified-review` runs the `Verify` command this brief names
