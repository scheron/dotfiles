---
name: autopilot
description: Run a batch of already-cut tickets through the /to-implement engine UNATTENDED, in dependency order — one fresh headless session per ticket, advancing on green, halting on the first red. The automation layer over /to-tickets → /to-implement: instead of driving each ticket by hand in a fresh chat, hand the runner a set (e.g. 1,2,3) and it works the frontier. Sequential v1. Resumable.
---

<STOP-GATE>
Render the plan first, then wait for one explicit go. Run `autopilot.sh --dry-run <batch>` and present its output verbatim — the topological order, each ticket's blockers and done/pending status, the integration branch, and the policy (sequential · halt-on-red · permission-mode auto). Then:

Autopilot will run these tickets through `/to-implement` **unattended**, landing each on the integration branch on green and **halting on the first red**. Plan-in was already approved when the tickets were cut at `/to-tickets`; review-out stays fully enforced (`/verified-review` must go green per ticket). Go?

Nothing is branched, spawned, or integrated until the go is given.
</STOP-GATE>

# Autopilot

The loop that `/to-tickets` and `/to-implement` deliberately left to the human — now automated, without giving up what made it manual. Each ticket still runs through the **real `/to-implement`** in a **fresh session**, so every brief stays sharp; autopilot only adds the *scheduler* around it.

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

**Preconditions:** a clean working tree, and local-file tickets under `.scratch/<feature>/issues/<NN>-*.md` with a `Blocked by` line (what `/to-tickets` writes). Real-tracker batches are out of scope for v1.

## The contract (what the врезки rely on)

The runner sets three environment variables for each child session; the `/to-implement` **Autopilot exception** honours them:

| Variable | Meaning |
|---|---|
| `DEV_STACK_AUTOPILOT=1` | the master switch — pre-authorizes plan-in, and stands the `review-guard` Stop-hook down (review-out is enforced structurally instead) |
| `DEV_STACK_INTEGRATION_BRANCH` | the branch each worktree cuts from and lands back onto |
| `DEV_STACK_AUTOPILOT_SENTINEL` | the exact file the child writes (the merge SHA) as its final act on a clean green→merge land |

**Advance = sentinel present AND the integration branch advanced.** Anything else — no sentinel, branch unchanged, child died — is a **halt**. The child never reports its own success; the loop reads the disk. A derailed session simply leaves no sentinel, so a soft failure degrades to a safe halt, never a bad merge.

## The moving base

There is one **integration branch**. Ticket N's worktree cuts from its current tip; on green it merges back; the next ticket cuts from the new tip. That is what gives a dependent ticket its blockers' code for free — and because v1 is strictly sequential, merges are serialized and the runner introduces no conflicts of its own.

## Halt & resume

On the first red the run stops and writes the reason to `<git-common-dir>/dev-stack/autopilot/<feature>/run.json`. Fix the ticket by hand (its worktree/branch are left in place), then **re-run the same command** — the runner recomputes the frontier from the sentinels, skips what already landed, and continues. There is no separate "resume" verb; the command *is* idempotent.

## Red flags

**Never:**
- Run with a dirty working tree — the runner refuses; commit or stash first
- Point `--integration-branch` at the default branch — landings would fight `branch-guard`, and unreviewed history would reach the main line
- Treat a child's chat output as the outcome — only the sentinel + branch advance close a ticket
- Parallelize the frontier in v1 — sequential is the whole safety story; concurrent merges are a separate design
- Weaken review-out to make a ticket pass — a halt is the correct outcome; `/verified-review` green is not negotiable

**Related:** `/to-tickets` cuts the batch this runs · `/to-implement` is the per-ticket engine (its Autopilot exception is the entry point) · `/finish-branch` lands each ticket (Option 1, driven non-interactively) · `/verified-review` still gates every ticket
