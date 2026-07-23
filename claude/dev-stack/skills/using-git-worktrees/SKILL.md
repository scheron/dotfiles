---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
---

> Ported from superpowers' `using-git-worktrees` (MIT, Copyright (c) 2025 Jesse Vincent).
> Adapted by `dev-stack`: this is the isolation step for **every** tier (Tier 1 fixes included, so a batch runs in parallel), with a plan-gate reminder and a base-commit check (Step 0.5) added below. See ../../NOTICE.md.

# Using Git Worktrees

## Overview

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

> **dev-stack — two rules ride on top of the port below:**
> 1. **Plan gate.** Don't reach this skill to *start coding* until your tier's plan is presented and approved (Tier 1: a few lines in chat + a "go"; Tier 2/3: the spec / wayfinder gate). The worktree is where approved work goes — not a way around the gate.
> 2. **Base commit.** Before creating the worktree, confirm the *commit* you're branching off — right branch, and local not silently behind origin — Step 0.5 below.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Step 0: Detect Existing Isolation

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

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.

## Step 0.5: Confirm the base commit (dev-stack)

A worktree's base is a **commit you choose and then verify** — not a default you accept. Two silent traps put it on the wrong commit; check both before creating, and verify after.

Resolve the default branch and where you are:

```bash
DEF=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
[ -z "$DEF" ] && { git show-ref -q refs/heads/main && DEF=main || DEF=master; }
CUR=$(git branch --show-current)
```

**Trap 1 — wrong branch.** If `CUR != DEF`, STOP and ask before creating anything:
> "You're on `<CUR>`, not the default `<DEF>`. Branch this worktree from here, or from `<DEF>`?"

Set `BASE` to their choice (`$CUR` or `$DEF`).

**Trap 2 — local ahead of origin.** Native worktree tools (e.g. `EnterWorktree`) often default to branching from **`origin/<DEF>`** (a `worktree.baseRef=fresh`-style default), NOT your local branch. If your local base carries unpushed commits, that base silently drops them — including the foundation you're building on.

```bash
git rev-list --count "origin/$DEF..$DEF" 2>/dev/null   # >0 → local $DEF is ahead of origin
git rev-list --count "@{u}..HEAD"        2>/dev/null   # >0 → current HEAD has unpushed commits
```

If either is non-zero, choose the base deliberately:
- **keep the unpushed foundation** → base off **local** (`EnterWorktree`: set `worktree.baseRef=head`; git fallback: pass the local ref as the start point in Step 1b).
- **want a clean base off the pushed tip** → base off **origin** — only if nothing local is load-bearing.

**Then verify — do NOT trust the config.** A `baseRef` setting can silently fail to apply, so the tool may still branch from origin after you asked for local. After the worktree exists (Step 3), confirm it sits on the base you intended:

```bash
# FOUND = a commit that MUST be present (your foundation). Fails if the base was wrong.
git merge-base --is-ancestor "$FOUND" HEAD && echo "base ok" || echo "WRONG BASE — re-point"
```

If the base is wrong and the worktree has no commits of its own, re-point its branch onto the intended base (`git reset --hard <local-base>`), then re-verify.

Branching off the wrong commit is silent — the worktree looks fine and quietly carries the wrong history. This check is the cheap insurance.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

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

git worktree add "$path" -b "$BRANCH_NAME" "${BASE:-$DEF}"   # BASE chosen in Step 0.5
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

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

**Base check first (dev-stack).** Before trusting any baseline, confirm the worktree is founded on the intended commit — run Step 0.5's `git merge-base --is-ancestor "$FOUND" HEAD` check. A wrong base is the most common silent worktree failure: a green test suite on the wrong foundation still ships the wrong history.

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
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
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

## Common Mistakes

### Fighting the harness

- **Problem:** Using `git worktree add` when the platform already provides isolation
- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.

### Skipping detection

- **Problem:** Creating a nested worktree inside an existing one
- **Fix:** Always run Step 0 before creating anything

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: explicit instructions > existing project-local directory > default

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

## Red Flags

**Never:**
- Create a worktree when Step 0 detects existing isolation
- Create a worktree off a non-default branch without asking first (Step 0.5)
- Trust a native worktree tool's default base — it may branch from `origin`, behind your local commits. Verify the base (Step 0.5), don't assume it.
- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
- Skip Step 1a by jumping straight to Step 1b's git commands
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking

**Always:**
- Run Step 0 detection first
- Prefer native tools over git fallback
- Follow directory priority: explicit instructions > existing project-local directory > default
- Verify directory is ignored for project-local
- Auto-detect and run project setup
- Verify clean test baseline
