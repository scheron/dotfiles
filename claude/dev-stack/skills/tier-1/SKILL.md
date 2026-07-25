---
name: tier-1
description: "The Tier 1 driver — small work that fits one execution now: a bug fix, a small feature, or a small refactor, run as a single unit through the engine. Use when the user types /tier-1 already knowing the tier, or when route-me proposes Tier 1 and the user approves. Bug-shaped work (broken, throwing, failing, slow) routes through /diagnose first."
---

<STOP-GATE>
Present the entry and wait for the user's explicit go before touching anything:

- the **task** — what's being fixed or changed, in one line;
- the **tier** — Tier 1, and why it fits one execution now.

Nothing is planned or handed off until the go is given.
</STOP-GATE>

Tier 1 *is* the execution of one unit. This driver shapes the work, gets the plan approved, and hands it to the engine — it writes no code and cuts no worktree itself; `/to-implement` owns isolation and the build.

1. **Shape the work first, if it needs it.**
   - **Bug-shaped** — broken, throwing, failing, slow — run `/diagnose` before any plan. In Tier 1, diagnosis produces *understanding*, not commits: the plan below is the fix it points to, and the fix itself is built in the engine's worktree.
   - **A small feature** — sharpen it with `/grill`, the lightweight grill that writes no docs (docs are Tier 2's job). It is a conversation; nothing is branched.
2. **GATE IN — the inline plan.** Present the plan in chat, a few lines: what changes, which files, how to verify. Wait for the explicit approval. The plan lives in chat — never an artifact, never a written file.
3. **Hand off** — `/to-implement` with input **nothing**: the approved chat plan is the single unit. The engine isolates the worktree and carries the rest — the brief, the build, the sweep, `/verified-review`, `/finish-branch`.

## When NOT Tier 1

The scout's map or the plan itself reveals unclear scope, a wide blast radius, new domain vocabulary, or more than one context window of work — or the repo has no `CONTEXT.md` yet. Escalate to `/tier-2` rather than stretching the inline plan.

**Related:** `/route-me` proposes the tier from evidence · `/to-implement` is the engine that isolates and builds · `/grill` sharpens a small feature · `/diagnose` for bug-shaped work · `/tier-2` is the escalation
