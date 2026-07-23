# dev-stack

The 27 skills that make [`STACK.md`](STACK.md) executable, as one self-contained Claude Code plugin.

**Nothing else needs to be installed.** Install this plugin and you can drop the upstream Pocock set and disable the superpowers plugin.

Run **`/route-me`** for the map — the tiers, the Tier 2 chain, and which skill to reach for when.

## Composition

| Kind | Count | What |
|---|---|---|
| New | 3 | `brief`, `cold-read`, `route-me` |
| Forked from Pocock | 2 | `verified-review`, `diagnose` |
| Ported from superpowers | 5 | `execute-tickets`, `finish-branch`, `using-git-worktrees`, `verification-before-completion`, `receiving-code-review` |
| Vendored from Pocock, patched | 2 | `to-spec`, `to-tickets` |
| Vendored from Pocock, verbatim | 15 | `grill-with-docs`, `grilling`, `domain-modeling`, `tdd`, `wayfinder`, `codebase-design`, `improve-codebase-architecture`, `prototype`, `research`, `handoff`, `setup-matt-pocock-skills`, `writing-great-skills`, `resolving-merge-conflicts`, `setup-pre-commit`, `git-guardrails-claude-code` |

### The ones that carry the changes

| Skill | Why it exists |
|---|---|
| [`brief`](skills/brief/SKILL.md) | Technical bottom of a ticket — Files, Interfaces, Verify, Run as. Generated **at pickup**, not at planning time. STACK.md §9.3 |
| [`cold-read`](skills/cold-read/SKILL.md) | Reads the spec from the implementer's position, no planning context, to surface drift while fixing is free |
| [`route-me`](skills/route-me/SKILL.md) | The router — names every user-reachable skill and when to reach for it. Replaces Pocock's `ask-matt` |
| [`verified-review`](skills/verified-review/SKILL.md) | Fork of `code-review`: **runs `Verify` itself** instead of trusting the implementer's report. STACK.md §9.4 |
| [`diagnose`](skills/diagnose/SKILL.md) | Fork of `diagnosing-bugs`: adds Phase 2.5 Pattern Analysis and the three-fix breaker. STACK.md §9.5 |
| [`execute-tickets`](skills/execute-tickets/SKILL.md) | Port of `subagent-driven-development`: ticket+brief as the unit, review delegated to `verified-review`, `task-brief` script dropped |
| [`finish-branch`](skills/finish-branch/SKILL.md) | Port of `finishing-a-development-branch` + Step 1 **Harvest** — durable knowledge extracted before `.scratch/` is deleted |
| [`receiving-code-review`](skills/receiving-code-review/SKILL.md) | Verify a review finding against the code before implementing it — a finding is a hypothesis too. Invoked from the `execute-tickets` fix step |
| [`using-git-worktrees`](skills/using-git-worktrees/SKILL.md) | Port + dev-stack additions: the isolation step for **every** tier (Tier 1 too), a base-commit check (wrong-branch + local-ahead-of-origin traps), and the plan/review gate reminder. `new-branch` is the in-place fallback |
| [`to-spec`](skills/to-spec/SKILL.md) | Patched: publishes to `.scratch/` as well as a tracker. STACK.md §9.2 |
| [`to-tickets`](skills/to-tickets/SKILL.md) | Patched: points at `/brief` + `/execute-tickets` instead of `/implement`, and says explicitly not to write briefs at planning time |

Every dev-stack patch inside a vendored file is marked with an `<!-- dev-stack: … -->` comment, so `check-upstream.sh` and future re-vendoring can find them.

### Deliberately not included

`implement` (replaced by `brief` + `execute-tickets`), `code-review` and `diagnosing-bugs` (superseded by the forks), `ask-matt` (replaced by `route-me`), `triage` (`setup-matt-pocock-skills` already skips its section when absent), and the superpowers skills listed in STACK.md §8 (`brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `executing-plans`, `writing-plans`, `dispatching-parallel-agents`, `using-superpowers`).

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
3. **Harvest before `.scratch/` is deleted.** The only silent failure in the chain: nothing breaks, you just pay again in three weeks.

## Gates & enforcement

Every tier is bracketed by two gates — **Tier 1 included**:

- **Plan in.** Present the plan and get an explicit "go" before any edit. A few lines in chat for Tier 1; the spec / wayfinder chain for Tier 2/3.
- **Review out.** A change is not done until `/verified-review` has run — the reviewer runs `Verify` itself.

Four hooks back this as far as git state allows. The two `SessionStart`/`Stop` gates are **opt-in per repo** via an empty `.branch-guard` file at the repo root (the same marker `branch-guard` already uses):

| Hook | Event | Does |
|---|---|---|
| `branch-guard` | PreToolUse | denies edits/commits on the default branch — isolate first (`/using-git-worktrees`, or `/new-branch` fallback) |
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

Then disable the superpowers plugin (STACK.md §9.6): its `SessionStart` hook (`hooks/hooks.json`, matcher `startup|clear|compact`) injects `using-superpowers` wrapped in `<EXTREMELY_IMPORTANT>`, mandating a workflow this stack deliberately departs from. The hook can't be edited without being overwritten on update — hence the ports.

### Iterating on skills live

`install.sh` is a **dev-only** linker — it symlinks each `skills/<name>` into `~/.claude/skills` so an edit here is picked up without reinstalling the plugin. It is not the supported install path.

```bash
./install.sh --dry-run     # preview
./install.sh               # link skills/* into ~/.claude/skills
./install.sh --replace     # overwrite an existing entry of the same name
```

## The cost of vendoring

Freezing the upstream skills here means upstream fixes no longer arrive on their own. Both authors ship often.

```bash
./check-upstream.sh
```

Clones both upstreams (`mattpocock/skills` and the superpowers plugin from `anthropics/claude-plugins-official`) and reports which vendored skills drifted, ignoring `agents/` metadata and the two files dev-stack patches on purpose. It also runs an **invocation lint**: no user-invoked skill may be imperatively invoked by another skill (the class of bug that made `verified-review` unreachable in the first draft). Run it occasionally; re-vendor by copying upstream over `skills/<name>`, re-applying the marked patch, and deleting the copied `agents/`.

That is the trade you took to stop maintaining two installs. It's a real cost, not a rounding error.

## One thing found while vendoring

The installed copies of `grilling`, `research`, and `tdd` carried `disable-model-invocation: true`, which upstream does not have. Upstream keeps those three **model-invocable on purpose** — they are invoked by other skills, not by you:

- `grill-with-docs` is one line: *"Run a `/grilling` session, using the `/domain-modeling` skill"*
- `wayfinder` fires `/research` subagents to burn down AFK tickets in parallel
- `execute-tickets` and its implementer prompt drive `/tdd`

With the flag set, the model cannot reach any of them and each of those three chains silently degrades to "the agent describes what it would do". The copies here have the flag removed — and `check-upstream.sh`'s invocation lint now guards the general case.

## Status

Written, not yet exercised on a real feature. STACK.md §9 items 1–6 are covered; obkatka runs GrammarDiff first, then Chelsea (see STACK.md §9 and the `chelsea-verify-gap` note).

Open question: `/brief` adds an `Explore` dispatch per ticket. On a repo with a well-maintained `CONTEXT.md` and genuinely deep modules, the implementer might find what it needs in two greps and the brief is overhead. Worth measuring on the first real feature rather than assuming.

## Licence

MIT throughout. See [NOTICE.md](NOTICE.md).
