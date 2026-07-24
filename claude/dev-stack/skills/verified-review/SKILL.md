---
name: verified-review
description: Review the changes since a fixed point along two axes — Standards (does the code follow this repo's documented standards?) and Spec (does it match what the ticket asked for?) — after running the Verify command itself. Runs both axes in parallel sub-agents and reports them side by side. Use to review a ticket, branch, PR, or work-in-progress changes.
---

# Verified Review

Review of the diff between `HEAD` and a fixed point, in two stages:

- **Stage 0 — cheap, early-exit.** The reviewer runs the brief's `Verify` command plus its `Sweep` directions (lint, type/compile checks) *itself*, in the worktree under review. Any red → return immediately; the axes never launch on broken code.
- **Stage 1 — the axes, in parallel.** Two sub-agents so they don't pollute each other's context, reported side by side without merging:
  - **Standards** — does the code conform to this repo's documented standards?
  - **Spec** — does the code faithfully implement the originating ticket / spec?
  - plus one informational check — `adr-candidate` (step 6).

## Process

### Stage 0 — early exit on broken code

Run by you — the reviewer — in the worktree under review. Nothing is dispatched before this stage is green.

#### 1. Pin the fixed point

Whatever the user said — a commit SHA, branch, tag, `main`, `HEAD~5`. If they didn't specify, ask.

Capture `git diff <fixed-point>...HEAD` (three-dot, against the merge-base) and `git log <fixed-point>..HEAD --oneline`.

Confirm the ref resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref should fail here, not inside two sub-agents.

#### 2. Run Verify + lint + type/compile checks — yourself

The commands are in the brief. Read `.scratch/brief-NN.md` in the worktree under review: the `Verify` block names the focused command, and the `Sweep` block names the repo's lint, type/compile, and other verification directions. Run `Verify` plus whatever `Sweep` lists. If there is no brief (a hand-driven review), ask the user for the commands. A repo that genuinely has only tests runs those alone; don't invent substitutes.

**Run them yourself. Now, before dispatching anything.**

| Outcome | Meaning |
|---|---|
| All green | Stage 0 passes. Continue to stage 1. |
| Any red | Return immediately. The failing command's output is the **only** finding — the Standards/Spec axes never launch on broken code. |
| No Verify command exists | **This is the finding.** Report it and stop — this is what `/improve-codebase-architecture` handles. Do not substitute a manual check. |

**Red here where the implementer's report claimed green is itself a finding — record it in the return, beside the command output.** A report contradicted on its most checkable claim is not load-bearing: every other claim in it is now suspect, and whoever fixes must treat the report as noise, not evidence.

### Stage 1 — the axes, in parallel

Reached only on a green stage 0.

#### 3. Identify the spec source

In this order:

1. Issue refs in commit messages (`#123`, `Closes #45`) — fetch per `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. The ticket or spec under `.scratch/`, `docs/`, or `specs/` matching the branch or feature.
4. Ask. If there genuinely isn't one, the Spec sub-agent skips and reports "no spec available".

The brief's **Global Constraints** block, if present, travels to both sub-agents verbatim.

#### 4. Identify the standards sources

Anything documenting how code should be written here — `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `CLAUDE.md`.

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

#### 5. Spawn both sub-agents in parallel

One message, two `Agent` calls, `general-purpose` for both.

**Standards prompt** — include the diff command and commit list; the standards-source files from step 4 **plus the smell baseline pasted in full** (the sub-agent has no other access to it); and:

> Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words.

**Spec prompt** — include the diff command and commit list, the spec/ticket contents, the Global Constraints verbatim, and:

> Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words.

Do not pre-judge findings for either sub-agent. If the prompt you're writing contains "don't flag", "at most Minor", or "the spec chose" — stop. Let the finding surface and adjudicate it yourself.

#### 6. The adr-candidate check

One conditional, applied by you while reading the diff and the axes' reports: **the change passes the ADR test owned by `/domain-modeling` → emit a finding of class `adr-candidate`**, carrying a one-sentence statement of the decision and its trade-off. The criteria live in `/domain-modeling`; this skill only points at them.

`adr-candidate` is **informational**: it never blocks the unit and is never dispatched for fixing. The orchestrator writes it up automatically — via `/domain-modeling`, before integrating — so it always lands on the default branch. The review only surfaces it.

#### 7. Aggregate

```
## Stage 0
<verify command> → green
<lint command> → green · <typecheck command> → green

## Standards
<report, verbatim or lightly cleaned>

## Spec
<report, verbatim or lightly cleaned>

## adr-candidate (informational — the orchestrator writes it up automatically)
<one sentence: the decision and its trade-off> — omit the section if none
```

Do **not** merge or rerank across axes. End with one line: findings per axis and the worst issue *within each axis*. No single winner across axes — that reranking is what the separation exists to prevent.

## Fix dispatch

When findings need fixing, dispatch **one fixer per findings list — never one fixer per finding**: the fixer sees the whole list, so related findings get one coherent fix instead of N colliding ones.

The dispatch carries one conditional line: **findings received → follow `/receiving-code-review`** — a finding is a hypothesis too; verify it against the code before implementing it.

## Definition of Done

All of it, or it isn't done:

- [ ] **Stage 0 green** — Verify (red before the change, green after) plus lint and type/compile checks, run by you
- [ ] **Spec axis** — matches the ticket
- [ ] **Standards axis** — matches the repo's conventions
- [ ] **No discrepancy** between the implementer's report and what you observed

An `adr-candidate` finding never blocks — the orchestrator writes it up automatically, it is not fixed here.

### On a clean pass — record it

When stage 0 and both axes pass with no blocking findings (an `adr-candidate` on its own is not blocking), mark this exact working state as reviewed so the `review-guard` Stop hook knows the change was reviewed and won't nag at turn end:

```
"${DEV_STACK_ROOT:-$HOME/.dotfiles/claude/dev-stack}/hooks/review-mark.sh" || true
```

Best-effort — it fingerprints `HEAD` + the working diff, so any later edit re-arms the gate and needs a fresh review. If findings remain, do **not** mark: address them (or hand them back) and re-review first.

## Why the reviewer runs it

The tempting optimisation is to trust the implementer's report — it already carries test evidence, so why re-run? Because that buys the saving with the one thing the review exists to establish. **An implementer's report is a hypothesis, not evidence.** A report contradicted on its most checkable claim — a green it reported that comes back red under stage 0 — is not load-bearing on any of its other claims either.

Running stage 0 costs seconds. Discovering at merge that the report was optimistic costs the branch.

## Why two axes

A change can pass one and fail the other:

- Follows every standard, implements the wrong thing → **Standards pass, Spec fail.**
- Does exactly what the ticket asked, breaks the repo's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one from masking the other. Stage 0 is not a third axis — it's the gate both axes stand on.

**Related:** `/brief` names the `Verify` command and the `Sweep` directions · `/to-implement` calls this after the unit · `/domain-modeling` owns the ADR test behind `adr-candidate` · `/receiving-code-review` governs the fixer's handling of findings · `/improve-codebase-architecture` receives the "no Verify command" finding
