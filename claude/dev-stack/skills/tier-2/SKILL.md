---
name: tier-2
description: The Tier 2 driver — a feature that doesn't fit an inline solution, driven through the full chain (grill, spec, tickets, cold read, engine) with a pause at every phase gate. Use when the user types /tier-2 already knowing the tier, or when route-me proposes Tier 2 and the user approves.
---

<STOP-GATE>
Present the entry and wait for the user's explicit go before starting any phase:

- the **feature** — what's being built, in one or two lines;
- the **open decisions** — the scout's list when one was provided, one line each; otherwise "none surfaced".

No phase starts until the go is given.
</STOP-GATE>

Tier 2 is orchestration over Tier 1 runs (STACK.md §1): the chain below produces tickets, then the engine runs each as a Tier 1 lifecycle in its own worktree.

## Preflight — the tracker, asked once

Check `docs/agents/issue-tracker.md`. Present → the chain reads it silently. Missing → ask the user **once** where specs and tickets live for this repo — a real tracker (GitHub, GitLab, Linear, …) or local markdown under `.scratch/` — and record the answer in `docs/agents/issue-tracker.md`, so nothing downstream (`/decision-map`, `/to-spec`, `/to-tickets`, the engine) asks again.

## The chain

Each phase is a reference; its skill owns the content.

1. `[/decision-map ⏸]` — only when the open decisions exceed one grill session; the fog clears into the grill.
2. `/grill-with-docs` — the grill composition home; agenda pre-seeded from the scout's open decisions when available; CONTEXT.md and ADRs committed to the branch as the session goes.
3. `/to-spec` ⏸ — the spec, approved by the user.
4. `/to-tickets` ⏸ — the tickets, approved by the user.
5. `/cold-read` — once per feature, before any implementation.
6. `/to-implementation` over the tickets — the engine's own STOP-gate presents the units, the batch, and the launch point; from there the engine holds every remaining pause through integration.

**Isolation.** The feature branch (the hub) is cut via `/using-git-worktrees` *before* the grill's outputs are committed — CONTEXT.md, ADRs, and the spec land on the hub, never on the default branch.

## The driver contract

The driver sequences and pauses; the phases' skills own their content. The chain is drivable entirely by hand — `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/to-implementation` — the driver is a convenience, never a requirement.

**Related:** `/route-me` proposes the tier from evidence · `/tier-1` for work that fits inline · `/to-implementation` is the engine
