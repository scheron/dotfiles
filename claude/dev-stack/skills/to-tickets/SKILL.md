---
name: to-tickets
description: Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker.
---

<STOP-GATE>
The spec is ready; I'll cut it into tracer-bullet tickets with blocking edges — go?

**Satisfied when** `/tier-2` reached you: the spec was just approved at its own gate, and cutting it is the next phase. Cut, and gate on the *breakdown* instead — step 4 is the real stop. Typed directly, the gate is live.
</STOP-GATE>

# To Tickets

Break a plan, spec, or conversation into a set of **tickets** — tracer-bullet vertical slices, each declaring the tickets that **block** it.

The tracker configuration lives in `docs/agents/issue-tracker.md`; if it's missing, ask the user once where specs and tickets live and record the answer there (the tier-2 preflight normally has done this already).

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path, an issue number or URL) as an argument, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Ticket titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer it touches (schema, API, transport, UI, tests) — vertical, NOT a horizontal slice of one layer
- **Name the observable behaviour and how it will be observed** — the command, the screen, the request, the build. If you cannot name it, this is not a slice: split differently or merge it into the one that makes it observable
- Any prefactoring goes first, in its own ticket

</vertical-slice-rules>

The naming rule is the whole test, and it is load-bearing downstream twice over. A slice with no observable behaviour gives the review's runtime gate nothing to drive, so that gate silently voids and the ticket closes on green tests alone. And a slice that is really one layer gives the brief no layers to cut, so it arrives at the implementer as a monolith — the failure this whole shape exists to prevent.

Slice size is bounded by **one observable behaviour**, not by a context window: the engine fans the work out across fresh subagent windows, so window size no longer bounds a ticket.

Give each ticket its **blocking edges** — the other tickets that must complete before it can start. A ticket with no blockers can start immediately.

<wide-refactor-exception>

A **wide refactor** — one mechanical change whose blast radius fans across the codebase (rename a column, retype a shared symbol) — cannot land green as a vertical slice: a single edit breaks thousands of call sites. Sequence it as **expand–contract** instead:

1. **Expand** — add the new form beside the old. One ticket, nothing breaks.
2. **Migrate** — call sites in batches sized by blast radius (per package, per directory). One ticket per batch, each blocked by the expand. CI stays green batch to batch because the old form still exists.
3. **Contract** — delete the old form once no caller remains. One ticket, blocked by every migrate batch.

If even the batches cannot stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify ticket — green is promised only there.

</wide-refactor-exception>

### 4. Quiz the user — the breakdown gate

Present the proposed breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **Observable behaviour**: what works end to end once it lands, and how you'd observe it

Then ask the question that decides the breakdown:

> **Does each of these run unattended?**

That is the bar, and it is checkable rather than a matter of taste: `/autopilot` exists to run a batch of cut tickets with nobody watching, halting on the first red. A ticket you would not hand it is a ticket that is not finished being written — the granularity, the observable behaviour, and the blocking edges are all downstream of that one question.

Follow with:

- Are the blocking edges correct — does each ticket only depend on tickets that genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 5. Publish the tickets to the configured tracker

Publish the approved tickets. **How** depends on what `docs/agents/issue-tracker.md` configures — the tickets are the same either way, only the shape of the blocking edges changes:

- **Local files** → write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first). Each file's "Blocked by" lists the numbers/titles it depends on. Use the per-ticket file template below — one ticket per file, never a single combined file.
- **A real issue tracker (GitHub, Linear, …)** → publish one issue per ticket in dependency order (blockers first) so each ticket's blocking edges can reference real identifiers. Use the platform's native blocking / sub-issue relationship where it has one; otherwise set each ticket's "Blocked by" to the blocking issues. Apply the `ready-for-agent` triage label unless instructed otherwise — the tickets are agent-grabbable by construction.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

Do NOT close or modify any parent issue.

Every ticket carries the same four fields, whichever form it lands in. Each one exists because the brief-writer cannot do its job without it — this is the ticket's whole contract with everything downstream.

<local-ticket-template>

# <NN> — <Ticket title>

**Observable behaviour:** what works end to end once this lands, from the user's perspective — and **how to observe it**: the exact command, screen, request, or build. Not a layer-by-layer implementation list.

**Layers crossed:** the layers this slice cuts through, by their domain names — `event schema · WS transport · client store · panel component`. Names only, never paths: this is what the brief cuts the slice along, and it is the difference between horizontal tasks and a monolith.

**Blocked by:** the numbers/titles of the tickets that gate this one, or "None — can start immediately".

**Acceptance:**

- [ ] Criterion 1
- [ ] Criterion 2

**Slice acceptance:** the test the spec's Testing Decisions mandate for this slice, named with its command. Omit only when there is no spec — a Tier 1 slice carries its observable behaviour and nothing more.

**Status:** ready-for-agent

</local-ticket-template>

**Write acceptance criteria as end-to-end behaviour, never per layer.** A criterion list shaped like the layers ("transport emits the event", "store receives it") is the one mistake that survives every gate below: the brief will cut its tasks along your criteria, and each task will then verify green while the slice as a whole does nothing. The layers belong in `Layers crossed`; the criteria describe what the user gets.

<issue-template>

## Parent

A reference to the parent issue on the tracker (if the source was an existing issue, otherwise omit this section).

## Observable behaviour

What works end to end once this lands, from the user's perspective — and how to observe it: the exact command, screen, request, or build. Not layer-by-layer implementation.

## Layers crossed

The layers this slice cuts through, by their domain names. Names only, never paths.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Slice acceptance

The test the spec's Testing Decisions mandate for this slice, named with its command.

## Blocked by

- A reference to each blocking ticket, or "None — can start immediately".

</issue-template>

**No file paths, no signatures, no code snippets, in either form.** Two reasons, and the second is the one people forget: they go stale fast, *and* naming them here takes from the brief the one job only the brief can do — reading the tree fresh at pickup, after the blockers have merged and moved things. A path in a ticket is an anchor the brief-writer may trust instead of looking.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

Work the frontier one ticket at a time, clearing context between tickets.

**Do not write briefs here.** The technical bottom of a ticket — exact paths, signatures, the ordered build steps, the `Verify` command — is generated by `/brief` **at the moment the ticket is picked up**, never at planning time: a brief written now for a ticket behind six blockers describes a codebase those blockers are about to change.

Then run the tickets through the engine **one per fresh chat**, in dependency order: `/to-implement <ticket>`. The engine isolates, briefs, builds, reviews, and integrates each unit; a fresh context per ticket keeps every brief sharp. The loop over tickets is yours — the engine builds one unit at a time, it does not orchestrate the set. Hand the set to `/autopilot` to run that loop unattended, which is the bar step 4 held each ticket to.

