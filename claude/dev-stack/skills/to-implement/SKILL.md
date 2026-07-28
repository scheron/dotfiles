---
name: to-implement
description: "The execution engine — runs ONE unit (an approved chat plan, a raw task, a single-slice spec, or one ticket) through its full lifecycle in an isolated worktree: ready-check, brief, verify-brief, waves of implementer+reviewer pairs, slice review, ADR, integrate. The body of /tier-1, and directly invocable to skip the tiers; /tier-2 feeds it one ticket per fresh chat. Use to build an approved plan, a task, or a ticket."
---

<STOP-GATE>
Present what is about to run and wait for the user's explicit go before creating any worktree or dispatching any seat:

- the **unit** — the plan, task, spec, or ticket, in one line;
- the **base commit** the worktree will branch from, named as a commit the user can see.

Nothing is branched, dispatched, or integrated until the go is given.

**Satisfied when** a driver reached you and its gate already carried both facts:

- `/tier-1` — its G3 gate presented the plan **and the base commit** and took the go;
- `/tier-2` — the ticket was approved at `/to-tickets`; present the base commit in one line as you branch, no stop.

Typed directly with a raw task, the gate is live.

**Autopilot exception.** If `DEV_STACK_AUTOPILOT=1` is set in the environment (check with `printenv DEV_STACK_AUTOPILOT`), this gate is already satisfied — the ticket was approved at `/to-tickets` and the batch at `/autopilot`. The base is the integration branch's tip; landing is `/finish-branch` Option 1 to that branch with no menu; any state that would normally escalate to the user instead halts the run for resume.

Waves run unchanged — tickets are sequential, tasks inside one are not. **One rule is stricter:** you may not park a finding at a cap. Parking is a judgement the user delegates by being present, and unattended it is a bar quietly lowered — so at any cap, and on any finding that conflicts with the brief, halt without writing the sentinel. The `/autopilot` skill owns the exact base/branch/sentinel contract.
</STOP-GATE>

# To Implement

One unit, start to finish. You are the **orchestrator** — you gate, dispatch, commit, and integrate. You never edit code, and you are the **only** one who touches git. Every seat below is a subagent dispatched by **agent name**, never an inline role prompt.

The unit is a **vertical slice**; the brief cuts it into **horizontal tasks**; each task is built by its own implementer and judged by its own reviewer. You hold the loop over tasks — the seats never see each other.

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

### 0. Ready to go

Read-only, seconds, on an empty context — and it closes early what otherwise surfaces after an expensive dispatch or, worse, at merge:

- the working tree is clean (`git status --porcelain` empty);
- no merge, rebase or cherry-pick in progress;
- the base branch is not behind its remote — if it is, the eventual merge is a rebase, and the user should know now;
- no stale worktree already exists for this unit;
- the unit resolves and reads — the ticket, the plan, the spec;
- **the unit's blockers are actually merged into this tree.** Today a missing blocker surfaces as the brief-writer returning BLOCKED, after an opus dispatch has been paid for. Checking here is nearly free.

Anything failing is the user's call, presented at the gate above.

### 1. Isolate

Cut the worktree from the tip of the current branch — `/using-git-worktrees`. **Record the base commit**: it is the review's fixed point, and it is never `HEAD~1` (which drops every commit but the last of a multi-commit unit).

### 2. brief-writer → the brief

Dispatch the **brief-writer** into the worktree. It explores the code itself and writes `.scratch/brief-NN.md`, returning only the path — or BLOCKED. You never read its exploration; only the path travels on.

### 3. Verify the brief — yourself

Read the brief and confirm it is load-bearing. **Never dispatch an implementer against a hollow brief:** with several implementers building from it at once, a hole becomes N agents guessing in parallel.

- **Blocks present** — The slice, Files, Interfaces, Binding Decisions, Plan, Execution Boundary, Verify, Sweep — with `Verify` named and shown already-run, Global Constraints verbatim, no placeholders.
- **The cut.** Is each task one functionally whole horizontal layer? A single task covering a slice that plainly has layers is the defect this engine exists to prevent — send it back. So is a task per function.
- **Every task self-sufficient.** Real values, named seams, no step that sends its implementer into the code to find a location, name or approach. Its `Consumes` names every signature it needs, including those a sibling task produces.
- **The task graph.** Does every `Consumes` from a sibling carry a matching `Blocked by`? Do two tasks with no edge between them name the same file? Either answer wrong is a brief defect, not something to work around — an undeclared edge means building against nothing, and a shared file means two writers colliding.
- **Closure.** Could a competent implementer make a different locally-valid semantic choice, broaden into an adjacent surface, or cross an escalation trigger without the brief stopping it? Then `Binding Decisions`, a task's `Out of scope`, or `Execution Boundary` is hollow.

Send a hollow brief back to the brief-writer with the specific defect. **Five rounds maximum** — past that the brief-writer cannot see its own problem, and grinding is worse than asking. Escalate to the user with the rounds and what stayed broken.

### 4. Build the waves

The brief carries the tasks; **you do not re-plan them.** Read the list and execute it. If the list looks wrong, that is step 3's business — go back, don't fix it here.

#### Compute the wave

A **wave** is the set of tasks that can run side by side right now:

1. take every task whose `Blocked by` entries are all closed;
2. from those, keep a set whose `Files` are **pairwise disjoint**; anything left over waits for the next wave.

Both conditions matter and they catch different things: the edges stop a task building against a signature that doesn't exist yet, the file check stops two agents editing one file. A wave of one is a normal and correct outcome — layers usually chain.

#### Dispatch the pairs

Each task is a **pair**: an **implementer** builds it, then a **task-reviewer** judges it. Each dispatch carries exactly two things — **the brief's path and the task number**. Both seats read the brief for the rest, and the reviewer builds its own diff scoped to the task's `Files`, so nothing large passes through your context.

Dispatch **every implementer in the wave in one message** so they run concurrently. As each returns, dispatch its task-reviewer — reviewers are read-only, so they safely run alongside implementers still working.

Handle each implementer's status:

- **DONE** → its task-reviewer.
- **DONE_WITH_CONCERNS** → read the concerns first; resolve correctness or scope before the reviewer, carry observations to the slice review.
- **NEEDS_CONTEXT** → supply what was missing, re-dispatch — then fix the brief so the gap doesn't recur for the tasks still to come.
- **BLOCKED** → triage; most "too hard" is something else in disguise. A gap the brief should have closed → treat as NEEDS_CONTEXT. An open decision with several valid answers → the user's call, never the seat's. The task too large → the cut was wrong, back to step 3. The unit itself wrong → escalate. Only when none fit is the seat genuinely too small: propose the **same implementer on a stronger model** and wait for the user's go — spend sits behind a gate. Never force an unchanged retry.

**A failed task does not stop its siblings.** They are file-disjoint by construction, so they cannot corrupt each other; let the wave finish. Only closed tasks are committed. The next wave waits on its *own* blockers, not on the whole previous wave — if the failed task doesn't block it, it runs. A task that exhausts its fix loop is `BLOCKED` and escalates **before** any wave that depends on it starts.

#### The fix loop, per task

Triggered by any Critical or Important finding, or a failed conformance verdict. Minor findings never enter it — record them and hand them to the slice review to triage.

**Five rounds maximum per task:**

- **rounds 1–3** — the **same implementer**, findings verbatim. Its context is intact: it knows the task, the code, and its own choices, so it pays only for the findings.
- **rounds 4–5** — a **fresh implementer on a stronger model**, carrying the brief path, the report path, and the framing: *a prior implementer attempted this N times; you own it now, read the report for what was tried.* A loop that survives three resumes usually means the implementer cannot see its own problem — fresh eyes and a capability bump in one move.
- Every round ends with the **same task-reviewer contract**, re-run against the amended code. The reviewer verdicts each finding; "attempted" is not addressed.

**At the cap**, stop dispatching and adjudicate each open finding yourself:

- the reviewer is wrong, or the point is contestable → **park it** with your ruling, and hand it to the slice review;
- real but nothing downstream builds on it → park it the same way, ruled real and deferred;
- **real and load-bearing** — a later task builds on it, or it exposes a brief defect → **stop.** Escalate to the user with the finding, the brief text it collides with, and the fix history.

Adjudicate **only** at the cap. Adjudicating earlier to end a loop is pre-judging with a different name, and a silently dropped finding is forbidden.

A finding that conflicts with what the brief mandates is the **user's** call: present it beside the brief text and ask which governs. `brief-mandated` is a label, not a defence — the brief's authorship does not grade its own work.

#### Commit the wave — you, and only you

Every task in the wave closed? Then commit, and **you are the only one who touches git.** No agent stages, commits or amends anything: one worktree means one index, and two agents staging at once produces a commit silently carrying another's half-written files.

1. **Check the fence mechanically.** Compare `git status --porcelain` against the union of the wave's tasks' `Files`. Anything modified outside that union belongs to no task — that is a boundary violation found without an agent looking for it. Resolve it before committing.
2. **Stage by path** — the wave's declared files, never `git add -A`.
3. **One commit for the wave**, naming the tasks: `feat(x): wave 2 — transport layer, client wiring`.

Fixes land **before** the commit, not after: a commit of unreviewed work means "wave N" no longer marks a closed wave.

The commit list plus the task reports in `.scratch/` are the run's memory. If your context is compacted mid-run, recover from those — `git log` for the closed waves, `.scratch/report-NN-task-K.md` for the tasks closed inside the current one. **Trust them over your own recollection**, and never re-dispatch a task whose report is already on disk.

Then compute the next wave, until every task is closed.

### 5. /verified-review — the slice

Raise `/verified-review` **once**, after the last wave, with the fixed point set to **the base commit from step 1**.

Once, and not per wave: until the final wave lands, the vertical slice does not exist yet — there is no end-to-end behaviour to drive, and the expensive part of the review (the full sweep, the runtime, a capable model on the whole diff) would be paid N times for a partial answer.

This is where everything a task reviewer structurally could not see gets judged: the full sweep, the real runtime, duplication **between** tasks, Shotgun Surgery across the slice, coherence between the layers, the Spec axis against the ticket, and the Minor findings parked during the waves.

- Findings → dispatch **one fixer per findings list** (never one per finding), carrying the line: *findings received → follow `/receiving-code-review`*. Re-review after — scoped, per `/verified-review`'s re-review contract. The system-wide pass happens once; rounds converge on the findings.
- A finding that conflicts with what the unit mandates is the user's call: present it beside the unit text and ask which governs.
- Fixes are committed by you, as their own commit — `fix: slice fix 1 — <what changed>`.
- **Green on every axis, with the runtime observed working, closes the review.** No report is ever a close condition; a green sweep is a working signal, not evidence the thing runs.

### 6. adr-candidate → write it

If the review surfaced an `adr-candidate`, write the ADR **now, automatically, before integrating** — its own commit on the branch, so it merges with the work and cannot be lost. Use `/domain-modeling`'s ADR format; the candidate already carries the decision and its trade-off, so no question is asked — not losing it outweighs the gate. (`/finish-branch`'s harvest stays the final catch for anything that slipped.)

### 7. Integrate

Hand off to `/finish-branch`. It carries its own STOP-gate and the merge / PR / keep / discard menu, and asks what to do with the worktree.

Before the menu, **read the branch log.** `wave 1 → wave 1 fix → wave 2 → slice fix 1` is a diagnostic surface that costs nothing and disappears at the squash: many rounds on one wave says the cut was wrong, the brief was thin, or the reviewers are miscalibrated. Read it while it exists.

## Red flags

The six that are not stated anywhere above — the rest of the contract lives in the steps:

- **Say "done" on green tests alone.** A fake/mock/fixture-backed green is a working signal, not proof the thing runs; the word waits until you have watched it work.
- **Dispatch a seat by inline role prompt** instead of by agent name — the seat's protocol lives in its definition, and an inline prompt silently forks it.
- **Paste a seat's output into the next dispatch.** Dispatches carry paths, never contents.
- **Tell a reviewer what not to flag**, or pre-rate a finding's severity. Let it surface and adjudicate it yourself.
- **Edit code yourself, or let an agent touch git.** You orchestrate and you alone commit; the seats build.
- **Re-dispatch a task whose report is already on disk.** After a compaction, `git log` and `.scratch/` are the truth and your recollection is not.

**Related:** `/tier-1` drives this for one unit · `/tier-2` feeds it tickets one at a time · `/brief` is the brief-writer's protocol · `/verified-review` reviews the finished slice and drives the real runtime · `/finish-branch` integrates · `/using-git-worktrees` isolates the worktree
