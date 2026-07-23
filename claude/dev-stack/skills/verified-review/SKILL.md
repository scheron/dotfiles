---
name: verified-review
description: Review the changes since a fixed point along two axes — Standards (does the code follow this repo's documented standards?) and Spec (does it match what the ticket asked for?) — after running the Verify command itself. Runs both axes in parallel sub-agents and reports them side by side. Use to review a ticket, branch, PR, or work-in-progress changes.
---

# Verified Review

Three checks on the diff between `HEAD` and a fixed point:

- **Verify** — does the named command go green? *The reviewer runs it.* Binary.
- **Standards** — does the code conform to this repo's documented standards?
- **Spec** — does the code faithfully implement the originating ticket / spec?

Verify runs first and is a gate. The two axes then run as **parallel sub-agents** so they don't pollute each other's context, and are reported side by side without merging.

> Fork of Matt Pocock's `code-review` (MIT). One substantive change: the reviewer executes the verification command instead of reading the implementer's claim that it passed. See *Why the reviewer runs it*.

## Process

### 1. Pin the fixed point

Whatever the user said — a commit SHA, branch, tag, `main`, `HEAD~5`. If they didn't specify, ask.

Capture `git diff <fixed-point>...HEAD` (three-dot, against the merge-base) and `git log <fixed-point>..HEAD --oneline`.

Confirm the ref resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref should fail here, not inside two sub-agents.

### 2. Run Verify — the gate

Find the command, in this order:

1. The `Verify` block of the ticket's brief (`.scratch/<feature>/brief-NN.md`).
2. `AGENTS.md` → `## Build & run`.
3. Ask the user.

**Run it yourself. Now, before dispatching anything.**

| Outcome | Meaning |
|---|---|
| Green | Gate passes. Continue to step 3. |
| Red | Stop. Report the failure. Do not spend two sub-agents reviewing code that doesn't work. |
| No such command exists | **This is the finding.** Report it and stop — this is what `/improve-codebase-architecture` handles. Do not substitute a manual check. |

**If the implementer's report said this command passed and it goes red for you, that discrepancy is itself a finding** — report it above the axes. It means the report is not load-bearing, and every other claim in it is now suspect.

### 3. Identify the spec source

In this order:

1. Issue refs in commit messages (`#123`, `Closes #45`) — fetch per `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. The ticket or spec under `.scratch/`, `docs/`, or `specs/` matching the branch or feature.
4. Ask. If there genuinely isn't one, the Spec sub-agent skips and reports "no spec available".

The brief's **Global Constraints** block, if present, travels to both sub-agents verbatim.

### 4. Identify the standards sources

Anything documenting how code should be written here — `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md`.

On top of that, the Standards axis always carries the **smell baseline** below — Fowler's code smells (*Refactoring*, ch.3), which apply even when a repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented standard always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. Skip anything tooling already enforces.

Each reads *what it is* → *how to fix*:

- **Mysterious Name** — a name that doesn't reveal what it does or holds. → rename; if no honest name comes, the design is murky.
- **Duplicated Code** — the same logic shape in more than one hunk or file. → extract, call from both.
- **Feature Envy** — a method reaching into another object's data more than its own. → move it onto the data it envies.
- **Data Clumps** — the same few fields keep travelling together. → bundle them into one type.
- **Primitive Obsession** — a primitive standing in for a domain concept. → give the concept its own small type.
- **Repeated Switches** — the same cascade on the same type recurs. → polymorphism, or one shared map.
- **Shotgun Surgery** — one logical change forces scattered edits. → gather what changes together.
- **Divergent Change** — one module edited for several unrelated reasons. → split by reason.
- **Speculative Generality** — abstraction for needs the spec doesn't have. → delete it.
- **Message Chains** — long `a.b().c().d()` the caller shouldn't depend on. → hide the walk.
- **Middle Man** — a unit that mostly delegates onward. → cut it.
- **Refused Bequest** — a subclass ignoring most of what it inherits. → composition.

### 5. Spawn both sub-agents in parallel

One message, two `Agent` calls, `general-purpose` for both.

**Standards prompt** — include the diff command and commit list; the standards-source files from step 4 **plus the smell baseline pasted in full** (the sub-agent has no other access to it); and:

> Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words.

**Spec prompt** — include the diff command and commit list, the spec/ticket contents, the Global Constraints verbatim, and:

> Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words.

Do not pre-judge findings for either sub-agent. If the prompt you're writing contains "don't flag", "at most Minor", or "the spec chose" — stop. Let the finding surface and adjudicate it yourself.

### 6. Aggregate

```
## Verify
<command> → green | red
[report discrepancy with the implementer's report, if any]

## Standards
<report, verbatim or lightly cleaned>

## Spec
<report, verbatim or lightly cleaned>
```

Do **not** merge or rerank across axes. End with one line: findings per axis and the worst issue *within each axis*. No single winner across axes — that reranking is what the separation exists to prevent.

## Definition of Done

All three, or it isn't done:

- [ ] **Verify green** — red before the change, green after, run by you
- [ ] **Spec axis** — matches the ticket
- [ ] **Standards axis** — matches the repo's conventions

Plus: no discrepancy between the implementer's report and what you observed.

### On a clean pass — record it

When all three pass with no blocking findings, mark this exact working state as reviewed so the `review-guard` Stop hook knows the change was reviewed and won't nag at turn end:

```
"${CLAUDE_PLUGIN_ROOT:-$HOME/.dotfiles/claude/dev-stack}/hooks/review-mark.sh" || true
```

Best-effort — it fingerprints `HEAD` + the working diff, so any later edit re-arms the gate and needs a fresh review. If findings remain, do **not** mark: address them (or hand them back) and re-review first.

## Why the reviewer runs it

Upstream `subagent-driven-development` says the opposite:

> *"Do not ask a reviewer to re-run tests the implementer already ran on the same code — the implementer's report carries the test evidence."*
> — superpowers, `subagent-driven-development/SKILL.md:166`

That is a token optimisation, and it buys the saving with the one thing the review exists to establish. **An implementer's report is a hypothesis, not evidence.** The contradiction is already inside superpowers: `verification-before-completion` names "trusting agent success reports" a red flag, and SDD is built on exactly that trust.

Running one command costs seconds. Discovering at merge that the report was optimistic costs the branch.

## Why two axes

A change can pass one and fail the other:

- Follows every standard, implements the wrong thing → **Standards pass, Spec fail.**
- Does exactly what the ticket asked, breaks the repo's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one from masking the other. Verify is not a third axis — it's the gate both axes stand on.

**Related:** `/brief` names the `Verify` command · `/execute-tickets` calls this after every ticket · `/improve-codebase-architecture` receives the "no Verify command" finding
