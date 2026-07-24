---
name: finish-branch
description: Complete development work — harvest durable knowledge into ADRs and CONTEXT.md on the default branch, verify the build, present integration options, execute the choice, and clean up the worktree and .scratch/. Use when implementation is complete and tests pass.
---

<STOP-GATE>
Implementation is complete and the tree is green. I'll harvest the durable layer (ADRs, CONTEXT.md) to the default branch and re-run verification, then integrate — how should this land?

1. Merge to the base branch, then delete the branch and worktree
2. Merge to the base branch, keep the branch and worktree
3. Push and open a Pull Request
4. Keep the branch as-is
5. Discard this work

Detached HEAD drops the merge options. The exact menu is confirmed after environment detection (Step 3).
</STOP-GATE>

# Finish Branch

**Core principle:** Harvest → Verify → Detect environment → Present options → Execute → Clean up.

**Step 1, Harvest** is the final sweep for durable knowledge that didn't already land mid-flight. The branch is about to disappear along with everything ephemeral on it; whatever deserved to outlive it and slipped past the `adr-candidate` gate has to be extracted now, while the context still exists.

## Step 1 — Harvest the durable layer (the final sweep)

ADRs are meant to land **mid-flight** — `/verified-review` raises them as `adr-candidate` findings and the orchestrator writes them straight to the default branch. This step is the **final sweep**: the last pass for anything that slipped through before `.scratch/` is deleted and the branch merged. No longer the only chance to capture a decision — but the last.

Walk the unit's `.scratch/` directory and the review report, and ask two questions:

**Did a decision get made that passes the ADR test `/domain-modeling` owns — and never make it into `docs/adr/`?**
The test is the same one `/verified-review` applies mid-flight (hard to reverse, surprising without context, a real trade-off — all three, or it's not an ADR). Passed it and it's already recorded? Nothing to do. Otherwise write it to `docs/adr/` now — including the alternatives that were rejected and why. The rejected branch is the half that stops the next agent rediscovering a dead end.

**Did a term get settled, sharpened, or disambiguated?**
Into `CONTEXT.md`, via `/domain-modeling`. Definition only — one or two sentences, what it *is*, plus the rejected synonyms under `_Avoid_`. No implementation details; `CONTEXT.md` is a glossary and nothing else.

**ADRs and `CONTEXT.md` go straight to the default branch** — commit them there directly (`branch-guard` passes `docs/adr/` and `CONTEXT.md`), not onto this unit's branch. Domain knowledge belongs on the main line, and committing it there means it survives even if the code below is discarded.

Also carry forward, if they came up:

- **"No Verify command exists" findings** → an issue in the tracker
- **"No correct seam exists" findings** from `/diagnose` → same
- **Minor review findings the final review chose not to fix** → an issue

Show the user what you're about to write before writing it.

**What does not get harvested:** briefs, reports, prototypes, plans. They were exact because they were disposable. Promoting them to the repo recreates the staleness the split exists to prevent.

## Step 2 — Verify

Run the unit's verification — the brief's `Verify` plus its `Sweep` directions, not from memory.

**If it fails:**

```
Verification failing (<N> failures). Must fix before completing:

[show failures]

Cannot proceed with merge/PR until this is green.
```

Stop. Do not proceed to Step 3.

## Step 3 — Detect the environment

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

| State | Menu | Cleanup |
|---|---|---|
| `GIT_DIR == GIT_COMMON` (normal repo) | 5 options | no worktree to clean |
| `GIT_DIR != GIT_COMMON`, named branch | 5 options | provenance-based (Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | 3 options (no merge) | none — externally managed |

## Step 4 — Determine the base branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main — is that right?"

## Step 5 — Present options

**Normal repo or named-branch worktree — exactly these five:**

```
Implementation complete. What would you like to do?

1. Merge to <base-branch>, then delete the branch and worktree
2. Merge to <base-branch>, keep the branch and worktree
3. Push and create a Pull Request
4. Keep the branch as-is (I'll handle it later)
5. Discard this work

Which option?
```

**Detached HEAD — exactly these three:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

Don't add explanation. Keep the options concise.

## Step 6 — Execute

### Option 1 — Merge, then delete

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

git checkout <base-branch>
git pull
git merge <feature-branch>

# verify on the merged result, not just on the branch
<verify command>
```

Only after the merge succeeds: clean up (Step 7), then `git branch -d <feature-branch>`.

### Option 2 — Merge, then keep

The same merge as Option 1 — `checkout` the base, `pull`, `merge <feature-branch>`, and verify the merged result. Then **stop**: no cleanup. The branch and worktree stay for follow-up work; do not remove the worktree or delete the branch.

### Option 3 — Push and create a PR

```bash
git push -u origin <feature-branch>
```

**Do not clean up the worktree** — it's needed for PR feedback. `.scratch/` also stays: review comments may need the briefs.

### Option 4 — Keep as-is

Report: "Keeping branch \<name\>. Worktree preserved at \<path\>." No cleanup.

### Option 5 — Discard

Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <list>
- Worktree at <path>
- .scratch/

Type 'discard' to confirm.
```

Wait for the exact word. Then `cd` to the main root, clean up (Step 7), and `git branch -D <feature-branch>`.

**Harvest still ran.** Discarding the code does not discard what was learned — an ADR written in Step 1 is already on the default branch, often the entire value of an abandoned branch.

## Step 7 — Clean up

**Only for Options 1 and 5.** Options 2, 3, and 4 always preserve everything.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**`.scratch/`** — delete it. Harvest already ran; what's left is briefs and reports, both correct only for a codebase that no longer exists.

**Worktree:**

- `GIT_DIR == GIT_COMMON` → normal repo, nothing to remove. Done.
- Worktree path under `.worktrees/` or `worktrees/` → we created it, we own cleanup:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

- Otherwise → the harness owns this workspace. Do **not** remove it.

## Quick reference

| Option | Harvest | Merge | Push | Keep worktree | Delete `.scratch/` | Branch |
|---|---|---|---|---|---|---|
| 1. Merge + delete | yes | yes | — | — | yes | delete |
| 2. Merge + keep | yes | yes | — | yes | no | keep |
| 3. Create PR | yes | — | yes | yes | no | — |
| 4. Keep as-is | yes | — | — | yes | no | — |
| 5. Discard | yes | — | — | — | yes | force-delete |

## Common mistakes

**Skipping harvest** — the ADR that slipped past the mid-flight `adr-candidate` gate dies with the branch. Most decisions are recorded during the run now; this sweep is the last catch for the ones that weren't, and missing it is silent: nothing breaks, you just pay again in three weeks.

**Harvesting the briefs** — promoting exact paths into the repo recreates spec-rot. Briefs were allowed to be precise *because* they were disposable.

**Skipping verification** — merging broken code, opening a failing PR.

**Cleaning up for Option 2 or 3** — removing the worktree the user asked to keep, or needs for PR iteration.

**Deleting the branch before removing the worktree** — `git branch -d` fails while a worktree still references it. Merge, remove worktree, then delete.

**Running `git worktree remove` from inside the worktree** — fails silently. Always `cd` to the main root first.

**No confirmation on discard** — accidental loss of work.

## Red flags

**Never:**
- Proceed with verification failing
- Merge without verifying the merged result
- Delete `.scratch/` before harvest
- Promote a brief or report into the repo
- Delete work without typed confirmation
- Force-push without an explicit request
- Remove a worktree before confirming the merge succeeded
- Clean up a worktree you didn't create

**Always:**
- Harvest before anything is deleted, and show the user what you'll write
- Write ADRs and `CONTEXT.md` to the default branch, not the unit's branch
- Verify from the brief's `Verify`/`Sweep`, not memory
- Detect the environment before presenting the menu
- Present exactly 5 options (3 on detached HEAD)
- `cd` to the main root before removing a worktree, then `git worktree prune`

**Related:** `/to-implement` hands off here · `/domain-modeling` owns `CONTEXT.md` and ADR writing · `/using-git-worktrees` created the workspace this removes
