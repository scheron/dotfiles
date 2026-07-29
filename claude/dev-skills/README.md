# dev-skills

An engineering workflow for Claude Code. One idea goes in; a reviewed, integrated branch comes out.

```
grill-me      interview → 2-3 approaches → design doc          .ai-workflow/specs/
   ↓
to-plan       one plan: exact paths, real code, TDD steps      .ai-workflow/plans/
   ↓          ⏸ approve the plan
to-implement  per task: implementer → task-reviewer → fix loop
   ↓          then one whole-branch review, on the strongest model
finish-branch ⏸ merge / PR / keep
```

There is no ticket layer and no second planning pass at pickup. The plan is the only document between the design and the code — the engine cuts each task out of it mechanically, so what is not in the plan does not reach an implementer.

## Install

Part of the dotfiles. `setup-symlinks.sh` runs `install.sh`, which links every
`skills/<name>/` into `~/.claude/skills/` and every `agents/<name>.md` into
`~/.claude/agents/`. It only ever touches its own names and prunes its own stale
links, so an edit here is live at once — no reinstall.

On another machine: `git pull` in the dotfiles, then `./setup-symlinks.sh`.

The hooks are wired in `claude/settings.json`, pointing at this directory:

| Event | Command |
|---|---|
| `SessionStart` (startup\|clear\|compact) | `hooks/session-start` |
| `PreToolUse` Bash | `hooks/commit-guard.sh` |
| `PreToolUse` Edit\|Write\|Bash | `hooks/branch-guard.sh` |
| `Stop` | `hooks/review-guard.sh` |

## The seats

Every subagent has its model pinned in `agents/`, so a dispatch can never silently inherit the session's most expensive model.

| Seat | Model | Does |
|---|---|---|
| `implementer` | `sonnet` | builds one task, TDD, commits, self-reviews |
| `task-reviewer` | `sonnet` | judges that task on a clean context — spec, quality, smells |
| `re-reviewer` | `sonnet` | verifies one fix round against the fix diff only |
| `fixer` | `sonnet` | applies a whole findings list in one pass |
| `code-reviewer` | `opus` | the branch's one broad judgement, and drives the runtime |

`implementer` drops to `haiku` when the plan step carries the complete code — that task is transcription. Reviewing seats never go below `sonnet`: a cheap reviewer does not merely miss defects, it argues for them.

## The hooks

| Hook | When | Does |
|---|---|---|
| `session-start` | startup / clear / compact | injects `using-dev-skills` so skills actually fire |
| `branch-guard` | before an edit or a commit | refuses work on the default branch; exempts `CONTEXT.md`, `docs/adr/` and `.ai-workflow/` |
| `commit-guard` | before a Bash commit | Conventional Commits, no blanket `git add`, no bot trailers |
| `review-guard` | on stop | refuses "done" on a branch whose current state was never reviewed |

## Artifacts

| Where | What | Lives |
|---|---|---|
| `.ai-workflow/specs/` | the design doc | git-ignored |
| `.ai-workflow/plans/` | the implementation plan | git-ignored |
| `.ai-workflow/run/<plan>/` | ledger, task briefs, reports, review packages | git-ignored, deleted when the branch lands |
| `CONTEXT.md`, `docs/adr/` | glossary and decisions | committed, on the default branch |

Everything under `.ai-workflow/` is scaffolding for one branch, and a self-ignoring `.gitignore` at its root keeps all of it out of `git status`. Specs and plans are exact, which is what makes them useful during the run and false the moment the code moves past them — a committed spec is a document that rots in place and misleads the next reader. Only the domain docs are written to survive: `CONTEXT.md` for the vocabulary, `docs/adr/` for the decisions and their reasons. Those go on the default branch, and they are the record.

The ledger is what survives compaction. A controller that loses its place re-dispatches completed tasks; the ledger and `git log` are trusted over recollection.

## Skills

**The chain** — `grill-me` · `to-plan` · `to-implement` · `requesting-code-review` · `finish-branch`

**Discipline** — `tdd` · `diagnose` · `receiving-code-review` · `verification-before-completion` · `using-git-worktrees` · `commit-work` · `resolving-merge-conflicts`

**Design and knowledge** — `domain-modeling` · `codebase-design` · `improve-codebase-architecture` · `decision-map` · `prototype` · `research` · `handoff`

**Setup and meta** — `setup-pre-commit` · `git-guardrails-claude-code` · `writing-skills` · `using-dev-skills` · `dispatching-parallel-agents`

## Upstream

Forked from [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent,
MIT licensed, at v6.2.0. It is not wired as a git remote — this lives inside the
dotfiles now, and their history does not belong here.

To take a later version of theirs, clone it beside this directory and diff:

```bash
git clone https://github.com/obra/superpowers /tmp/sp
diff -ru /tmp/sp/skills ./skills | less
```

[NOTICE.md](NOTICE.md) records what this fork subtracted, renamed, added and
deliberately kept — read it before pulling anything across.

## Licence

MIT — see [LICENSE](LICENSE).
