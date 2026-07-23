---
name: new-branch
description: Fallback isolation when a worktree can't be made — cut a dedicated branch in place. The primary path for every tier (Tier 1 included) is /using-git-worktrees; reach here only when a worktree is impossible (sandbox denial) or declined. Runs scripts/new-branch.sh.
---

# New Branch

The **isolation fallback**: never work on the default branch, and when a worktree can't be made, cut a dedicated `<type>/<slug>` branch in place instead. The primary path for every tier — Tier 1 fixes included, so a batch runs in parallel — is `/using-git-worktrees`. Reach here only when a worktree is impossible (sandbox denial) or the user declined one.

<HARD-GATE>
Tier 1 is bracketed by two gates — even a one-line fix gets both. **In:** before you branch AND before you edit, the plan must already be presented and approved (a few lines in chat and a "go"; nothing gets built off an unapproved plan). **Out:** the fix is not done until `/verified-review` has run — the reviewer runs Verify itself. Approved in, reviewed out.
</HARD-GATE>

## Confirm the branch origin first

Before cutting the branch, check where you are — branching off the wrong base is silent and expensive:

- **On the default branch** — cut the branch off it, as normal.
- **Not on the default** — STOP and ask: *"You're on `<cur>`, not `<def>`. Branch from here, or switch to `<def>` first?"* The script **refuses** in this case unless you pass `--from-here`, so ask the user before you do.

## Run

```
${CLAUDE_PLUGIN_ROOT}/scripts/new-branch.sh <type> <slug> [--from-here]
```

If `$CLAUDE_PLUGIN_ROOT` is unset in this context, the inline equivalent is:

```
git switch -c <type>/<slug>   # off the default branch — confirm the origin first
```

- `type` — `fix` for a bug, `feat`/`chore`/`refactor` as the routed task fits. Default `chore`.
- `slug` — a short kebab description of the work; the script sanitises it.
- `--from-here` — branch off the current branch instead of refusing when it isn't the default. Only after the user has said so.

Name from the routed task: a crash → `fix/<slug>`, a small addition → `feat/<slug>`.

## Why a script and a guard, not a reminder

A `branch-guard` PreToolUse hook denies file edits and commits on the default branch in any repo carrying a `.branch-guard` marker. **The obligation lives in the hook** — this skill is the clean path the guard points you to. Text alone would be skippable; the guard is not. (The plan-approval gate above can't be mechanically enforced the same way — no marker to check — so it lives as text; the branch-origin ask is backed by the script's refusal.)
