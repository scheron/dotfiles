---
name: route-me
disable-model-invocation: true
description: Router over the dev-stack skills — names each skill and when to reach for it. Type /route-me when unsure which skill or flow fits the situation.
---

# Route Me

The map of this skill set: pick a **tier**, then follow its chain. This skill only routes — each skill it names carries its own detail, and STACK.md carries the *why*.

<HARD-GATE>
No tier writes code before its gate is cleared — and the gate is **presented and approved**, not just thought through. Tier 1: a plan inline in this session, approved. Tier 2: the spec + tickets chain, approved. Tier 3: the wayfinder map. Dropping to a lighter tier to dodge a heavier gate is the one failure this whole map exists to prevent — the tier is set by what the *code* demands, never by what's convenient. "Too small to plan" is exactly where a wrong assumption costs the most.
</HARD-GATE>

**Before any tier — open a TodoWrite plan.** Every change, down to a one-line fix, starts by naming its steps in TodoWrite. This is not ceremony and it is not optional: an explicit plan is how the model holds the whole change in view and stops dropping steps. The tier decides how much *process* rides on top — spec, tickets, `.scratch/` — never whether you plan. If the session doesn't expose TodoWrite, track the same steps inline in text; the plan is the obligation, the tool is just where it lives. TodoWrite is your *own* tracking — it is **not** the plan the user approves at the gate above; presenting the plan and getting a "go" is a separate, non-skippable step.

## Step 0 — scout first (you can't tier without it)

You cannot honestly pick a tier from the armchair — until you look at the code, a "simple bug" is a Tier 2 once you see how far it spreads, and a "feature" is a one-line fix. So **always** dispatch a clean, read-only scout *before* tiering:

- Send an **Explore** agent scoped to the task: where does this live, how far does it spread, what patterns must it match, what constrains it.
- It returns a distilled map **and a tier signal** — localized / one file → Tier 1; multi-file, one–two sessions → Tier 2; shape unclear, decisions needed → Tier 3.
- Read-only, so it runs on the current branch, *before* you cut one. Keep the conclusion, not the file dumps.

Never skip the scout to "save time": mis-tiering is the expensive mistake, a scout is cheap. It is the first thing route-me does — step one of the flow, always.

## Step 1 — pick the tier

```
                        what happened?
                              │
        ┌─────────────────────┼─────────────────────┐
   something broken       you know what          the shape of the
   / slow                 to build               work is unclear
        │                     │                     │
     TIER 1                TIER 2                TIER 3
      FIX                 FEATURE                EFFORT
   minutes–hour        one–two sessions      won't fit one session
```

**Then isolate — before any edit.** The moment the tier is picked, move into an isolated worktree via `/using-git-worktrees` — **every** tier, Tier 1 included, so a batch of simple fixes can run in parallel without fighting over one working copy. `/new-branch` (a dedicated branch in place) is the fallback for when a worktree can't be made — sandbox denial, or you decline one. **Before either branches it checks where you are:** off the default branch it stops and asks whether to branch from here or switch to the default first — branching off the wrong base is silent and expensive. In a dev-stack repo a `branch-guard` hook denies edits and commits on `main`/`master`, so isolation is enforced, not advised.

### Tier 1 — FIX

<HARD-GATE>
Tier 1 is still gated. Before you edit a single line — present the plan inline, in this session, and wait for the user's explicit "go". This holds no matter how trivial the fix looks: "too small to plan" is exactly where a wrong assumption costs the most. Lightweight means lightweight — a few lines in chat (what changes, which files, how you'll verify), NOT a spec, NOT a `.scratch/` doc, NOT an artifact, NOT a written file. TodoWrite is your own tracking, not the plan the user approves. Touch code only after the user says go.
</HARD-GATE>

```
routed to Tier 1        ──►  /using-git-worktrees  (isolate; /new-branch = fallback)
plan                    ──►  present inline → get approval  (before any edit)
bug / throwing / slow   ──►  /diagnose
small change            ──►  work the approved plan
                        ──►  /verified-review
```

No spec, no tickets, no `.scratch/` — but the plan is presented and approved before any edit, and every fix gets its own worktree, so a batch of them runs in parallel.

<HARD-GATE>
Tier 1 is gated at the *exit* too — even a one-line fix. It is not done until `/verified-review` has run: the reviewer runs the Verify command **itself** (red before, green after) and checks the Standards + Spec axes. "It's small, I'll eyeball it" is not review. Do not report the fix complete until the review has run and its findings are addressed.
</HARD-GATE>

### Tier 3 — EFFORT

```
/wayfinder ──►  a map of decision-tickets (prototype / grilling / task)
                1 ticket = 1 session
                research tickets burned down by /research subagents in parallel
                each decision ──► an ADR
                each resolved ticket ──► drops into Tier 2
```

## Tier 2 — the full chain

One unbroken context up to the tickets; then clear and execute.

```
/grill-with-docs        = /grilling + /domain-modeling at once
  one question at a time, facts looked up, decisions are yours
  CONTEXT.md and ADRs written inline
      │  need a runnable answer? → /handoff → new session → /prototype → /handoff back
      ▼  GATE 1 — shared understanding?

seams + verify           "cut here, prove it with this"
      ▼  GATE 2 — nothing to verify with? that's a FINDING, not "I'll check by hand"

/to-spec                 Problem / Solution / User Stories / Implementation
  carries Global Constraints. NO paths, NO code
      ▼  GATE 3 — proofread

/to-tickets              vertical tracer bullets + blocking edges. NO paths, NO code
      ▼  quiz: granularity and edges

/cold-read               ONCE per feature — a cold session reads spec+tickets,
  reports what it understood; you check against what you meant. Fixing is free.
      │
   ═══ CLEAR CONTEXT ═══
      │
/execute-tickets         loop the frontier (all blockers closed):
  ├ /brief           JIT, only now — Explore walks the code →
  │                  .scratch/<feature>/brief-NN.md (Files/Interfaces/Verify/Run as)
  ├ implementer      inline | cheap | standard — runs /tdd on agreed seams
  └ /verified-review 1. runs Verify itself (gate) 2. Standards ∥ Spec subagents
      │                                        → line in ledger.md → next ticket
      ▼
/verified-review over the whole branch (fixed point = merge-base, strongest model)
      ▼
/finish-branch           1. HARVEST (decisions→ADR, terms→CONTEXT.md,
                            commands→AGENTS.md, findings→issue)  ◄── before teardown
                         2. Verify  3. merge/PR/keep/discard  4. tear down .scratch/
```

## How to drive a tier

A tier is a **decision, not a command** — there is no `/tier-1`. Every flow opens with a read-only **scout** (Step 0) — that's what tells you the tier — then you cut a branch and walk that tier's chain. What you actually type are the skills in the chain.

The **driving** skills are user-only by design (`disable-model-invocation`) — the model never starts a grill, a spec, or a ticket cut on its own; the wheel stays in your hand. The rest auto-invoke: `/diagnose` fires the moment you report a bug (Matt's default — kept open), and a driver raises `/brief` and `/verified-review` inside the loop.

```
you type:       /route-me /grill-with-docs /to-spec /to-tickets
                /cold-read /execute-tickets /wayfinder
auto-invokes:   /diagnose (on a bug report)  ·  /brief /verified-review
                /finish-branch (raised inside /execute-tickets)
```

So you memorise **one** command — `/route-me` — and it reprints the map and cheat sheet whenever you're lost. Then per tier:

```
Tier 1   plan inline + approval → work (bug? /diagnose fires) → /verified-review
Tier 2   front by hand:         /grill-with-docs → /to-spec → /to-tickets → /cold-read
         then ONE driver:       /execute-tickets loops the frontier
                                 (brief → implementer → verified-review → next)
Tier 3   start with the map:    /wayfinder → each resolved ticket drops into Tier 2
```

Remember `/route-me` + your tier's entry (`/diagnose`, `/grill-with-docs`, or `/wayfinder`). The map and the driver carry the rest — the full chain is never yours to memorise.

## Definition of Done

**Every tier — Tier 1 included — a change is not done until `/verified-review` has run.** There is no "too small to review"; a one-line fix meets the same bar as a Tier 2 ticket.

```
Verify green    red BEFORE, green AFTER — the reviewer ran it
spec axis       matches the ticket
standards axis  matches the repo's conventions

discrepancy with the implementer's report  = a FINDING (the report is not evidence)
no Verify command exists                    = a FINDING → /improve-codebase-architecture
                                              never "verify manually"
```

## Cheat sheet

| Command | When |
|---|---|
| `/grill-with-docs` | start of any feature against a codebase |
| `/grilling` | grill with no codebase in play |
| `/prototype` | a question needs a runnable answer |
| `/handoff` | context is running out, need a fresh session |
| `/to-spec` | the conversation has settled |
| `/to-tickets` | spec is ready, the work spans sessions |
| `/cold-read` | tickets are ready and the grill was long |
| `/brief` | taking one specific ticket into work |
| `/execute-tickets` | drive the whole frontier this session |
| `/tdd` | build one behaviour test-first |
| `/verified-review` | after a ticket, a branch, a PR |
| `/finish-branch` | everything green, time to integrate |
| `/using-git-worktrees` | isolate before any tier's work — Tier 1 included |
| `/new-branch` | worktree fallback — a dedicated branch in place |
| `/diagnose` | something broke or went slow |
| `/wayfinder` | the shape of the work is unclear, need a map |
| `/improve-codebase-architecture` | a finding arrived |
| `/codebase-design` | designing a module's interface |
| `/domain-modeling` | a term drifted, a decision wants an ADR |
| `/research` | need an external fact |
| `/receiving-code-review` | before acting on review feedback |
| `/resolving-merge-conflicts` | mid-merge/rebase conflict |
| `/setup-matt-pocock-skills` | new repo: configure tracker + docs/agents/ |
| `/setup-pre-commit` | add Husky + lint-staged hooks |
| `/git-guardrails-claude-code` | block destructive git commands |
| `/writing-great-skills` | writing or editing a skill |

## When something goes wrong

**Implementer returned `NEEDS_CONTEXT`** — the brief fell short. Supply what's missing, re-dispatch, **and fix `/brief`'s output for the next ticket**. The same gap twice is a brief bug, not an implementer bug.

**Implementer returned `BLOCKED` three times** — the ticket is sliced wrong. Don't dispatch a fourth; go back to `/to-tickets`.

**`/brief` can't name a Verify command** — a finding, not grounds for "verify manually". `/improve-codebase-architecture`.

**Three fixes in a row failed in `/diagnose`** — the breaker. Stop; the system model is wrong, and further attempts are guesses dressed as iteration.

**Context near ~120k before `/to-tickets`** — don't push on a degraded window. `/handoff` and a fresh session.

**Session died after compaction** — `ledger.md` survived. Tickets marked complete there are done (`git log` confirms). Don't re-dispatch them.

**`/cold-read` understood the wrong thing** — it's right, you're not. The artifact permitted the reading; the implementer will read it the same way. Fix the artifact.
