---
name: new-branch
description: Create a dedicated working branch before any Tier 1 work — right after routing picks Tier 1 (a fix or small change), or whenever edits must start off the default branch. Runs scripts/new-branch.sh.
---

# New Branch

The **Tier 1 isolation floor**: never work on the default branch. This skill cuts `<type>/<slug>` off the default branch so a fix lives on its own branch, then hands back to the tier chain.

Tier 2/3 use `/using-git-worktrees` instead — a worktree already carries its own branch, so it satisfies the same floor.

## Run

```
${CLAUDE_PLUGIN_ROOT}/scripts/new-branch.sh <type> <slug>
```

If `$CLAUDE_PLUGIN_ROOT` is unset in this context, the inline equivalent is:

```
git switch -c <type>/<slug>   # off the default branch
```

- `type` — `fix` for a bug, `feat`/`chore`/`refactor` as the routed task fits. Default `chore`.
- `slug` — a short kebab description of the work; the script sanitises it.

Name from the routed task: a crash → `fix/<slug>`, a small addition → `feat/<slug>`.

## Why a script and a guard, not a reminder

A `branch-guard` PreToolUse hook denies file edits and commits on the default branch in any repo carrying a `.branch-guard` marker. **The obligation lives in the hook** — this skill is the clean path the guard points you to. Text alone would be skippable; the guard is not.
