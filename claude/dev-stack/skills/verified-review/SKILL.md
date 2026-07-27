---
name: verified-review
description: Review the changes since a fixed point: run the Verify command and drive the real runtime yourself, then judge two axes — Standards (does the code follow this repo's documented standards?) and Spec (does it match what the ticket asked for?). A broken build or a dead runtime early-exits before the parallel axes launch. Use to review a ticket, branch, PR, or work-in-progress changes.
---

# Verified Review

Review of the diff between `HEAD` and a fixed point, in three stages — each a gate the next stands on:

- **Stage 0 — build, cheap early-exit.** The reviewer runs the brief's `Verify` command plus its `Sweep` directions (lint, type/compile checks) *itself*, in the worktree under review. Any red → return immediately; nothing downstream launches on broken code.
- **Stage ½ — real run, the runtime gate.** Tests are only as honest as what they touch: a unit can be green on fakes while the real path is dead from config, wiring, environment, or an external contract no test covers. A dispatched runner drives the affected flow and returns a verdict; a `HARD-FAIL` early-exits like a red stage 0 — the axes never review a unit that doesn't run.
- **Stage 1 — the axes, in parallel.** Two sub-agents so they don't pollute each other's context, reported side by side without merging:
  - **Standards** — does the code conform to this repo's documented standards?
  - **Spec** — does the code faithfully implement the originating ticket / spec, including the tests its Testing Decisions mandate?
  - plus one informational check — `adr-candidate` (step 7).

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

**Red is read, not re-run.** You cannot see Verify fail on the finished tree — the red lives in the brief: the brief-writer ran the command at pickup, before the unit was built, and pasted its output. Confirm that paste shows red. A green at pickup means the command cannot fail — that is a finding (the command is no Verify), except a wide refactor, where `Verify: build` is legitimately green.

| Outcome | Meaning |
|---|---|
| All green | Stage 0 passes. Continue to stage 1. |
| Any red | Return immediately. The failing command's output is the **only** finding — the Standards/Spec axes never launch on broken code. |
| No Verify command exists | **This is the finding.** Report it and stop — this is what `/improve-codebase-architecture` handles. Do not substitute a manual check. |

**Red here where the implementer's report claimed green is itself a finding — record it in the return, beside the command output.** A report contradicted on its most checkable claim is not load-bearing: every other claim in it is now suspect, and whoever fixes must treat the report as noise, not evidence.

### Stage ½ — the runtime gate

Reached only on a green stage 0. The build passing is not the thing running.

#### 3. Real run — drive it, don't trust green

Dispatch a **runner** (`general-purpose`) into the worktree to drive the affected flow end-to-end and **observe the behaviour** — not a test of it. The flow is already named; the runner reads it, never invents it:

- the brief's **`Verify`** command — the focused entry the brief-writer ran at pickup;
- the ticket / spec's **manual-acceptance or "done-by-observation" script**, if it names one — that script *is* this gate; run it, don't paraphrase;
- failing an explicit script, the **affected flow the diff implies** — the endpoint, screen, command, or job the change touches.

The runner drives the real dependencies the flow reaches; the observation travels back, not the logs:

| Verdict | Meaning | Effect |
|---|---|---|
| **PASS** | Driven, observed doing what the unit promised | Continue to stage 1 |
| **HARD-FAIL** | Won't build, won't launch, crashes on entry — the runtime is dead | **Return immediately.** The observation is the only finding; the axes never launch. |
| **SOFT-FAIL** | Runs, but the observed behaviour is wrong | **Carry as a finding** into stage 1's aggregate — the axes still run, so one hand-back carries everything |
| **NOTHING-TO-DRIVE** | No runtime surface — docs, config-free fixtures, pure test code | Continue, recorded with the reason. Any unit touching product source has a surface; find it before claiming the exemption. |

### Stage 1 — the axes, in parallel

Reached only on a green stage 0 and a stage ½ that did not hard-fail.

#### 4. Identify the spec source

In this order:

1. Issue refs in commit messages (`#123`, `Closes #45`) — fetch per `docs/agents/issue-tracker.md`.
2. A path the user passed as an argument.
3. The ticket or spec under `.scratch/`, `docs/`, or `specs/` matching the branch or feature.
4. Ask. If there genuinely isn't one, the Spec sub-agent skips and reports "no spec available".

The brief's **Global Constraints** block, if present, travels to both sub-agents verbatim.

#### 5. Identify the standards sources

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

#### 6. Spawn both sub-agents in parallel

One message, two `Agent` calls, `general-purpose` for both.

**Standards prompt** — include the diff command and commit list; the standards-source files from step 4 **plus the smell baseline pasted in full** (the sub-agent has no other access to it); and:

> Report — per file/hunk where relevant — (a) every place the diff violates a documented standard: cite the standard (file + rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls — documented-standard breaches can be hard, baseline smells are always judgement calls, and a documented repo standard overrides the baseline. Skip anything tooling enforces. Under 400 words.

**Spec prompt** — include the diff command and commit list, the spec/ticket contents (**including its Testing Decisions**), the Global Constraints verbatim, and:

> Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong; (d) **tests the spec's Testing Decisions mandate that are absent, downgraded, or quietly swapped for a weaker form** — e.g. a mandated e2e / acceptance / integration test that isn't present, or one replaced by a unit test that only exercises fakes and mocks. Judge (d) against what the Testing Decisions actually name, not your own taste — the mandate is the yardstick. Quote the spec line for each finding. Under 400 words.

Do not pre-judge findings for either sub-agent. If the prompt you're writing contains "don't flag", "at most Minor", or "the spec chose" — stop. Let the finding surface and adjudicate it yourself.

#### 7. The adr-candidate check

One conditional, applied by you while reading the diff and the axes' reports: **the change passes the ADR test owned by `/domain-modeling` → emit a finding of class `adr-candidate`**, carrying a one-sentence statement of the decision and its trade-off. The criteria live in `/domain-modeling`; this skill only points at them.

`adr-candidate` is **informational**: it never blocks the unit and is never dispatched for fixing. The orchestrator writes it up automatically — via `/domain-modeling`, before integrating — its own commit on the unit's branch, so it merges with the work. The review only surfaces it.

#### 8. Aggregate

```
## Stage 0
<verify command> → green
<lint command> → green · <typecheck command> → green

## Real run
<verdict> — <one line: what was driven, and what was observed>

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

- [ ] **Stage 0 green** — Verify green now, run by you, with red-at-pickup on file in the brief — plus lint and type/compile checks
- [ ] **Real run** — the affected flow driven and observed working (or `NOTHING-TO-DRIVE` recorded with its reason); no `HARD-FAIL`, no unresolved `SOFT-FAIL`
- [ ] **Spec axis** — matches the ticket, including the tests its Testing Decisions mandate (a mandated e2e/acceptance test absent or downgraded to fakes is a Spec finding)
- [ ] **Standards axis** — matches the repo's conventions
- [ ] **No discrepancy** between the implementer's report and what you observed

An `adr-candidate` finding never blocks — the orchestrator writes it up automatically, it is not fixed here.

### On a clean pass — record it

When stage 0 and both axes pass with no blocking findings (an `adr-candidate` on its own is not blocking), mark this exact working state as reviewed so the `review-guard` Stop hook knows the change was reviewed and won't nag at turn end:

```
"${DEV_STACK_ROOT:-$(dirname "$(readlink "$HOME/.claude/skills/verified-review")")/..}/hooks/review-mark.sh" || true
```

Best-effort — it fingerprints `HEAD` + the working diff, so any later edit re-arms the gate and needs a fresh review. If findings remain, do **not** mark: address them (or hand them back) and re-review first.

## Why the reviewer runs it

The tempting optimisation is to trust the implementer's report — it already carries test evidence, so why re-run? Because that buys the saving with the one thing the review exists to establish. **An implementer's report is a hypothesis, not evidence.** A report contradicted on its most checkable claim — a green it reported that comes back red under stage 0 — is not load-bearing on any of its other claims either.

Running stage 0 costs seconds. Discovering at merge that the report was optimistic costs the branch.

## Why two axes

A change can pass one and fail the other:

- Follows every standard, implements the wrong thing → **Standards pass, Spec fail.**
- Does exactly what the ticket asked, breaks the repo's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one from masking the other. Stages 0 and ½ are not axes — they're the gates the axes stand on.

**Related:** `/brief` names the `Verify` command and the `Sweep` directions · `/to-implement` raises this as the unit's review gate · `/domain-modeling` owns the ADR test behind `adr-candidate` · `/receiving-code-review` governs the fixer's handling of findings · `/improve-codebase-architecture` receives the "no Verify command" finding
