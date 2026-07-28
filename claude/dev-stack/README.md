# dev-stack

An opinionated engineering workflow for Claude Code — a set of skills, four subagents, and four git hooks that carry a task from idea to reviewed, integrated code through one of two tiers.

Run **`/route-me`** any time for the live map. This file is the overview.

## The idea

**Two tiers, one engine.** Every piece of work is one of:

- **Tier 1** — small work that fits a single execution: a bug fix, a small feature, a small refactor. Plan it inline, build it, review it, integrate.
- **Tier 2** — a feature too large for one pass. Grill it into a spec, cut the spec into tracer-bullet tickets, then build each ticket as its own Tier 1.

The tier is never chosen from the armchair. `/route-me` sends a read-only **scout** over the code first, and the tier falls out of **one** question: *how many vertical slices is this?* One → Tier 1. More than one → Tier 2. Unclear scope means you cannot count them, and a wide blast radius means no single slice lands green — both answer "more than one".

A **vertical slice** cuts a narrow but complete path through every layer it touches and ends in behaviour you can observe. The spec exists to hold several of them together across sessions, so a single slice has no use for one.

Domain vocabulary sits on a **second axis**, not this one: new terms, or a repo with no `CONTEXT.md` yet, raise `/domain-modeling` alongside either tier. One slice that introduces one term is Tier 1 plus a glossary entry — it does not buy a spec and a ticket breakdown to record a word.

**One engine.** Both tiers execute through `/to-implement`, which runs a single unit start to finish in an isolated worktree:

```
ready-check → brief → verify-brief → waves of (implementer + reviewer) → slice review → ADR → integrate
```

**The unit is a vertical slice; the brief cuts it into horizontal tasks, one per layer.** Each task gets its own **implementer** and its own **task-reviewer** on a clean context — a pair — and tasks whose declared files and edges permit it run side by side as a wave. That cut is the load-bearing idea: handed a whole slice at once, a cheap model attempts everything, drifts out of scope, and the work is redone. Handed one layer with its fence and its proof, it finishes.

Four subagents do the building. A **brief-writer** (the expensive model) explores the tree at pickup and makes the cut. An **implementer** builds one task test-first and refactors its own green code. A **task-reviewer** judges that task — conformance, its fence, repo conventions, smells, test quality — and hands findings back rather than fixing them. A **test-runner** runs the repo's checks once, at the slice review, and returns a noise-free summary.

The orchestrator gates, dispatches, commits and integrates. It never writes code, and it is the **only** thing that touches git: one worktree means one index, so agents edit files and the orchestrator commits each wave by path.

A feature of many tickets is run one ticket per fresh chat — or handed to **`/autopilot`** to run the batch unattended; the engine builds one unit at a time.

## The map

The map lives in **one place — `/route-me`.** Type it for the live chain, the gates, and the cheat sheet; this file describes the idea, that skill draws the shape. Nothing else in the stack carries a second copy.

Both tiers clear the same two gates — a one-line fix and a whole feature meet the same bar:

- **Plan in.** No code before an approved plan. Tier 1: a few lines in chat. Tier 2: the spec and the tickets, each approved at its gate.
- **Review out.** No unit closes until `/verified-review` passes — the sweep is run by a seat that wrote none of the code (green now, with red-at-pickup on file in the brief) and the real runtime is driven and observed: a green built on fakes fails here, before the axes spend a pass on it.

## Autopilot — a batch, unattended

The loop over tickets is normally yours — `/to-implement <ticket>`, one per fresh chat. **`/autopilot`** automates it without giving up what made it manual: each ticket still runs through the real `/to-implement` in a fresh session, so every brief stays sharp — autopilot only adds the scheduler.

```bash
/autopilot 1,2,3          # run tickets 1, 2, 3 through the engine unattended
```

It works the **frontier** of the dependency DAG — a ticket runs once its blockers have landed — **sequentially**, spawning one fresh headless session per ticket. Each cuts its worktree from an **integration branch** (`autopilot/<feature>` by default) and lands back on it on green, so the next ticket cuts from the new tip and sees its blockers' code for free. A ticket closes only when its session leaves a **success sentinel**; anything else — no sentinel, a red review, a merge conflict — **halts the whole run** and leaves state on disk. Fix it and re-run the same command: the frontier recomputes from the sentinels, landed tickets are skipped, the run continues. There is no separate resume verb — the command is idempotent.

Plan-in was approved when the tickets were cut (`/to-tickets`); **review-out stays fully enforced** — `/verified-review` must go green per ticket. Every autopilot behaviour is gated on `DEV_STACK_AUTOPILOT=1`, exported only by the runner, so with it unset the interactive pipeline is byte-for-byte unchanged.

**Preconditions & flags:** a clean working tree, and local-file tickets under `.scratch/<feature>/issues/<NN>-*.md` (what `/to-tickets` writes). `/autopilot` renders the plan and takes one go before anything runs. Under the hood it calls `scripts/autopilot.sh <batch>`; `--dry-run` prints the plan without spawning, and `--feature`, `--integration-branch`, `--base` override the defaults.

## The skills

The full menu — every command and when to reach for it — lives in **`/route-me`**: type it any time for the map and cheat sheet. The drivers (`/route-me`, `/tier-1`, `/tier-2`, `/to-implement`, `/autopilot`) plus `/verified-review` and `/finish-branch` carry the spine; the rest are raised by a driver or typed directly.

Five skills — `/brief`, `/codebase-design`, `/domain-modeling`, `/resolving-merge-conflicts`, `/receiving-code-review` — are **internal**: a driver or the model raises them in context, they aren't in the menu.

Four subagents in `agents/` do the building — `brief-writer`, `implementer`, `task-reviewer`, `test-runner` — each with its model pinned in frontmatter. `/to-implement` dispatches them by name.

`task-reviewer` is **new**: a fresh clone or a `git pull` needs `install.sh` re-run before it resolves, because a new agent is a new symlink. An edit to an existing one is live through the link it already has.

## Artifacts — volatile vs durable

The single rule: **volatile lives in the ephemeral, stable lives in the durable.**

| | Where | Paths & signatures | Lifetime |
|---|---|---|---|
| `CONTEXT.md` (glossary), `docs/adr/` | the default branch | never | forever |
| Spec, ticket | tracker or `.scratch/` | never | until merged |
| Brief, task reports | `.scratch/` only | always exact | dies with the worktree |

A spec has no paths because a human reads it and volatile detail gets in the way. A brief has exact paths because it will be dead in a day and precision there is free — and it is written **at pickup**, against the exact commit the worktree branched from, so it cannot go stale.

Domain knowledge — `CONTEXT.md` and ADRs — always reaches the default branch: planning-time docs are committed there directly, a unit's ADRs ride its branch and land with the merge, and a discarded branch is harvested first — `/domain-modeling` owns the destination rules.

## Gates & enforcement

Four hooks back the two gates as far as git state allows. The `SessionStart`/`Stop` gates are **opt-in per repo** via an empty `.branch-guard` file at the repo root.

| Hook | Event | Does |
|---|---|---|
| `branch-guard` | PreToolUse | denies edits/commits on the default branch — isolate first. Exempts `CONTEXT.md` and `docs/adr/`, so domain docs land on the main line |
| `commit-guard` | PreToolUse | Conventional Commits, no banned trailers, no blanket `git add` |
| `session-gate` | SessionStart | re-injects the gate contract on `startup\|clear\|compact` so it survives compaction |
| `review-guard` | Stop | blocks wrapping up unreviewed changes on a fix branch; kill-switch `~/.claude/.dev-stack-no-review-guard`, and stands down under `DEV_STACK_AUTOPILOT=1` (autopilot enforces review-out structurally) |

Gate **in** (plan approval) can't be git-checked, so it rides on the re-injected text (`session-gate`) and native plan mode. Gate **out** *is* enforced in code (`review-guard`), because "unreviewed changes on a fix branch" is git state.

### Gates vs conversations

A **gate** is one stop with one decision. A **grill** is a conversation — turn by turn, a question at a time — and marking a whole grill as "a gate" says nothing operational, so the two are named differently throughout.

Gates come in two kinds, and the difference is mechanical:

- **Self-gated** — the gate is live every time: `route-me`, `decision-map`, `finish-branch`, `handoff`, `improve-codebase-architecture`, `autopilot`. These are entry points or irreversible actions.
- **Chain-gated** — the gate is live when you type the skill's name, and **already satisfied** when a driver reached it, because the driver's own gate just asked the same question: `tier-1`, `tier-2`, `grill-me`, `to-spec`, `to-tickets`, `to-implement`.

Without that split, a seven-link chain makes every link ask permission to do what the previous gate authorised — Tier 1 collected four or five stops before a line of code. The bar never moves; only the asking does.

`cold-read` carries no gate at all: it is the last point where fixing a spec is free, so asking whether to run it buys nothing. Whether it is worth running on a *small* feature is a rule (few tickets, short grill), not a question.

## Design notes — why the stack is shaped this way

Decisions that keep needing an explanation live here, not in the skills. A skill is a prompt loaded into a working context: a reason belongs in the same sentence as the instruction it sharpens, and a reason that needs its own section belongs on this page.

### The brief is rebuilt at pickup — always

A ticket carries no paths. A brief carries exact paths, exact signatures, and the commands that prove the work — and it is written at pickup, in the unit's worktree, against the commit that worktree branched from.

Nothing seeds it. Not the scout, not a previous brief, not memory. The scout runs on the current branch *before* any worktree exists; between the scout and pickup, blockers merge, symbols get renamed, files move. A seed is worse than no seed, because the brief-writer will trust it and not look again.

The two readings do different jobs and have different lifetimes:

- the **scout** answers *how wide, and how clear* — that decides the tier, and it is decided once;
- the **brief** answers *where exactly, and what is it called* — that must be rebuilt on every pickup.

Corollary: everything a unit consumes is already merged code in the tree. If a signature the unit needs is missing, the ticket was picked up too early — that is `BLOCKED`, not a brief written against paper.

### Why the reviewer runs the checks itself

The tempting saving is to trust the implementer's report — it already carries test evidence, so why re-run? Because that spends the one thing the review exists to establish. **An implementer's report is a hypothesis, not evidence.** A report contradicted on its most checkable claim — a green it reported that comes back red — is not load-bearing on any of its other claims either.

Running the checks costs seconds. Discovering at merge that the report was optimistic costs the branch.

### Why the review has two axes

A change can pass one and fail the other:

- follows every standard, implements the wrong thing → **Standards pass, Spec fail**;
- does exactly what the ticket asked, breaks the repo's conventions → **Spec pass, Standards fail**.

Reported separately, neither masks the other. The build and runtime stages are not axes — they are the gates the axes stand on.

### Why a cold reader, instead of re-reading it yourself

You can't. You sat through the grilling session, so you will read the intended meaning into an ambiguous sentence every time — that is precisely the knowledge the artifact is supposed to carry, and you cannot un-know it while checking whether it does.

The cold reader isn't smarter than you. It is ignorant in exactly the way the next reader will be.

### Why planning is allowed to be slow

Planning error compounds. Something missed in the spec grows into the tickets, travels from the tickets into implementation, and the blast radius widens at every step — worst case the whole spec's output is thrown away, and that is usually discovered on the *last* slice, not the first.

So the length of a Tier 2 planning conversation is an investment, not an overhead. What gets cut on the way in is **ceremony** — gates that ask permission twice — never the thinking. Implementation stops being the hard part once the slice is written well; a slice written well enough runs unattended.

## Install

Clone the repo, then link the skills and agents into your Claude config:

```bash
git clone <this-repo> ~/.dev-stack
~/.dev-stack/install.sh             # symlinks skills/* and agents/* into ~/.claude
~/.dev-stack/install.sh --dry-run   # preview
~/.dev-stack/install.sh --replace   # overwrite an existing entry of the same name
```

`install.sh` symlinks each `skills/<name>` into `~/.claude/skills` and each `agents/<name>.md` into `~/.claude/agents`, so an edit in the repo is picked up live — no reinstall.

**After a `git pull` (or on a fresh machine), re-run `install.sh`.** A repo *edit* is live through the existing symlink, but a **new** skill or agent is a new name with no link yet — `install.sh` creates it (idempotent; it also prunes links whose target is gone). Hooks are wired by path in `settings.json`, so a pulled change to an existing hook (like the autopilot env-gate in `review-guard.sh`) is live with no reinstall — only a brand-new hook file needs adding to `settings.json`. Example: pulling `/autopilot` onto another machine is just `git pull && ./install.sh` — no new hooks, nothing to re-wire.

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

It asserts every driving skill opens with a `<STOP-GATE>` block, no skill declares `disable-model-invocation`, exactly five skills are internal, and forbidden skill directories are absent. Non-zero exit on any violation.

## Licence

MIT — see [LICENSE](LICENSE), which also credits the projects some of these skills grew from.
