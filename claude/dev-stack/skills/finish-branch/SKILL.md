---
name: finish-branch
description: Complete development work — harvest durable knowledge into ADRs and CONTEXT.md, verify the build, present integration options (merge, PR, keep, discard), execute the choice, and clean up the worktree and .scratch/. Use when implementation is complete and tests pass.
---

# Finish Branch

**Core principle:** Harvest → Verify → Detect environment → Present options → Execute → Clean up.

> Port of superpowers' `finishing-a-development-branch` (MIT, Jesse Vincent), with one step added: **Step 1, Harvest**. The branch is about to disappear along with everything ephemeral on it; whatever deserved to outlive it has to be extracted first, deliberately, while the context still exists.

## Step 1 — Harvest the durable layer

`.scratch/` is about to be deleted and the branch merged. Anything worth keeping has to move **now** — this is the last moment the knowledge and the context coexist.

Walk the feature's `.scratch/` directory, the ledger, and the review reports, and ask three questions:

**Did a decision get made that is hard to reverse, surprising without context, and the result of a real trade-off?**
All three, or it's not an ADR. Write it to `docs/adr/` — including the alternatives that were rejected and why. The rejected branch is the half that stops the next agent rediscovering a dead end.

**Did a term get settled, sharpened, or disambiguated?**
Into `CONTEXT.md`, via `/domain-modeling`. Definition only — one or two sentences, what it *is*, plus the rejected synonyms under `_Avoid_`. No implementation details; `CONTEXT.md` is a glossary and nothing else.

**Did the repo gain or lose a way to verify itself?**
Update `AGENTS.md` → `## Build & run`. New commands go in. Commands that turned out not to work honestly come out, or get marked. That section is the verification contract every later brief reads first — a stale one poisons every future ticket.

Also carry forward, if they came up:

- **"No Verify command exists" findings** → an issue, or `## Known issues` in `AGENTS.md` if there's no tracker
- **"No correct seam exists" findings** from `/diagnose` → same
- **Minor review findings the final review chose not to fix** → an issue, not the ledger, which is about to be deleted

Show the user what you're about to write before writing it.

**What does not get harvested:** briefs, reports, ledger, prototypes, plans. They were exact because they were disposable. Promoting them to the repo recreates the staleness the split exists to prevent.

## Step 2 — Verify

Run the project's verification command — from `AGENTS.md` → `## Build & run`, not from memory.

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
| `GIT_DIR == GIT_COMMON` (normal repo) | 4 options | no worktree to clean |
| `GIT_DIR != GIT_COMMON`, named branch | 4 options | provenance-based (Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | 3 options (no merge) | none — externally managed |

## Step 4 — Determine the base branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main — is that right?"

## Step 5 — Present options

**Normal repo or named-branch worktree — exactly these four:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

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

### Option 1 — Merge locally

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

### Option 2 — Push and create a PR

```bash
git push -u origin <feature-branch>
```

**Do not clean up the worktree** — it's needed for PR feedback. `.scratch/` also stays: review comments may need the briefs.

### Option 3 — Keep as-is

Report: "Keeping branch \<name\>. Worktree preserved at \<path\>." No cleanup.

### Option 4 — Discard

Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <list>
- Worktree at <path>
- .scratch/<feature>/

Type 'discard' to confirm.
```

Wait for the exact word. Then `cd` to the main root, clean up (Step 7), and `git branch -D <feature-branch>`.

**Harvest still ran.** Discarding the code does not discard what was learned — an ADR written in Step 1 is often the entire value of an abandoned branch.

## Step 7 — Clean up

**Only for Options 1 and 4.** Options 2 and 3 always preserve everything.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**`.scratch/<feature>/`** — delete it. Harvest already ran; what's left is briefs, reports, and the ledger, all of which were correct only for a codebase that no longer exists.

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
| 1. Merge locally | yes | yes | — | — | yes | delete |
| 2. Create PR | yes | — | yes | yes | no | — |
| 3. Keep as-is | yes | — | — | yes | no | — |
| 4. Discard | yes | — | — | — | yes | force-delete |

## Common mistakes

**Skipping harvest** — the ADR that would have saved the next feature dies with the branch. This is the failure this fork exists to prevent, and it's silent: nothing breaks, you just pay again in three weeks.

**Harvesting the briefs** — promoting exact paths into the repo recreates spec-rot. Briefs were allowed to be precise *because* they were disposable.

**Skipping verification** — merging broken code, opening a failing PR.

**Cleaning up for Option 2** — removing the worktree the user needs for PR iteration.

**Deleting the branch before removing the worktree** — `git branch -d` fails while a worktree still references it. Merge, remove worktree, then delete.

**Running `git worktree remove` from inside the worktree** — fails silently. Always `cd` to the main root first.

**No confirmation on discard** — accidental loss of work.

## Red flags

**Never:**
- Proceed with verification failing
- Merge without verifying the merged result
- Delete `.scratch/` before harvest
- Promote a brief, report, or ledger into the repo
- Delete work without typed confirmation
- Force-push without an explicit request
- Remove a worktree before confirming the merge succeeded
- Clean up a worktree you didn't create

**Always:**
- Harvest before anything is deleted, and show the user what you'll write
- Verify from `AGENTS.md` `## Build & run`, not memory
- Detect the environment before presenting the menu
- Present exactly 4 options (3 on detached HEAD)
- `cd` to the main root before removing a worktree, then `git worktree prune`

**Related:** `/execute-tickets` hands off here · `/domain-modeling` owns `CONTEXT.md` and ADR writing · `/using-git-worktrees` created the workspace this removes
