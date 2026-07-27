---
name: to-implement
description: "The execution engine — runs ONE unit (an approved chat plan, a raw task, a single-slice spec, or one ticket) through its full lifecycle in an isolated worktree: brief, verify-brief, build, sweep, review, ADR, integrate. The body of /tier-1, and directly invocable to skip the tiers; /tier-2 feeds it one ticket per fresh chat. Use to build an approved plan, a task, or a ticket."
---

<STOP-GATE>
Present what is about to run and wait for the user's explicit go before creating any worktree or dispatching any seat:

- the **unit** — the plan, task, spec, or ticket, in one line;
- the **base commit** the worktree will branch from, named as a commit the user can see.

Nothing is branched, dispatched, or integrated until the go is given.

**Autopilot exception.** If `DEV_STACK_AUTOPILOT=1` is set in the environment (check with `printenv DEV_STACK_AUTOPILOT`), this gate is already satisfied — the ticket was approved at `/to-tickets` and the batch at `/autopilot` — so proceed without stopping. The base is the integration branch's tip; landing is `/finish-branch` Option 1 to that branch with no menu; any state that would normally escalate to the user instead halts the run for resume. The `/autopilot` skill owns the exact base/branch/sentinel contract.
</STOP-GATE>

# To Implement

One unit, start to finish. You are the **orchestrator** — you gate, dispatch, and integrate; you never edit code yourself. Every seat below is a subagent dispatched by **agent name**, never an inline role prompt.

## Input — one unit

Whatever you are handed is built as a single unit. The engine does not decompose.

| Input | What it is |
|---|---|
| **a plan** | the approved inline plan from chat — the body of `/tier-1` |
| **a task** | a raw task handed straight here, skipping `/route-me` and the tiers |
| **a spec** | a single-slice spec (`/tier-2` can output a spec with no tickets) |
| **a ticket** | one ticket |

A feature split into several tickets is run **one ticket per fresh chat** — the loop over tickets is the user's, not the engine's. A dependent ticket already sees its blockers' code, because they are merged into the branch this worktree cuts from: the contract is the code read from the tree, never paper from another ticket.

## The lifecycle

### 1. Isolate

Cut the worktree from the tip of the current branch — `/using-git-worktrees`. **Record the base commit**: it is the review's fixed point, and it is never `HEAD~1` (which drops every commit but the last of a multi-commit unit).

### 2. brief-writer → the brief

Dispatch the **brief-writer** into the worktree. It explores the code itself and writes `.scratch/brief-NN.md`, returning only the path — or BLOCKED. You never read its exploration; only the path travels on.

### 3. Verify the brief — yourself

Before dispatching the implementer, read the brief and confirm it is load-bearing: the blocks present (Files, Interfaces, Binding Decisions, Plan, Execution Boundary, Verify, Sweep), the `Verify` command named and shown already-run, Global Constraints copied verbatim, no placeholders. Check the `Plan` task by task: is every task an independently testable/reviewable deliverable with a focused proof, and does every action name real values plus a concrete edit or command? A task that sends the implementer back into the code to find a location, name, or approach is hollow. Then test closure: could a competent implementer make a different locally-valid semantic choice, broaden into an adjacent surface, or cross an escalation trigger without the brief explicitly stopping it? If so, `Binding Decisions` or `Execution Boundary` is hollow. Send a hollow brief back to the brief-writer; never dispatch the implementer against one.

### 4. implementer → the build

Dispatch the **implementer** with the brief's path. It reads the brief first and works `/tdd` at the brief's seams. Handle its status:

- **DONE** → the sweep.
- **DONE_WITH_CONCERNS** → read the concerns first; resolve correctness or scope before the sweep, carry observations to the review.
- **NEEDS_CONTEXT** → supply what was missing, re-dispatch — then fix the brief so the gap doesn't recur.
- **BLOCKED** → triage first — most "too hard" is something else in disguise: a gap the brief should have closed → treat as NEEDS_CONTEXT; an open decision with several valid answers → the user's call, never the seat's; unit too large → the slice was wrong, split it; the unit itself wrong → escalate to the user. Only when none of those fit is the seat genuinely too small: propose re-dispatching the **same implementer with a stronger model** (the Agent tool's model override) and wait for the user's go — escalation is spend, and spend sits behind a gate. Never force an unchanged retry.

### 5. The sweep — run by you

Dispatch the **test-runner** in the worktree, handing it the brief's **Sweep** directions as the exact commands to run — the implementer never runs the full sweep. It returns a summary: counts, failing names, one line per failure, never stacktraces.

- **GREEN** → review.
- **RED** → send the summary back to the **same implementer** — its context is alive, it pays only for the summary. It fixes in place and re-reports; you re-sweep.
- **Three red rounds in a row → BLOCKED.** Escalate to the user, with the same stronger-model re-dispatch on the menu. Never grind an unwinnable loop.

### 6. /verified-review — the review receipt

Raise `/verified-review` with the fixed point set to **the base commit you recorded in step 1**. It runs three gates, each standing on the one before: stage 0 (Verify, lint, type/compile checks — itself), then a **real run** that drives the actual runtime and observes it working, then the Standards and Spec axes in parallel. A broken build or a dead runtime returns before the axes ever launch — tests can be green on fakes while the real path is broken by config, environment, wiring, or an external contract no test covers.

- Findings → dispatch **one fixer per findings list** (never one per finding), carrying the line: *findings received → follow `/receiving-code-review`*. Re-review after — scoped, per `/verified-review`'s re-review: stage 0 re-runs, the real run only if the fix touched the driven flow, one re-reviewer verdicts each finding against the fix diff. The system-wide pass happens once; rounds converge on the findings.
- A finding that conflicts with what the unit mandates is the user's call: present it beside the unit text and ask which governs.
- **Green on every axis — with the runtime observed working — closes the review.** The implementer's report is never a close condition; a green sweep is a working signal, not evidence that the thing actually runs.

### 7. adr-candidate → write it

If the review surfaced an `adr-candidate`, write the ADR **now, automatically, before integrating** — its own commit on the branch, so it merges with the work and cannot be lost. Use `/domain-modeling`'s ADR format; the candidate already carries the decision and its trade-off, so no question is asked — not losing it outweighs the gate. (`/finish-branch`'s harvest stays the final catch for anything that slipped.)

### 8. Integrate

Hand off to `/finish-branch`. It carries its own STOP-gate and the merge / PR / keep / discard menu, and asks what to do with the worktree.

## Red flags

**Never:**
- Close a unit without `/verified-review` green on every axis
- Close a unit on green tests alone — `/verified-review` drives the real runtime as a gate wherever there's a flow to observe; fake/mock/fixture-backed green is a working signal, not proof the thing runs. Say "done" only after you've watched it work.
- Use `HEAD~1` as the review fixed point — it drops all but the last commit of a multi-commit unit
- Dispatch the implementer against a brief you haven't verified
- Merge or integrate without the user's word
- Dispatch a seat by inline role prompt instead of by agent name
- Paste a seat's full output into the next dispatch instead of its path — dispatches carry paths, never contents
- Let the implementer's self-review replace `/verified-review` — both are needed
- Tell a reviewer what not to flag, or pre-rate a finding's severity
- Edit code yourself — you orchestrate; the seats build
- Work on the default branch — the unit is always isolated

**Related:** `/tier-1` drives this for one unit · `/tier-2` feeds it tickets one at a time · `/brief` is the brief-writer's protocol · `/verified-review` reviews the diff and drives the real runtime · `/finish-branch` integrates · `/using-git-worktrees` isolates the worktree
