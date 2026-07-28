---
name: autopilot
description: "Run a batch of already-cut tickets through the /to-implement engine UNATTENDED, in dependency order — one fresh headless session per ticket, advancing on green, halting on the first red. The automation layer over /to-tickets → /to-implement: instead of driving each ticket by hand in a fresh chat, hand the runner a set (e.g. 1,2,3) and it works the frontier. Runs one ticket at a time; resumable."
---

<STOP-GATE>
Render the plan first, then wait for one explicit go. Run `autopilot.sh --dry-run <batch>` and present its output verbatim — the topological order, each ticket's blockers and done/pending status, the integration branch, and the policy (sequential · halt-on-red · permission-mode auto). Then:

Autopilot will run these tickets through `/to-implement` **unattended**, landing each on the integration branch on green and **halting on the first red**. Plan-in was already approved when the tickets were cut at `/to-tickets`; review-out stays fully enforced (`/verified-review` must go green per ticket). Go?

Nothing is branched, spawned, or integrated until the go is given.
</STOP-GATE>

# Autopilot

The loop that `/to-tickets` and `/to-implement` leave to the human, run for you — without giving up what makes the manual path safe. Each ticket still runs through the **real `/to-implement`** in a **fresh session**, so every brief stays sharp; autopilot only adds the *scheduler* around it.

## What it is

`autopilot.sh` is a dumb sequential loop over the ticket DAG. For each **frontier** ticket (all blockers landed) it spawns one fresh headless session:

```
DEV_STACK_AUTOPILOT=1 claude -p "/to-implement <ticket>" --permission-mode auto
```

and advances when that session leaves a **success sentinel**, or halts when it doesn't. All durable truth lives on disk, so the loop is crash-safe and resumable.

## Run it

```bash
AP="${DEV_STACK_ROOT:-$(dirname "$(readlink "$HOME/.claude/skills/autopilot")")/..}/scripts/autopilot.sh"
"$AP" --dry-run 1,2,3      # render the plan for the gate
"$AP" 1,2,3                # after the go
```

That resolver mirrors `/verified-review`'s (`$DEV_STACK_ROOT` overrides; otherwise follow the installed symlink to the clone). Flags: `--feature <slug>` (needed only when `.scratch/*/issues` holds more than one feature), `--integration-branch <b>` (default `autopilot/<feature>`), `--base <ref>` (default the current branch).

**Preconditions:** a clean working tree, and local-file tickets under `.scratch/<feature>/issues/<NN>-*.md` with a `Blocked by` line (what `/to-tickets` writes). Real-tracker batches are not supported.

## The contract

The runner sets three environment variables for each child session; the `/to-implement` **Autopilot exception** honours them:

| Variable | Meaning |
|---|---|
| `DEV_STACK_AUTOPILOT=1` | the master switch — pre-authorizes plan-in, and stands the `review-guard` Stop-hook down (review-out is enforced structurally instead) |
| `DEV_STACK_INTEGRATION_BRANCH` | the branch each worktree cuts from and lands back onto |
| `DEV_STACK_AUTOPILOT_SENTINEL` | the exact file the child writes (the landed squash-commit SHA) as its final act on a clean green→merge land |

**Advance = sentinel present AND the integration branch advanced.** Anything else — no sentinel, branch unchanged, child died — is a **halt**. The child never reports its own success; the loop reads the disk. A derailed session simply leaves no sentinel, so a soft failure degrades to a safe halt, never a bad merge.

## The moving base

There is one **integration branch**. Ticket N's worktree cuts from its current tip; on green it merges back; the next ticket cuts from the new tip. That is what gives a dependent ticket its blockers' code for free — and because the runner is strictly sequential, merges are serialized and it introduces no conflicts of its own.

## Sequential tickets, parallel tasks

Two axes, and only one of them is sequential — mixing them up is the easy mistake here.

- **Tickets are strictly sequential.** One at a time, one merge at a time. That is the whole safety story, and concurrent merges are a separate design.
- **Tasks inside a ticket run as waves**, exactly as in the interactive engine — implementer and reviewer per task, several pairs at once when the brief declares their files disjoint. Nothing about that is disabled here, and nothing about it touches the integration branch: it all happens inside one ticket's worktree, where the child session is the only committer.

So a ticket's session dispatches more seats than it used to and lives longer. Two consequences worth knowing when a run halts:

- **Compaction is likelier**, and there is no human watching to notice. The child recovers from `git log` and `.scratch/report-*` — the wave commits and the task reports are the run's memory, and the engine forbids re-dispatching a task whose report is on disk.
- **A halt can now come from inside a ticket**, not just from its review: a brief that fails its verify loop, a task that exhausts its fix rounds, a finding that needs adjudication. All of them leave no sentinel, which is exactly the safe outcome.

## No parking, unattended

The interactive engine lets the orchestrator **park** a finding at a fix-loop cap — ruled contestable or not load-bearing — and carry it to the slice review. **Under autopilot it may not.**

Parking is a judgement the human delegates by being in the room. With nobody there, a parked finding is a bar quietly lowered and a red turned green by fiat. At any cap, and on any finding that conflicts with what the brief mandates, the child **halts** instead. A halt costs one re-run; a laundered finding costs the merge.

## Halt & resume

On the first red the run stops and writes the reason to `<git-common-dir>/dev-stack/autopilot/<feature>/run.json`. Fix the ticket by hand (its worktree/branch are left in place), then **re-run the same command** — the runner recomputes the frontier from the sentinels, skips what already landed, and continues. There is no separate "resume" verb; the command *is* idempotent.

## Red flags

**Never:**
- Run with a dirty working tree — the runner refuses; commit or stash first
- Point `--integration-branch` at the default branch — landings would fight `branch-guard`, and unreviewed history would reach the main line
- Treat a child's chat output as the outcome — only the sentinel + branch advance close a ticket
- Parallelize the frontier — sequential *tickets* are the whole safety story; concurrent merges are a separate design. (Parallel *tasks* inside one ticket are normal and untouched — see above.)
- Park a finding at a cap to keep the run moving — halt instead; nobody is present to have delegated that call
- Weaken review-out to make a ticket pass — a halt is the correct outcome; `/verified-review` green is not negotiable

**Related:** `/to-tickets` cuts the batch this runs · `/to-implement` is the per-ticket engine (its Autopilot exception is the entry point) · `/finish-branch` lands each ticket (Option 1, driven non-interactively) · `/verified-review` still gates every ticket
