---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

# Using Git Worktrees

## Overview

Settle where the work happens before any of it starts. There are three places, and they are peers rather than a preference order — a worktree isolates hardest, a new branch here is cheaper and keeps one working directory, the current branch has no isolation at all. Which one fits is your human partner's call, and this skill never makes it silently.

**Core principle:** Check the repository's state first. Then take the choice. Then never fight the harness — a native worktree tool always beats raw git.

**Announce at start:** "I'm using the using-git-worktrees skill to set up the workspace."

## Step 0a: Pre-flight

Run this before offering any choice — its findings change which choice is right:

```bash
scripts/preflight
```

It reports, from local refs only, what is expensive to discover later: an unfinished merge, rebase, cherry-pick, revert or bisect; a detached HEAD; uncommitted changes; commits that exist only on this branch; and how far `origin/<default>` has moved since this point.

It blocks nothing — exit 1 means findings, not failure. Show them with the choice and let your human partner decide. Some findings decide it for them: uncommitted changes ride along onto a new branch but stay behind when you leave for a worktree, and an unfinished merge makes every option a bad one until it is settled.

## Step 0b: Detect Existing Isolation

**Before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree, and do not ask the workspace question — it is already answered.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout. Take the choice below.

## Step 0c: The Workspace Choice

**Ask. Every time.** Present the pre-flight findings, then exactly this:

```
Where should this work happen?

  1. Isolated worktree — a separate directory, this branch untouched
  2. New branch here — one working directory, current branch left behind
  3. Right here on <current-branch> — no isolation

Which one?
```

Wait for the answer. This is not a formality to skip when the answer seems obvious: option 3 on a shared branch and option 1 with uncommitted changes are both quietly expensive, and only your human partner knows which they meant.

Two things settle it without asking: an existing linked worktree (Step 0b — already answered), and an explicit standing instruction naming a workspace preference. A guess about which one they would probably want is neither.

**If option 3 lands on the default branch**, say so before proceeding: in a repo carrying `.branch-guard`, `branch-guard` denies every edit and commit there, so the run stops at the first write rather than at the end. Offer 1 or 2 instead.

Then: option 1 → Step 1a/1b · option 2 → Step 1c · option 3 → skip to Step 2.

## Step 1: Create the Workspace

**Option 1 has two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), say the sandbox blocked worktree creation and offer Step 1c instead — a branch in place is the closest thing left to isolation. Do not silently drop to option 3.

### 1c. New Branch Here

Chosen at Step 0c, or reached when a worktree could not be created.

```bash
scripts/new-branch <type> <slug>
```

`type` is a Conventional Commits type (`feat`, `fix`, `chore`, `refactor`, `docs`, `perf`), `slug` a short description — the script sanitises it to kebab-case and switches to `<type>/<slug>`, reusing the branch if it already exists.

It refuses to branch off anything but the default branch, exiting 3 with the base it found. That refusal is the point: branching off a half-finished feature branch buries this work inside someone else's, and the failure only surfaces at merge time. Ask which the user meant, then either switch to the default branch and re-run, or pass `--from-here` to branch from where you are.

It also warns when uncommitted changes will move onto the new branch. They are not lost — they follow you — but they are now part of this work whether you meant them to be or not.

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Run tests to ensure workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Before anything else | `scripts/preflight` (Step 0a) |
| Already in linked worktree | Skip creation and the choice (Step 0b) |
| In a submodule | Treat as normal repo (Step 0b guard) |
| Normal checkout | Ask the workspace question (Step 0c) |
| Option 2 chosen, or worktree denied | `scripts/new-branch` (Step 1c) |
| `new-branch` exits 3 (non-default base) | Ask, then switch or `--from-here` |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0b. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "They always want a worktree — I'll just make one" | Ask. A worktree leaves uncommitted work behind in the old directory, which is a surprise every time it happens. |
| "The repo looks clean, skip the pre-flight" | It costs one local command and no network. An unfinished rebase or a base that moved months ago does not show up in a glance, and both are far more expensive to meet after the feature is built. |
| "Pre-flight returned 1, so I must stop" | It is advisory. Exit 1 means findings to show alongside the choice, not a failure to escalate. |
| "`new-branch` refused — I'll pass `--from-here`" | The refusal means the base is not the default branch. `--from-here` is your human partner's answer to give, not your workaround. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call. |
