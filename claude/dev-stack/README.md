# dev-stack

An opinionated engineering workflow for Claude Code — a set of skills, three subagents, and four git hooks that carry a task from idea to reviewed, integrated code through one of two tiers.

Run **`/route-me`** any time for the live map. This file is the overview.

## The idea

**Two tiers, one engine.** Every piece of work is one of:

- **Tier 1** — small work that fits a single execution: a bug fix, a small feature, a small refactor. Plan it inline, build it, review it, integrate.
- **Tier 2** — a feature too large for one pass. Grill it into a spec, cut the spec into tracer-bullet tickets, then build each ticket as its own Tier 1.

The tier is never chosen from the armchair. `/route-me` sends a read-only **scout** over the code first, and the tier falls out of five questions: is the scope clear, how wide is the blast radius, does it introduce domain vocabulary, does one context window suffice, and does a `CONTEXT.md` exist yet. Anything unclear, wide, or novel → Tier 2.

**One engine.** Both tiers execute through `/to-implement`, which runs a single unit start to finish in an isolated worktree:

```
brief → verify-brief → build → sweep → review → integrate
```

Each seat is a subagent: a **brief-writer** explores the code and writes the exact plan, an **implementer** builds from it test-first, a **test-runner** runs the repo's checks and returns a noise-free summary. The orchestrator gates, dispatches, and integrates — it never writes code itself. A feature of many tickets is run one ticket per fresh chat; the engine builds one unit at a time.

## The map

```
/route-me     scout → "Tier N because …; open decisions …; launch /tier-N?" ⏸
/tier-1       [ /diagnose if bug ] · [ /grill if a small feature ]
              → plan inline ⏸ → /to-implement (the chat plan, one unit)
/tier-2       [ /decision-map ⏸  when open decisions exceed one grill session ]
              → /grill-me (grill + docs)
              → /to-spec ⏸ → /to-tickets ⏸ → /cold-read
              → /to-implement (one ticket per fresh chat)
/to-implement  the engine — one unit: a plan, a task, a spec, or one ticket
```

Both tiers clear the same two gates — a one-line fix and a whole feature meet the same bar:

- **Plan in.** No code before an approved plan. Tier 1: a few lines in chat. Tier 2: the spec and the tickets, each approved at its gate.
- **Review out.** No unit closes until `/verified-review` passes — the reviewer runs the verification command *itself*: green now, with red-at-pickup on file in the brief.

## The skills

The full menu — every command and when to reach for it — lives in **`/route-me`**: type it any time for the map and cheat sheet. The drivers (`/route-me`, `/tier-1`, `/tier-2`, `/to-implement`) plus `/verified-review` and `/finish-branch` carry the spine; the rest are raised by a driver or typed directly.

Five skills — `/brief`, `/codebase-design`, `/domain-modeling`, `/resolving-merge-conflicts`, `/receiving-code-review` — are **internal**: a driver or the model raises them in context, they aren't in the menu.

Three subagents in `agents/` do the building — `brief-writer`, `implementer`, `test-runner` — each with its model pinned in frontmatter. `/to-implement` dispatches them by name.

## Artifacts — volatile vs durable

The single rule: **volatile lives in the ephemeral, stable lives in the durable.**

| | Where | Paths & signatures | Lifetime |
|---|---|---|---|
| `CONTEXT.md` (glossary), `docs/adr/` | the default branch | never | forever |
| Spec, ticket | tracker or `.scratch/` | never | until merged |
| Brief, report | `.scratch/` only | always exact | dies with the worktree |

A spec has no paths because a human reads it and volatile detail gets in the way. A brief has exact paths because it will be dead in a day and precision there is free — and it is written **at pickup**, against the exact commit the worktree branched from, so it cannot go stale.

Domain knowledge — `CONTEXT.md` and ADRs — always reaches the default branch: planning-time docs are committed there directly, a unit's ADRs ride its branch and land with the merge, and a discarded branch is harvested first — `/domain-modeling` owns the destination rules.

## Gates & enforcement

Four hooks back the two gates as far as git state allows. The `SessionStart`/`Stop` gates are **opt-in per repo** via an empty `.branch-guard` file at the repo root.

| Hook | Event | Does |
|---|---|---|
| `branch-guard` | PreToolUse | denies edits/commits on the default branch — isolate first. Exempts `CONTEXT.md` and `docs/adr/`, so domain docs land on the main line |
| `commit-guard` | PreToolUse | Conventional Commits, no banned trailers, no blanket `git add` |
| `session-gate` | SessionStart | re-injects the gate contract on `startup\|clear\|compact` so it survives compaction |
| `review-guard` | Stop | blocks wrapping up unreviewed changes on a fix branch; kill-switch `~/.claude/.dev-stack-no-review-guard` |

Gate **in** (plan approval) can't be git-checked, so it rides on the re-injected text (`session-gate`) and native plan mode. Gate **out** *is* enforced in code (`review-guard`), because "unreviewed changes on a fix branch" is git state.

## Install

Clone the repo, then link the skills and agents into your Claude config:

```bash
git clone <this-repo> ~/.dev-stack
~/.dev-stack/install.sh             # symlinks skills/* and agents/* into ~/.claude
~/.dev-stack/install.sh --dry-run   # preview
~/.dev-stack/install.sh --replace   # overwrite an existing entry of the same name
```

`install.sh` symlinks each `skills/<name>` into `~/.claude/skills` and each `agents/<name>.md` into `~/.claude/agents`, so an edit in the repo is picked up live — no reinstall.

To wire the four hooks, add them to your `settings.json` (point the paths at your clone):

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "$HOME/.dev-stack/hooks/commit-guard.sh" }] },
      { "matcher": "Edit|MultiEdit|Write|NotebookEdit|Bash", "hooks": [{ "type": "command", "command": "$HOME/.dev-stack/hooks/branch-guard.sh" }] }
    ],
    "SessionStart": [
      { "matcher": "startup|clear|compact", "hooks": [{ "type": "command", "command": "$HOME/.dev-stack/hooks/session-gate.sh" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "$HOME/.dev-stack/hooks/review-guard.sh" }] }
    ]
  }
}
```

Requirements: `jq` on `PATH`. The `branch-guard` and session hooks only act in repos carrying a `.branch-guard` marker — drop an empty `.branch-guard` at a repo root to opt it in. Skills that need a helper script locate the clone through the installed symlinks; set `$DEV_STACK_ROOT` only to override that. Freshly linked skills are picked up when the harness next refreshes its skill list — at the latest, the next session.

## The contract lint

The stack's own invariants are checked offline by one script — its own Verify:

```bash
./contract-lint.sh
```

It asserts every driving skill opens with a `<STOP-GATE>` block, no skill declares `disable-model-invocation`, exactly five skills are internal, and the retired skills are gone. Non-zero exit on any violation.

## Licence

MIT — see [LICENSE](LICENSE), which also credits the projects some of these skills grew from.
