---
name: route-me
description: The entry point to the dev-stack — scouts a task read-only, proposes one of two tiers from the evidence, and routes into a driver behind your go. Use when unsure which tier or flow fits a task, or type /route-me any time to reprint the map and cheat sheet.
---

# Route Me

<STOP-GATE>
route-me's first act is the **scout** — read-only, cheap, safe to run *before* this gate. Dispatch it, then gate on what it found:

- present the proposal — **"Tier N because <reason>; open decisions: <list>; launch /tier-N?"** — and wait for the explicit go;
- launch nothing until the go. route-me proposes and hands off — it drives no chain itself.
</STOP-GATE>

## The scout — you can't tier from the armchair

Before any tier talk, dispatch a **read-only Explore agent** scoped to the task, on the current branch (read-only, so no branch is cut yet). You cannot honestly pick a tier from the armchair: until you look at the code, a "simple change" is a Tier 2 once you see how far it spreads, and a "feature" is a one-line fix. Mis-tiering is the expensive mistake; a scout is cheap. Keep the conclusion, not the file dumps.

It returns four things:

```
1. map of the code    where it lives, how far it spreads, what constrains it
2. slice count        how many vertical slices this is — the tier test below
3. subsystem check    is this one feature, or several independent ones?
4. open decisions     the questions the code cannot answer — those are the user's
```

The scout **measures**; it never resolves. Facts are looked up, decisions are put to the user. The open-decision list does double duty: a handful (fit one grill session) pre-seed the grill's agenda; more than a session's worth is the signal to propose `/decision-map` first.

**The subsystem check comes first.** If the task describes several independent subsystems — chat *and* file storage *and* billing — say so immediately and propose decomposing before anything else. A spec covering four subsystems yields tickets that are vertical slices of nothing coherent, and no amount of careful grilling downstream repairs that.

## The tier test — one question

> **How many vertical slices is this? One → Tier 1. More than one → Tier 2.**

A **vertical slice** cuts a narrow but complete path through every layer it touches, and ends in behaviour you can observe — run a command, open a browser, send a request, build the app. Tier 1 is exactly one such slice. Tier 2 is a spec that spans sessions, cut into several.

The spec exists to hold slices together across sessions; on a single slice it has nothing to hold.

Two readings of the code answer the question — neither is a separate test:

```
Is the scope clear?          unclear → you cannot count slices → more than one
How wide is the blast radius? wide   → no single slice lands green → more than one
                                       (a wide refactor sequences as expand–contract:
                                        several tickets, never one)
```

route-me only *proposes* the tier; at the gate the user can override it.

## The second axis — domain docs, on either tier

Two more facts the scout reports, and they decide something **other** than the tier:

```
Does it introduce new domain vocabulary?   yes → /domain-modeling rides along
Does a CONTEXT.md exist yet?               no  → /domain-modeling rides along
```

Either one raises `/domain-modeling` — `CONTEXT.md` and ADRs, committed straight to the default branch (`branch-guard` passes those paths). **On either tier.** One slice that introduces one new term is Tier 1 plus a glossary entry; it does not buy a spec, a ticket breakdown, and a cold read to record one word.

## Routing

The tier test picks the driver. route-me proposes it, waits at the gate above, then hands off.

- **Tier 1** — clears the test → propose `/tier-1`. Bug-shaped work runs `/diagnose` first; a small feature can grill with `/grill` (no docs).
- **Tier 2** — anything that fails the test → propose `/tier-2`.
- **Open decisions exceed one grill session** → propose `/decision-map` first; it burns the fog down to ADRs and feeds back into `/tier-2`.

route-me drives nothing further — the driver owns its own chain and opens with its own STOP-gate.

## The map

This is the map's single home — nothing else in the stack carries a copy. `⏸` is a stop that waits for the user; `↻` is a conversation, not a gate.

```
/route-me   scout: code map · SLICE COUNT · subsystem check · open decisions
   └─ ⏸ G1  "Tier N because …; open decisions …; launch /tier-N?"
        │
        ├─ ONE SLICE → /tier-1
        │    ├─ [bug]     /diagnose      → its red-capable command becomes the acceptance
        │    ├─ [feature] /grill ↻       (2-3 approaches with trade-offs)
        │    └─ ⏸ G3  the plan + the base commit        → /to-implement
        │
        └─ MORE THAN ONE → /tier-2
             ├─ preflight issue-tracker.md              (only if unconfigured)
             ├─ [fog > one grill session] /decision-map ⏸
             ├─ /grill-me ↻                             (sections, with /domain-modeling)
             ├─ /to-spec      ⏸ seams · self-review · ⏸ G5 the spec
             ├─ /to-tickets   ⏸ G6 "does this ticket run unattended?"
             └─ /cold-read                              (required, no gate)
                  → /to-implement, one ticket per fresh chat
                  → or /autopilot <batch> for the set, unattended ⏸

second axis, either tier: new domain vocabulary, or no CONTEXT.md yet
                          → /domain-modeling rides along (CONTEXT.md, ADRs)
```

Stops: **two** on Tier 1 (G1, G3), five or six on Tier 2. The bar never moves — only the asking.

**The drivers are a convenience, never a requirement.** Drive the chain by hand and skip them: `/grill-me` → `/to-spec` → `/to-tickets` → `/to-implement`, one ticket at a time into the engine. Typed directly, each of those opens its own gate; reached from a driver, that gate is already satisfied.

## Gates — plan in, review out

Both tiers are gated at the same two points; the tier scales the process between them, never the bar.

- **Plan in.** No code before an approved plan. Tier 1: a few lines inline in chat — the observable behaviour and how you'll observe it (never an artifact, never file paths). Tier 2: the spec and the tickets, each approved at its phase gate.
- **Review out.** No unit closes until `/verified-review` passes — the reviewer runs Verify itself (green now, red-at-pickup on file in the brief) and drives the real runtime. A one-line fix meets the same bar as a Tier 2 ticket.

No tier works on the default branch — every unit isolates in a worktree (`/using-git-worktrees`). The contract is enforced, not advised: `branch-guard` denies edits on `main`/`master`, `review-guard` blocks unreviewed wrap-up. Text gates steer; hooks enforce.

## Cheat sheet

Routing a task:

| Command | When |
|---|---|
| `/route-me` | unsure which tier or flow fits — scout and route |
| `/tier-1` | you already know it's one vertical slice |
| `/tier-2` | you already know it's several — grill, spec, split into tickets |
| `/diagnose` | something broke, throws, fails, or went slow |
| `/to-implement` | build one unit — a plan, a task, a spec, or one ticket |
| `/autopilot` | run a batch of cut tickets unattended |

Everything else is raised by a driver when the moment arrives — `/grill`, `/grill-me`, `/decision-map`, `/to-spec`, `/to-tickets`, `/cold-read`, `/verified-review`, `/finish-branch`, `/tdd`, `/using-git-worktrees`, `/domain-modeling` — and can also be typed by hand. Reach for the rest directly when you already know what you want: `/prototype` for a runnable answer, `/research` for an external fact, `/handoff` when context runs out, `/improve-codebase-architecture` when a finding arrives or no Verify command exists, `/commit-work`, `/setup-pre-commit`, `/git-guardrails-claude-code`, `/writing-great-skills`.

The **internal five** — `/brief`, `/codebase-design`, `/domain-modeling`, `/resolving-merge-conflicts`, `/receiving-code-review` — are not in the slash menu; a driver or the model raises them in context.
