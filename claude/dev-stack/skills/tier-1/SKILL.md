---
name: tier-1
description: "The Tier 1 driver — one vertical slice, run as a single unit through the engine: a bug fix, a small feature, or a small refactor. Use when the user types /tier-1 already knowing the tier, or when route-me proposes Tier 1 and the user approves. Bug-shaped work (broken, throwing, failing, slow) routes through /diagnose first."
---

<STOP-GATE>
Present the entry and wait for the user's explicit go before touching anything:

- the **task** — what's being fixed or changed, in one line;
- the **tier** — Tier 1, and why it is one vertical slice.

Nothing is planned or handed off until the go is given.

**Satisfied when** `/route-me` reached you — its G1 gate just presented this task and this tier and took the go. Proceed to step 1 without asking again. Typed directly, the gate is live.
</STOP-GATE>

Tier 1 *is* one vertical slice — a narrow but complete path through every layer it touches, ending in behaviour you can observe. This driver shapes the work, gets the plan approved, and hands it to the engine — it writes no code and cuts no worktree itself; `/to-implement` owns isolation and the build.

1. **Shape the work first, if it needs it.**
   - **Bug-shaped** — broken, throwing, failing, slow — run `/diagnose` before any plan. In Tier 1, diagnosis produces *understanding*, not commits: the plan below is the fix it points to, and the fix itself is built in the engine's worktree.

     **Carry its Phase 1 command into the plan as the acceptance.** Diagnosis ends on one red-capable, deterministic, fast, agent-runnable command it has already run — the same four properties the brief's `Verify` gate demands. Naming it in the plan is what stops the brief-writer deriving it again from nothing; the brief-writer still runs it itself in the worktree, because the brief needs its own pasted output.
   - **A small feature** — sharpen it with `/grill`, the lightweight grill that writes no docs (docs are Tier 2's job). It is a conversation; nothing is branched.
2. **GATE IN — the inline plan (G3).** Present the plan in chat and wait for explicit approval. It lives in chat — never an artifact, never a written file.

   A Tier 1 plan **is a ticket that was never written down**, so it carries what a ticket carries, and for the same reason: the brief-writer reads both and cannot work without these:

   - **Observable behaviour** — what works once this lands, and *how you'll observe it*: the command, the screen, the request, the build.
   - **Layers crossed** — the layers this slice cuts through, by their domain names. Names only.
   - **Acceptance** — as end-to-end behaviour, never per layer.
   - **The command that proves it** — for bug-shaped work, `/diagnose`'s Phase 1 command; otherwise the check you'd run.

   Plus **the base commit** the worktree will branch from, named as a commit the user can see. Carrying it here is what lets `/to-implement` branch without a second stop: its gate asks for exactly the plan and the base, so asking twice buys nothing.

   **No file paths.** They belong to the brief, which rebuilds them at pickup against the tree it is about to change; named here they are an anchor the brief-writer may trust instead of looking.
3. **Hand off** — `/to-implement` with input **nothing**: the approved chat plan is the single unit. The engine isolates the worktree and carries the rest — the brief, the build, `/verified-review`, `/finish-branch`.

## When NOT Tier 1

One condition, and only one: **the work turns out to be more than one vertical slice.** The scout's map or the plan itself shows unclear scope (you cannot count the slices) or a blast radius wide enough that no single slice lands green. Escalate to `/tier-2` rather than stretching the inline plan.

New domain vocabulary is **not** an escalation. It raises `/domain-modeling` alongside this tier — a glossary entry or an ADR committed straight to the default branch — and the slice stays Tier 1. Same for a repo with no `CONTEXT.md` yet.

**Related:** `/route-me` proposes the tier from evidence · `/to-implement` is the engine that isolates and builds · `/grill` sharpens a small feature · `/diagnose` for bug-shaped work · `/tier-2` is the escalation
