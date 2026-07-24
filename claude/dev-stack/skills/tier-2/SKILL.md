---
name: tier-2
description: The Tier 2 driver — a feature too large for one execution, driven through the planning chain (grill, spec, tickets, cold read) with a pause at every phase gate, then built as several Tier 1 units, one ticket at a time. Use when the user types /tier-2 already knowing the tier, or when route-me proposes Tier 2 and the user approves.
---

<STOP-GATE>
Present the entry and wait for the user's explicit go before starting any phase:

- the **feature** — what's being built, in one or two lines;
- the **open decisions** — the scout's list when one was provided, one line each; otherwise "none surfaced".

No phase starts until the go is given.
</STOP-GATE>

Tier 2 is planning, then several Tier 1 runs: the chain below produces the spec and the tickets, and each ticket is then built as its own Tier 1 — one `/to-implement` per fresh chat. Tier 2 splits and records; it builds no code itself.

## Preflight — the tracker, asked once

Check `docs/agents/issue-tracker.md`. Present → the chain reads it silently. Missing → ask the user **once** where specs and tickets live for this repo — a real tracker (GitHub, GitLab, Linear, …) or local markdown under `.scratch/` — and record the answer in `docs/agents/issue-tracker.md`, so nothing downstream (`/decision-map`, `/to-spec`, `/to-tickets`) asks again.

## The chain

Each phase is a reference; its skill owns the content.

1. `[/decision-map ⏸]` — only when the open decisions exceed one grill session; the fog clears into the grill.
2. `/grill-me` — the grill + docs composition; agenda pre-seeded from the scout's open decisions when available. `CONTEXT.md` and ADRs are committed **straight to the default branch** as the session goes — domain knowledge belongs on the main line, and `branch-guard` passes those paths.
3. `/to-spec` ⏸ — the spec, approved by the user.
4. `/to-tickets` ⏸ — the tickets, approved by the user.
5. `/cold-read` — once per feature, before any implementation.
6. **Build the tickets** — each is its own Tier 1: run `/to-implement` on one ticket, in a fresh chat, in dependency order (blockers first). The loop over tickets is the user's; Tier 2 hands them over, it does not orchestrate them.

## No feature branch

There is no hub. The domain docs live on the default branch from the grill onward; each ticket's `/to-implement` cuts its worktree from the default branch and `/finish-branch` merges it back. A dependent ticket already sees its blockers — they are merged code on the default branch, not paper from another ticket. The contract is the code in the tree.

## The driver contract

The driver sequences and pauses through planning; the phases' skills own their content. The chain is drivable entirely by hand — `/grill-me` → `/to-spec` → `/to-tickets` → `/to-implement` per ticket — the driver is a convenience, never a requirement.

**Related:** `/route-me` proposes the tier from evidence · `/tier-1` for work that fits one execution · `/to-implement` builds each ticket · `/decision-map` clears heavy fog first
