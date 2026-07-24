---
name: route-me
description: The entry point to the dev-stack — scouts a task read-only, proposes one of two tiers from the evidence, and routes into a driver behind your go. Use when unsure which tier or flow fits a task, or type /route-me any time to reprint the map and cheat sheet.
---

# Route Me

The entry point. route-me scouts the task read-only, proposes a tier from what the code shows, and hands the wheel to a driver — it launches nothing on its own. Each skill it names carries its own detail; STACK.md carries the *why*.

<STOP-GATE>
route-me's first act is the **scout** — read-only, cheap, safe to run *before* this gate. Dispatch it, then gate on what it found:

- present the proposal — **"Tier N because <reason>; open decisions: <list>; launch /tier-N?"** — and wait for the explicit go;
- launch nothing until the go. route-me proposes and hands off — it drives no chain itself.
</STOP-GATE>

## The scout — you can't tier from the armchair

Before any tier talk, dispatch a **read-only Explore agent** scoped to the task, on the current branch (read-only, so no branch is cut yet). You cannot honestly pick a tier from the armchair: until you look at the code, a "simple bug" is a Tier 2 once you see how far it spreads, and a "feature" is a one-line fix. Mis-tiering is the expensive mistake; a scout is cheap. Keep the conclusion, not the file dumps.

It returns three things (STACK.md §2):

```
1. map of the code   where it lives, how far it spreads, what constrains it
2. tier signal       "does this fit an inline solution right now?"  yes → Tier 1 · no → Tier 2
3. open decisions    the questions the code cannot answer — those are the user's
```

The scout **measures** the fog; it never resolves it — facts are looked up, decisions are put to the user. The third output does double duty: a handful of decisions (fit one grill session) pre-seed the grill's agenda; more than a session's worth is the signal to propose `/decision-map` first.

## Routing

The scout's tier signal picks the driver. route-me proposes it, waits at the gate above, then hands off.

- **Tier 1** — fits an inline solution now → propose `/tier-1`.
- **Tier 2** — everything else → propose `/tier-2`.
- **Open decisions exceed one grill session** → propose `/decision-map` first; it burns the fog down to ADRs and feeds back into `/tier-2`.

route-me drives nothing further — the driver owns its own chain and opens with its own STOP-gate.

## The map

Two tiers, one engine. The tier is the scout's call, never the armchair's.

```
/route-me     scout → "Tier N because …; open decisions …; launch /tier-N?" ⏸
/tier-1       plan inline ⏸ → /to-implementation (the chat plan, one unit)
/tier-2       [/decision-map ⏸  when the scout's fog exceeds one grill session]
              → /grill-with-docs   (the grill + docs home; agenda from the scout;
                  CONTEXT.md and ADRs committed as the session goes)
              → /to-spec ⏸ → /to-tickets ⏸ → /cold-read
              → /to-implementation (the tickets)
/to-implementation   THE ENGINE — input: spec | ticket | tickets | nothing (chat)
```

**The drivers are a convenience, never a requirement.** Drive the classic chain by hand and skip them entirely: `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/to-implementation`, with an optional ticket selection into the engine.

## Gates — plan in, review out

Both tiers are gated at the same two points; the tier scales the process between them, never the bar.

- **Plan in.** No code before an approved plan. Tier 1: a few lines inline in chat — what changes, which files, how you'll verify (never an artifact). Tier 2: the spec and the tickets, each approved at its phase gate.
- **Review out.** No ticket closes until `/verified-review` passes — the reviewer runs Verify itself, red before / green after. A one-line fix meets the same bar as a Tier 2 ticket.

No tier works on the default branch — every unit isolates in a worktree (`/using-git-worktrees`). The contract is enforced, not advised: `branch-guard` denies edits on `main`/`master`, `review-guard` blocks unreviewed wrap-up, and every driver opens with a STOP-gate. Text gates steer; hooks enforce.

## Cheat sheet

| Command | When |
|---|---|
| `/route-me` | unsure which tier or flow fits — scout and route |
| `/tier-1` | you already know it's a fix that fits inline now |
| `/tier-2` | you already know it's a feature — drive the full chain |
| `/diagnose` | something broke, throws, fails, or went slow |
| `/grill-with-docs` | start of any feature against a codebase (grill + docs) |
| `/grilling` | grill with no codebase in play |
| `/decision-map` | open decisions exceed one grill session |
| `/to-spec` | the conversation has settled |
| `/to-tickets` | the spec is ready and the work spans sessions |
| `/cold-read` | tickets are ready — one cold read before implementation |
| `/to-implementation` | run a spec, a ticket, several, or the chat plan through the engine |
| `/verified-review` | close a ticket, a branch, or a PR |
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

The **internal five** — `/brief`, `/codebase-design`, `/domain-modeling`, `/resolving-merge-conflicts`, `/receiving-code-review` — are not in the menu; a driver or the model raises them in context (STACK.md §13).
