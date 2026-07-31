# dev-skills

An engineering workflow for Claude Code. One idea goes in; a reviewed, integrated
commit comes out.

```
ds-grill        interview → shared understanding → STOP
   ↓            (a bug goes through ds-bug first)
ds-spec         only when the work needs more than one plan → STOP
   ↓
ds-plan         one plan file, phases of seven fields, human approval → STOP
   ↓            (also an entry of its own: name a plan from a spec's list)
ds-implement    workspace + preflight, then per segment:
   ↓              implementer → implement-review, fixes by the same pair, cap 2
   ↓            then final-review on the runtime, then GATE 1: the human clicks
ds-finish       reset --soft into one commit, GATE 2: the human reads one diff
   ↓
merge (ff-only) / rebase / keep
```

**The human invokes every step.** Nothing here fires on a bare prompt except
`ds-bug`, which exists because a bug arrives as a symptom and the mistake it
prevents happens in the first reply. The model proposes; the human calls.

## The idea

Planning is the lever. A plan dense enough that a cheap model can build from it
without inventing anything is what buys everything else: the human steps off
step-by-step supervision, execution runs on Haiku or Sonnet, and review has a
fixed contract to judge against instead of re-deriving intent from a diff.

So the plan is exhaustive about **decisions** — paths, abstractions by name,
which signatures are frozen, the verification cases and their assertions — and
silent about **mechanics**. Function bodies and test code are typing, not
deciding; a plan carrying them makes the planner write code it cannot run, and
goes stale at the first correction.

## Entries

| | |
|---|---|
| [`ds-grill`](skills/entry/ds-grill/SKILL.md) | the task is not clear yet; interview it into a shared understanding |
| [`ds-grill-with-docs`](skills/entry/ds-grill-with-docs/SKILL.md) | same, and it captures vocabulary and earned ADRs as they settle |
| [`ds-bug`](skills/entry/ds-bug/SKILL.md) | reproduce, root cause, a failing test that pins it |
| [`ds-scout`](skills/entry/ds-scout/SKILL.md) | explain how existing code works; read-only |
| [`ds-refactor`](skills/entry/ds-refactor/SKILL.md) | restructure, migrate, upgrade — behaviour must not change |
| [`ds-tests`](skills/entry/ds-tests/SKILL.md) | the tests are the deliverable: cover code, or repair tests that lie |

Each entry exists because its verification contract differs. Where the contract
is the same — a feature, a behaviour change, tooling — the route is the same, and
there is no separate skill for it.

## The pipeline

| | |
|---|---|
| [`ds-spec`](skills/planning/ds-spec/SKILL.md) | shared decisions, glossary, and the list of plans — only when there is more than one |
| [`ds-plan`](skills/planning/ds-plan/SKILL.md) | the plan file: completeness contract, phases, topology, scenarios, ledger |
| [`ds-implement`](skills/execution/ds-implement/SKILL.md) | workspace, preflight, the segment loop, the final gate |
| [`ds-finish`](skills/finishing/ds-finish/SKILL.md) | one commit, GATE 2, integration, cleanup |

## Outside a run

[`ds-review`](skills/standalone/ds-review/SKILL.md) ·
[`ds-improve`](skills/standalone/ds-improve/SKILL.md) ·
[`ds-research`](skills/standalone/ds-research/SKILL.md) ·
[`ds-prototype`](skills/standalone/ds-prototype/SKILL.md) ·
[`ds-domain-modeling`](skills/docs/ds-domain-modeling/SKILL.md)

**Utilities:** [`ds-commit-work`](skills/utils/ds-commit-work/SKILL.md) ·
[`ds-merge-conflicts`](skills/utils/ds-merge-conflicts/SKILL.md) ·
[`ds-pre-commit`](skills/utils/ds-pre-commit/SKILL.md) ·
[`ds-guardrails`](skills/utils/ds-guardrails/SKILL.md) ·
[`ds-writing-skills`](skills/utils/ds-writing-skills/SKILL.md)

**Meta:** [`ds-bootstrap`](skills/meta/ds-bootstrap/SKILL.md), injected at session
start — one rule and a list of what exists.

## The seats

Dispatched by `ds-implement`; the human never types these.

| Seat | Model | Does |
|---|---|---|
| [`implementer`](agents/implementer.md) | assigned per segment by the plan | every phase of one segment, TDD where the plan says there are tests, commits |
| [`implement-review`](agents/implement-review.md) | `sonnet` | runs the checks itself first, then judges the diff against the phases' fields |
| [`final-review`](agents/final-review.md) | `opus` | drives the plan's scenarios on a live system and reports what it saw |

Two orthogonal questions, never asked twice of one diff: **is it well written**
belongs to the checkpoint, **does it work** to the final gate.

The `model:` in each definition is a floor, not the decision — the dispatch names
the model, and for the implementer the plan's topology decides it.

## Shared material

| Where | What | Read by |
|---|---|---|
| [`ds-review-criteria/CRITERIA.md`](skills/shared/ds-review-criteria/CRITERIA.md) | what counts as a finding, and what does not | `implement-review`, `final-review`, `ds-review` |
| [`ds-implement/tdd.md`](skills/execution/ds-implement/tdd.md) | test discipline | `implementer` |
| [`ds-implement/environment-contract.md`](skills/execution/ds-implement/environment-contract.md) | how the project builds, runs, and prepares a fresh tree | preflight, both reviewers |
| [`ds-plan/codebase-design.md`](skills/planning/ds-plan/codebase-design.md) | deep-module vocabulary | `ds-plan`, `ds-grill`, `ds-improve` |

`ds-review-criteria` is a skill only so the installer gives it a stable path; it
runs nothing and cannot be invoked. The other three live with the skill that owns
them.

**No agent definition carries a filesystem path.** The orchestrator resolves every
path and puts it in the dispatch; an agent handed no path stops and says so.

## The hooks

Wired in `claude/settings.json`, pointing at this directory.

| Hook | When | Does |
|---|---|---|
| `session-start` | startup / clear / compact | injects `ds-bootstrap` |
| `commit-guard` | before a Bash command | Conventional Commits, no blanket `git add`, no `git commit -a`, no bot trailers |
| `finish-guard` | before a Bash command | while a run is open, history surgery goes through `ds-finish` and nowhere else |
| `branch-guard` | before an edit or a commit | refuses work on the default branch in an opt-in repo; exempts `CONTEXT.md`, `docs/adr/` and `.ai-workflow/` |

`finish-guard` is armed by a run marker (`.ai-workflow/run/<plan>/RUN`) and is
inert without one — an unconditional block on `reset`/`merge`/`rebase` would
break ordinary work in every repository.

## Artifacts

| Where | What | Lives |
|---|---|---|
| `.ai-workflow/specs/` | the spec, when there is one | git-ignored |
| `.ai-workflow/plans/` | the plan — contract and ledger both | git-ignored |
| `.ai-workflow/run/<plan>/` | briefs, reports, review packages, and `RUN` — the marker holding plan, branch and base | git-ignored |
| `CONTEXT.md`, `docs/adr/` | glossary and decisions | committed, when the human says so |

`.gitignore` carries the line `.ai-workflow` **without a trailing slash**: in a
worktree it is a symlink into the main checkout, and git sees a symlink as a
file, which a trailing-slash pattern does not match. A symlink rather than a copy
because the plan is also the ledger — two copies would diverge, and an edit in
one tree would never reach the execution in the other.

Specs and plans are **not** deleted after integration. Deletion is irreversible
and disk is cheap; the human decides when they go.

## Install

Part of the dotfiles. `setup-symlinks.sh` runs `install.sh`, which searches
`skills/` **recursively** for `SKILL.md`, links each skill directory flat into
`~/.claude/skills/` under its own name, and links every `agents/*.md` into
`~/.claude/agents/`. The grouping into folders lives in this repository only.

Because the install is flat, a skill name must be unique across the whole tree —
the `ds-` prefix takes care of that, and a duplicate is an error rather than a
silent overwrite. Stale links are pruned, so an edit here is live at once.

On another machine: `git pull`, then `./setup-symlinks.sh`.

## Upstream

Forked from [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent,
MIT licensed, at v6.2.0, and reshaped since — the pipeline, the seven-field
phase, the review criteria and the finishing mechanics are this fork's. It is not
wired as a git remote.

To look at a later version of theirs, clone it beside this directory and diff:

```bash
git clone https://github.com/obra/superpowers /tmp/sp
diff -ru /tmp/sp/skills ./skills | less
```

## Licence

MIT — see [LICENSE](LICENSE).
