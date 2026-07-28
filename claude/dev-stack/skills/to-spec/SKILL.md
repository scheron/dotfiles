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

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better - the ideal number is one.

Check with the user that these seams match their expectations.

3. Write the spec using the template below, then publish it. **Where** depends on what `docs/agents/issue-tracker.md` configured — the spec is the same either way:

   - **A real issue tracker (GitHub, GitLab, Linear, …)** → publish as an issue and apply the `ready-for-agent` triage label; no further triage needed.
   - **Local markdown** → write it to `.scratch/<feature-slug>/spec.md`. The tickets from `/to-tickets` then land beside it under `.scratch/<feature-slug>/issues/`, and each references it by relative path.

   Either way the spec carries the **Global Constraints** that later briefs copy verbatim, and either way it contains no file paths or code snippets.


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

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details).
- Which modules will be tested, and the **prior art** for each (similar tests already in the codebase).
- **The test that proves the feature's point — not just that it wired up.** Name the acceptance/integration test at the highest meaningful seam that exercises what the feature actually delivers. A suite of fake/mock/fixture-backed unit tests proves the framework mounts and the calls are wired; it does not prove the feature works. If the value of the slice is an integration (transport, external API, real I/O, a user-visible flow), the spec must name a test that exercises that integration, not only its fakes.
- **End-to-end coverage, in whatever form the surface allows — when available.** e2e is not one thing: it can be a browser / computer-use flow, a `curl`/HTTP smoke against a running server, a real-client-against-mock-server integration over captured fixtures (fast and deterministic — prefer this where it fits), or a gated live smoke against a real endpoint. Choose the highest-fidelity form that stays affordable; state which and why. If no e2e is feasible, say so explicitly and name the manual acceptance that stands in — and make it a required step, not a hope.
- **Flake-prone tests get called out.** Any test that can fail for reasons outside the code (network, external service, timing) is marked flake-tolerant and gated out of the default suite (flag / nightly), so it never red-gates CI on infra — the runner retries it a bounded number of times and reports the flake rather than failing the build on a blip.

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
