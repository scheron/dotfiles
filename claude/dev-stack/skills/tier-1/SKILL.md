---
name: tier-1
description: The Tier 1 driver — a fix or small change that fits an inline solution right now, run as one unit through the engine. Use when the user types /tier-1 already knowing the tier, or when route-me proposes Tier 1 and the user approves. Bug-shaped work (broken, throwing, failing, slow) routes through /diagnose first.
---

<STOP-GATE>
Present the entry and wait for the user's explicit go before touching anything:

- the **task** — what's being fixed or changed, in one line;
- the **tier** — Tier 1, and why it fits an inline solution right now.

Nothing is branched, planned, or edited until the go is given.
</STOP-GATE>

Tier 1 *is* the execution of one unit (STACK.md §1). This driver sequences the references below and writes no code itself — the engine's lifecycle is the body of Tier 1.

1. **Isolate** — `/using-git-worktrees`, Tier 1 included. The unit's worktree, branched from the default branch, *is* the hub (the engine's Tier 1 topology): no separate feature branch, integration goes straight through `/finish-branch`.
2. **Bug-shaped? `/diagnose` first.** Broken, throwing, failing, or slow work runs the diagnosis loop before any plan — the plan below is the fix its diagnosis produces.
3. **GATE IN — the inline plan.** Present the plan in chat, a few lines: what changes, which files, how to verify. Wait for the explicit approval. The plan lives in chat — never an artifact, never a written file (STACK.md §1).
4. **Hand off** — `/to-implementation` with input **nothing**: the approved chat plan is the single unit. The engine carries the rest — implementation, the test-runner sweep, `/verified-review`, `/finish-branch`.

## When NOT Tier 1

The scout's map or the plan itself reveals multi-file spread, or decisions the user hasn't made — escalate to `/tier-2` rather than stretching the inline plan.

**Related:** `/route-me` proposes the tier from evidence · `/to-implementation` is the engine · `/tier-2` is the escalation
