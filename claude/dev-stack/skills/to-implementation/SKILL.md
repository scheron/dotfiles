---
name: to-implementation
description: The execution engine both tiers share — runs every unit as a fresh subagent in its own worktree off the hub, filters its inner loop through the test-runner, closes units only by /verified-review, and integrates only on the user's word. Input: a spec, one ticket, several tickets, or nothing (the approved chat plan is the single unit). Use to build specced or ticketed work, or as the body of /tier-1 and /tier-2.
---

<STOP-GATE>
Present what is about to run and wait for the user's explicit go before creating any worktree or dispatching any seat:

- the **units** — each by name, in the order the frontier gives them;
- the **batch** — which units launch together in this wave (overlap is the user's risk, §Integration);
- the **launch point** — the hub tip every spoke of this wave branches from, named as a commit the user can see.

Nothing is branched, dispatched, or merged until the go is given.
</STOP-GATE>

One engine, both tiers. Tier 1 is the degenerate case — one unit; Tier 2 orchestrates many. Each unit runs the same lifecycle down the model ladder (STACK.md §6): a fresh top-tier brief-writer, a standard-tier implementer, the test-runner sweep, then `/verified-review`. You are the orchestrator — you gate, dispatch, and integrate; you never edit code yourself.

## Input — what a unit is

| Input | Units |
|---|---|
| a **spec** | its tickets (read them from where the spec says they live) |
| **one ticket** | that ticket |
| **several tickets** | those tickets |
| **nothing** | the approved plan from chat is the single unit — Tier 1 |

**Tier 1 topology.** With a single unit and no feature branch, the unit's worktree — branched from the default branch — *is* the hub. There is no separate feature branch to merge into: integration goes straight through `/finish-branch`. The hub-and-spoke machinery below still runs, collapsed onto one branch.

## Pre-flight

Read every unit once, before dispatching any. Two scans, both cleared before execution starts:

- **Contradiction scan.** Anything a unit mandates that contradicts another unit, the spec's Global Constraints, or that `/verified-review` would treat as a defect. Present everything as **one batched question** — each finding beside the text that mandates it, asking which governs. Not one interrupt per discovery mid-run. A clean scan → proceed without comment.
- **Ledger resume.** Read the ledger (below). A unit already marked complete is **done** — never re-dispatch it. Resume at the first unit not closed.

## Per unit — the model ladder

Down the ladder (STACK.md §6), one rung at a time. Every seat below is dispatched by **agent name**, never by an inline role prompt — the model is pinned once in the agent's frontmatter.

### 1. Spoke off the approved hub tip

Create the unit's worktree from the hub tip the user approved at the gate — isolation per `/using-git-worktrees` (its Step 0.5 pins the base to the approved hub tip, not the default branch, and verifies it). **Record the spoke's branch base commit** — it is the review fixed point, and it is never `HEAD~1`.

### 2. brief-writer → the brief

Dispatch the **brief-writer** agent into the spoke. It explores the code itself, writes `.scratch/brief-NN.md` in the spoke, and returns only the path (or BLOCKED). You never read its exploration — only the path travels on.

### 3. implementer → the build

Dispatch the **implementer** agent with the brief's path. It reads the brief as its first act and works `/tdd` at the brief's seams. Handle its returned status:

- **DONE** — proceed to the sweep.
- **DONE_WITH_CONCERNS** — read the concerns first. Correctness or scope concerns are resolved before the sweep; observations are carried to the review.
- **NEEDS_CONTEXT** — supply what was missing and re-dispatch. Then ask why the brief didn't carry it, and fix the brief-writer's output for the next unit.
- **BLOCKED** — assess: context problem → provide more, re-dispatch the same seat; needs more reasoning → this is the wrong seat, escalate; unit too large → the slice was wrong, split it; the unit itself is wrong → escalate to the user. Never force an unchanged retry.

### 4. The test-runner sweep — run by you

Once the implementer reports done, **you** dispatch the **test-runner** agent in the spoke — the implementer never runs the full sweep. It returns a summary: counts, failing names, one line per failure, never stacktraces.

- **GREEN** → to review.
- **RED** → send the summary back to the **same implementer** — its context is alive, it pays only for the summary, never a fresh dispatch. It fixes in place and re-reports; you re-sweep.
- **Three red rounds in a row → BLOCKED.** Escalate to the user (the three-fix breaker of `/diagnose`, held here by the orchestrator). Never grind an unwinnable loop.

### 5. /verified-review — the only receipt

On green, raise `/verified-review` with the fixed point set to **the spoke's branch base you recorded in step 1** — never `HEAD~1`, which silently drops all but the last commit of a multi-commit unit. It runs stage 0 (Verify + lint + typecheck, itself) then the Standards and Spec axes in parallel.

- Findings → dispatch **one fixer per findings list** (never one per finding), carrying the conditional line: *findings received → follow `/receiving-code-review`*. Re-review after.
- A finding that conflicts with what the unit mandates is the user's call: present the finding beside the unit text, ask which governs. Don't dismiss the finding; don't fix against the unit without asking.
- **Green on all three axes closes the unit — nothing else does.** The implementer's report is never a close condition.

### 6. Close the unit

Append one line to the ledger, carrying all three verdicts by name (below). Delete nothing from `.scratch/` — `/finish-branch` harvests it. Then back to the frontier.

## Integration — the STOP-gate

Green units do not merge on their own. At the gate, **propose and wait** (STACK.md §5):

- the **merges** — which green units fold into the hub;
- the **adr-candidates** the reviews surfaced — one line each; approval sends each to `/domain-modeling`, which writes the ADR into the hub, so later spokes see it through git by construction;
- the **next wave's launch point** — the new hub tip the next batch branches from.

Merges, ADRs, and the next wave share this one pause — no extra interrupts. **Never merge or launch a wave without the user's word** — the starting point of every batch is theirs.

- **Batch overlap is the user's risk.** Briefs are born inside the spokes, so no disjoint-files check exists at dispatch. Conflicts surface at merge into the hub and route to `/resolving-merge-conflicts` — the honest price of the simpler topology.
- **A failed spoke is discarded with its worktree.** The hub stays clean — no resets, no pollution.

## When the frontier is empty

One `/verified-review` over the whole branch — fixed point = the merge-base with the default branch (`git merge-base <default> HEAD`), on the strongest model. Point it at the Minor findings the ledger accumulated so it can triage what must be fixed before merge. Then `/finish-branch`.

## The ledger

Conversation memory does not survive compaction; a controller that lost its place has re-dispatched whole completed sequences — the single most expensive failure mode there is.

```
hub  .scratch/<feature>/ledger.md
```

- One line per closed unit, carrying all three verdicts **by name**: `Unit NN: complete (commits <base7>..<head7>, Verify green, Spec ✓, Standards ✓)`. A line that cannot state all three is proof the review didn't run — the unit is not closed.
- Record Minor findings here as you go, for the final whole-branch review to triage. A roll-up nobody reads is a silent discard.
- After any compaction, **trust the ledger and `git log` over recollection.** Per-spoke ephemera dies with the spoke; the ledger line is what survives.

## File handoffs

Everything pasted into a dispatch and everything a seat prints back stays resident in your context, re-read every turn. Move it as **paths, not content**:

- Dispatches carry the brief path, the report path, the fixed point — never their contents.
- Never paste one unit's history into another's dispatch. A fresh seat needs its brief and the Global Constraints, nothing else.
- Exact values — numbers, magic strings, signatures — live **only** in the brief.

## Red flags

**Never:**
- Close a unit without a `/verified-review` green on all three axes — the ledger line carries `Verify green, Spec ✓, Standards ✓`, or the unit isn't closed
- Use `HEAD~1` as the review fixed point — it drops every commit but the last of a multi-commit unit
- Re-dispatch a unit the ledger already marks complete
- Merge a green unit or launch the next wave without the user's word
- Paste prior-unit history into a dispatch
- Let the implementer's self-review replace `/verified-review` — both are needed
- Tell a reviewer what not to flag, or pre-rate a finding's severity
- Dispatch a seat by inline role prompt instead of by agent name
- Work on the default branch — every spoke is isolated, Tier 1 included

**Related:** `/tier-1` and `/tier-2` drive this engine · `/brief` is the brief-writer's protocol · `/verified-review` is the gate that closes each unit · `/finish-branch` closes the run when the frontier is empty · `/using-git-worktrees` creates each spoke · `/resolving-merge-conflicts` handles collisions at the hub
