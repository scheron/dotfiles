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

It returns three things:

```
1. map of the code   where it lives, how far it spreads, what constrains it
2. the tier test     the five questions below, answered against the code
3. open decisions    the questions the code cannot answer — those are the user's
```

The scout **measures**; it never resolves. Facts are looked up, decisions are put to the user. The open-decision list does double duty: a handful (fit one grill session) pre-seed the grill's agenda; more than a session's worth is the signal to propose `/decision-map` first.

## The tier test

One question underneath all the others: **is this one execution, or does it have to be split first?** Tier 1 is a single execution; Tier 2 grills, specs, and splits the work into tickets that each run as a Tier 1. Answer these against the scout's map:

```
1. Is the scope clear?                        unclear → Tier 2
2. How wide is the blast radius?              wide    → Tier 2
3. Does it introduce new domain vocabulary?   yes     → Tier 2   (CONTEXT.md / ADRs)
4. Does one inline context window suffice?    no      → Tier 2
5. Does a CONTEXT.md exist yet?               no      → Tier 2   (Tier 2 establishes it)
```

Every answer pointing small / clear / contained → **Tier 1**; any one pushing the other way → **Tier 2**. Tier 1 is not only bug fixes — a small feature or a small refactor is Tier 1 when it clears the test. route-me only *proposes* the tier; at the gate the user can override it for a genuinely trivial change.

## Routing

The tier test picks the driver. route-me proposes it, waits at the gate above, then hands off.

- **Tier 1** — clears the test → propose `/tier-1`. Bug-shaped work runs `/diagnose` first; a small feature can grill with `/grill` (no docs).
- **Tier 2** — anything that fails the test → propose `/tier-2`.
- **Open decisions exceed one grill session** → propose `/decision-map` first; it burns the fog down to ADRs and feeds back into `/tier-2`.

route-me drives nothing further — the driver owns its own chain and opens with its own STOP-gate.

## The map

Two tiers, one engine. Both feed `/to-implement`; Tier 2 is several Tier 1 runs, one ticket at a time.

```
/route-me     scout → "Tier N because …; open decisions …; launch /tier-N?" ⏸
/tier-1       [ /diagnose if bug ]  ·  [ /grill if a small feature ]
              → plan inline ⏸ → /to-implement   (the chat plan, one unit)
/tier-2       [ /decision-map ⏸  when the scout's fog exceeds one grill session ]
              → /grill-me   (grill + docs: CONTEXT.md and ADRs committed as it goes)
              → /to-spec ⏸ → /to-tickets ⏸ → /cold-read
              → /to-implement   (one ticket per fresh chat)
/to-implement   THE ENGINE — one unit: a plan, a task, a spec, or one ticket
```

**The drivers are a convenience, never a requirement.** Drive the classic chain by hand and skip them: `/grill-me` → `/to-spec` → `/to-tickets` → `/to-implement`, one ticket at a time into the engine.

## Gates — plan in, review out

Both tiers are gated at the same two points; the tier scales the process between them, never the bar.

- **Plan in.** No code before an approved plan. Tier 1: a few lines inline in chat — what changes, which files, how you'll verify (never an artifact). Tier 2: the spec and the tickets, each approved at its phase gate.
- **Review out.** No unit closes until `/verified-review` passes — the reviewer runs Verify itself (green now, red-at-pickup on file in the brief) and drives the real runtime. A one-line fix meets the same bar as a Tier 2 ticket.

No tier works on the default branch — every unit isolates in a worktree (`/using-git-worktrees`). The contract is enforced, not advised: `branch-guard` denies edits on `main`/`master`, `review-guard` blocks unreviewed wrap-up, and every driver opens with a STOP-gate. Text gates steer; hooks enforce.

## Cheat sheet

| Command | When |
|---|---|
| `/route-me` | unsure which tier or flow fits — scout and route |
| `/tier-1` | you already know it's small work that fits one execution now |
| `/tier-2` | you already know it's a feature — grill, spec, split into tickets |
| `/diagnose` | something broke, throws, fails, or went slow |
| `/grill` | lightweight grill — stress-test a plan or decision, no docs written |
| `/grill-me` | feature grill against a codebase — grill + docs (CONTEXT.md, ADRs) |
| `/decision-map` | open decisions exceed one grill session |
| `/to-spec` | the conversation has settled |
| `/to-tickets` | the spec is ready and the work spans sessions |
| `/cold-read` | tickets are ready — one cold read before implementation |
| `/to-implement` | build one unit — a plan, a task, a spec, or one ticket |
| `/verified-review` | close a unit, a branch, or a PR |
| `/finish-branch` | everything green — integrate |
| `/tdd` | build one behaviour test-first |
| `/using-git-worktrees` | isolate before any tier's work — Tier 1 included |
| `/prototype` | a question needs a runnable answer |
| `/research` | need an external fact |
| `/handoff` | context running out — hand to a fresh session |
| `/improve-codebase-architecture` | a finding arrived, or no Verify command exists |
| `/commit-work` | craft and split commits |
| `/setup-pre-commit` | add Husky + lint-staged hooks |
| `/git-guardrails-claude-code` | block destructive git commands |
| `/writing-great-skills` | writing or editing a skill |

The **internal five** — `/brief`, `/codebase-design`, `/domain-modeling`, `/resolving-merge-conflicts`, `/receiving-code-review` — are not in the menu; a driver or the model raises them in context.
