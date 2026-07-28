---
name: to-spec
description: Turn the current conversation into a spec and publish it to the project issue tracker — no interview, just synthesis of what you've already discussed.
---

<STOP-GATE>
The conversation has settled; I'll synthesize it into a spec at <destination> — go?

**Satisfied when** `/tier-2` reached you: the grill it just ran was aimed at this spec, so asking whether to write it buys nothing. Synthesize, and gate on the *content* instead — the seams question in step 2 and the spec approval in step 4 are the real stops. Typed directly, the gate is live.
</STOP-GATE>

This skill takes the current conversation context and codebase understanding and produces a spec (you may know this document as a PRD). Do NOT interview the user — just synthesize what you already know.

The tracker configuration lives in `docs/agents/issue-tracker.md`; if it's missing, ask the user once where specs and tickets live and record the answer there (the tier-2 preflight normally has done this already).

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

2. **Sketch the seams — at two levels.** Existing seams beat new ones; use the highest seam you can, and the fewer across the codebase the better. But the engine tests at two heights, so name both:

   - **Task seams** — where each horizontal layer of a slice proves itself. Focused, fast, allowed to fake external dependencies. These become the per-task `Proof` commands.
   - **The slice seam** — where a whole vertical slice proves it actually works. Real dependencies, observed behaviour. This becomes the slice acceptance the review drives.

   A fast fake at the task seam and a real run at the slice seam is the normal shape; neither substitutes for the other. Conflating them is how a mandated e2e quietly becomes a handful of unit tests over mocks.

   **Check with the user that both sets of seams match their expectations.** This is a gate — the seams decide what "done" can even mean.

3. **Present the design in sections, and take approval as you go.** Scale each section to its complexity — a few sentences when it's straightforward, a couple of hundred words when it's nuanced — and ask after each whether it reads right so far. Drift caught in section three costs a sentence; the same drift caught on the finished spec costs a rewrite. This runs inside the conversation, so it adds no stop of its own.

4. Write the spec using the template below, then **self-review it before showing it** (see below), then publish. **Where** depends on what `docs/agents/issue-tracker.md` configured — the spec is the same either way:

   - **A real issue tracker (GitHub, GitLab, Linear, …)** → publish as an issue and apply the `ready-for-agent` triage label; no further triage needed.
   - **Local markdown** → write it to `.scratch/<feature-slug>/spec.md`. The tickets from `/to-tickets` then land beside it under `.scratch/<feature-slug>/issues/`, and each references it by relative path.

   Either way the spec carries the **Global Constraints** that later briefs copy verbatim, and either way it contains no file paths or code snippets.

## Self-review — before anyone else reads it

Four passes over what you just wrote, with fresh eyes. Fix inline; no second review, no dispatch.

1. **Placeholders** — any `TBD`, `TODO`, unfinished section, or requirement vague enough to build the wrong thing from.
2. **Internal consistency** — do two sections contradict each other? Does the stated architecture match the feature descriptions?
3. **Scope** — is this one feature, or several independent subsystems wearing one spec? Several means it needs decomposing, not writing.
4. **Ambiguity** — could any requirement be read two ways? **If so, pick one and make it explicit.** Do not leave the choice for a reader to make silently.

This is the cheap rung of a two-rung ladder: it catches what an author can see, and `/cold-read` afterwards catches what an author structurally cannot. Skipping it just moves the same findings onto the expensive rung.


<spec-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Global Constraints

The project-wide requirements every ticket in this spec implicitly includes — version floors, dependency limits, naming and copy rules, platform requirements, stated relationships between components ("same layout as X", "matches Y"). One line each, exact values, no prose around them.

**Keep this block short, and pay for every line deliberately.** It is the one section that travels verbatim and repeatedly: each brief copies it, and each of a slice's task reviewers receives it again. A line that earns its place binds behaviour; a line of background costs its length multiplied by every task in the feature, and dilutes the lines that matter.

## Testing Decisions

A list of testing decisions that were made, **split by the two heights the engine tests at** — a brief-writer that cannot tell which mandate belongs where will guess, and it guesses downward.

### Task level — proving a layer

Focused, fast, deterministic, allowed to fake external dependencies. One per horizontal layer a slice cuts through; these become the per-task `Proof` commands.

- Which modules will be tested, and the **prior art** for each (similar tests already in the codebase).
- A description of what makes a good test (only test external behavior, not implementation details).

### Slice level — proving the feature

Real dependencies, observed behaviour. One per vertical slice; this becomes the slice acceptance the review drives, and it is the mandate that gets quietly downgraded if it isn't named here.

- **The test that proves the feature's point — not just that it wired up.** Name the acceptance/integration test at the highest meaningful seam that exercises what the feature actually delivers. A suite of fake/mock/fixture-backed unit tests proves the framework mounts and the calls are wired; it does not prove the feature works. If the value of the slice is an integration (transport, external API, real I/O, a user-visible flow), the spec must name a test that exercises that integration, not only its fakes.
- **End-to-end coverage, in whatever form the surface allows — when available.** e2e is not one thing: it can be a browser / computer-use flow, a `curl`/HTTP smoke against a running server, a real-client-against-mock-server integration over captured fixtures (fast and deterministic — prefer this where it fits), or a gated live smoke against a real endpoint. Choose the highest-fidelity form that stays affordable; state which and why. If no e2e is feasible, say so explicitly and name the manual acceptance that stands in — and make it a required step, not a hope.
- **Flake-prone tests get called out.** Any test that can fail for reasons outside the code (network, external service, timing) is marked flake-tolerant and gated out of the default suite (flag / nightly), so it never red-gates CI on infra — the runner retries it a bounded number of times and reports the flake rather than failing the build on a blip.

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
