# dev-stack

The 28 skills and 3 agent definitions that make [`STACK.md`](STACK.md) executable, as one self-contained Claude Code plugin.

**Nothing else needs to be installed.** Install this plugin and you can drop the upstream Pocock set and disable the superpowers plugin.

Run **`/route-me`** for the map — the tiers, the Tier 2 chain, and which skill to reach for when.

## Composition

| Kind | Count | What |
|---|---|---|
| New (dev-stack original) | 7 | `route-me`, `tier-1`, `tier-2`, `decision-map`, `cold-read`, `brief`, `commit-work` |
| Forked from Pocock | 2 | `verified-review`, `diagnose` |
| Ported from superpowers | 4 | `to-implementation`, `finish-branch`, `using-git-worktrees`, `receiving-code-review` |
| Vendored from Pocock, patched | 2 | `to-spec`, `to-tickets` |
| Vendored from Pocock, invocation-contract patch | 7 | `grill-with-docs`, `domain-modeling`, `codebase-design`, `improve-codebase-architecture`, `handoff`, `writing-great-skills`, `resolving-merge-conflicts` |
| Vendored from Pocock, verbatim | 6 | `grilling`, `tdd`, `prototype`, `research`, `setup-pre-commit`, `git-guardrails-claude-code` |

Plus **3 agent definitions** in `agents/` — `brief-writer` (opus), `implementer` (sonnet), `test-runner` (sonnet): the seats `/to-implementation` dispatches, each with its model pinned in frontmatter. `install.sh` links `agents/` alongside `skills/`, and the plugin bundles them the same way. STACK.md §6/§13.

### The ones that carry the changes

| Skill | Why it exists |
|---|---|
| [`route-me`](skills/route-me/SKILL.md) | The scout + router — reads the task read-only, proposes one of two tiers plus the open decisions, and drives the chain behind a STOP-gate at each phase. Replaces Pocock's `ask-matt`. STACK.md §1–2 |
| [`tier-1`](skills/tier-1/SKILL.md) | The Tier 1 driver — plan inline, get the go, run one unit through the engine. STACK.md §4 |
| [`tier-2`](skills/tier-2/SKILL.md) | The Tier 2 driver — `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/cold-read` → engine, a STOP-gate at every phase. STACK.md §4 |
| [`decision-map`](skills/decision-map/SKILL.md) | Optional Tier 2 front phase — materialise the scout's open decisions as tickets and burn them down (research, prototype, grill); every resolution → an ADR. Inherits the Tier-3 role of the retired `wayfinder`. STACK.md §4 |
| [`to-implementation`](skills/to-implementation/SKILL.md) | The one execution engine both tiers share — runs every unit as a fresh subagent in its own worktree, filters the inner loop through `test-runner`, closes units only by `/verified-review`. Port of `subagent-driven-development`. STACK.md §4–6 |
| [`brief`](skills/brief/SKILL.md) | Technical bottom of a unit — Files, Interfaces, Verify. Written by the brief-writer **at pickup**, inside the spoke, never at planning time. STACK.md §6–7 |
| [`cold-read`](skills/cold-read/SKILL.md) | Reads the spec from the implementer's position, no planning context, to surface drift while fixing is free |
| [`verified-review`](skills/verified-review/SKILL.md) | Fork of `code-review`: **runs `Verify` itself** instead of trusting the implementer's report; raises `adr-candidate` findings mid-flight. STACK.md §8–9 |
| [`diagnose`](skills/diagnose/SKILL.md) | Fork of `diagnosing-bugs`: adds Phase 2.5 Pattern Analysis and the three-fix breaker. STACK.md §11 |
| [`finish-branch`](skills/finish-branch/SKILL.md) | Port of `finishing-a-development-branch` + Step 1 **Harvest** — the final sweep for durable knowledge that didn't land mid-flight, before `.scratch/` is deleted. STACK.md §9 |
| [`receiving-code-review`](skills/receiving-code-review/SKILL.md) | Verify a review finding against the code before implementing it — a finding is a hypothesis too. Invoked from `/to-implementation`'s fix dispatches |
| [`using-git-worktrees`](skills/using-git-worktrees/SKILL.md) | Port + dev-stack additions: the isolation step for **every** tier (Tier 1 too), a base-commit check (wrong-branch + local-ahead-of-origin traps), and the plan/review gate reminder. Its in-place branch fallback (Step 1c) absorbs the retired `new-branch` (helper script kept) |
| [`to-spec`](skills/to-spec/SKILL.md) | Patched: publishes to `.scratch/` as well as a tracker. STACK.md §7 |
| [`to-tickets`](skills/to-tickets/SKILL.md) | Patched: points at `/to-implementation` instead of `/implement`, and says explicitly not to write briefs at planning time |

Every dev-stack patch inside a vendored file is marked with an `<!-- dev-stack: … -->` comment, so `check-upstream.sh` and future re-vendoring can find them.

### Deliberately not included

`implement` (replaced by `brief` + `to-implementation`), `code-review` and `diagnosing-bugs` (superseded by the forks), `ask-matt` (replaced by `route-me`), `triage` (tracker detection folded into the tier-2 preflight), and the superpowers skills listed in STACK.md §12 (`brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `executing-plans`, `writing-plans`, `dispatching-parallel-agents`, `using-superpowers`).

_History:_ the five dev-stack skills retired in the 2026-07-23 two-tier redesign — `execute-tickets`, `wayfinder`, `new-branch`, `setup-matt-pocock-skills`, `verification-before-completion` — and where each one's live duties moved, are recorded in STACK.md §12–13.

## The one idea

**Volatile goes in the ephemeral artifact; stable goes in the durable one.**

| | Where | Paths & signatures | Lifetime |
|---|---|---|---|
| `CONTEXT.md`, `docs/adr/`, `AGENTS.md` | repo | never | forever |
| Spec, ticket | tracker or `.scratch/` | **never** | until merged |
| Brief, report, ledger | `.scratch/` only | **always exact** | dies at merge |

A spec has no paths because a human reads it and volatile detail gets in the way. A brief has exact paths because it will be dead in a day and precision there is free.

Three rules fall out of it, and they're the three most likely to be violated under pressure:

1. **A brief is generated at pickup, never earlier.** Staleness scales with depth in the dependency graph. A stale brief is worse than none — the implementer trusts it.
2. **The reviewer runs the verification command.** An implementer's report is a hypothesis, not evidence.
3. **Harvest before `.scratch/` is deleted.** The final sweep for durable knowledge that didn't already land mid-flight (the `adr-candidate` gate) — miss it and the loss is silent: nothing breaks, you just pay again in three weeks.

## Gates & enforcement

Every tier is bracketed by two gates — **Tier 1 included**:

- **Plan in.** Present the plan and get an explicit "go" before any edit. A few lines in chat for Tier 1; the spec → tickets chain for Tier 2.
- **Review out.** A change is not done until `/verified-review` has run — the reviewer runs `Verify` itself.

Four hooks back this as far as git state allows. The two `SessionStart`/`Stop` gates are **opt-in per repo** via an empty `.branch-guard` file at the repo root (the same marker `branch-guard` already uses):

| Hook | Event | Does |
|---|---|---|
| `branch-guard` | PreToolUse | denies edits/commits on the default branch — isolate first (`/using-git-worktrees`; its in-place branch fallback covers sandbox denial) |
| `commit-guard` | PreToolUse | Conventional Commits, no banned trailers, no blanket `git add` |
| `session-gate` | SessionStart | re-injects the gate contract on `startup\|clear\|compact` so it survives compaction |
| `review-guard` | Stop | blocks wrapping-up unreviewed changes on a fix branch; kill-switch `~/.claude/.dev-stack-no-review-guard` |

Gate **in** (plan approval) can't be git-checked — "did the user approve?" leaves no unforgeable trace — so it rides on the re-injected text (`session-gate`) and native plan mode. Gate **out** *is* enforced in code (`review-guard`), because "unreviewed changes exist on a fix branch" is git state. See [INSTALL.md](INSTALL.md) for wiring and [STACK.md](STACK.md) §1/§5 for the why.

## Install

This repo is its own single-plugin marketplace. Add it and install:

```
/plugin marketplace add <path-to-this-repo>
/plugin install dev-stack@dev-stack
```

The plugin lives in your `settings.json` `enabledPlugins`, so it can't be clobbered by an external `npx skills` manager — the failure that motivated shipping it this way.

Then disable the superpowers plugin (STACK.md §12): its `SessionStart` hook (`hooks/hooks.json`, matcher `startup|clear|compact`) injects `using-superpowers` wrapped in `<EXTREMELY_IMPORTANT>`, mandating a workflow this stack deliberately departs from. The hook can't be edited without being overwritten on update — hence the ports.

### Iterating on skills live

`install.sh` is a **dev-only** linker — it symlinks each `skills/<name>` into `~/.claude/skills` and each `agents/<name>.md` into `~/.claude/agents`, so an edit here is picked up without reinstalling the plugin. It is not the supported install path.

```bash
./install.sh --dry-run     # preview
./install.sh               # link skills/* and agents/* into ~/.claude
./install.sh --replace     # overwrite an existing entry of the same name
```

## The cost of vendoring

Freezing the upstream skills here means upstream fixes no longer arrive on their own. Both authors ship often.

```bash
./check-upstream.sh
```

Clones both upstreams (`mattpocock/skills` and the superpowers plugin from `anthropics/claude-plugins-official`) and reports which vendored skills drifted, ignoring `agents/` metadata and the two files dev-stack patches on purpose. It also runs a **contract lint**: every driving skill must open with a `<STOP-GATE>` block (STACK.md §3) — the mechanical half of the invocation policy that replaced `disable-model-invocation`. Run it occasionally; re-vendor by copying upstream over `skills/<name>`, re-applying the marked patch, and deleting the copied `agents/`.

That is the trade you took to stop maintaining two installs. It's a real cost, not a rounding error.

## Invocation: STOP-gates, not flags

Three vendored skills — `grilling`, `research`, `tdd` — are **model-invocable on purpose**: they're invoked by other skills, not typed by you:

- `grill-with-docs` is one line: *"Run a `/grilling` session, using the `/domain-modeling` skill"*
- `decision-map` fires `/research` subagents in parallel to burn down open decisions
- `/to-implementation`'s implementer drives `/tdd`

An installed copy that carries `disable-model-invocation: true` (as those three did in an early draft) makes the model unable to reach them, and each chain silently degrades to "the agent describes what it would do". The final policy removes the flag from every driving skill (STACK.md §3 — zero occurrences repo-wide) and replaces it with a `<STOP-GATE>` opener: the model may raise a skill, the user still gates it, and `check-upstream.sh`'s contract lint checks the gate is present.

## Status

Written, not yet exercised on a real feature. STACK.md §14 tracks the remaining work; the obkatka runs GrammarDiff first, then Chelsea (STACK.md §14).

Open question: the brief-writer explores the code itself for every unit — it *is* the walk, no separate `Explore` dispatch. On a repo with a well-maintained `CONTEXT.md` and genuinely deep modules, that walk may be overhead the implementer's two greps would have saved. Worth measuring on the first real feature rather than assuming.

## Licence

MIT throughout. See [NOTICE.md](NOTICE.md).
