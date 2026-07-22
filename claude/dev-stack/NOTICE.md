# Attribution

Everything in `dev-stack` derives from two MIT-licensed sources, or is original work built to sit alongside them.

## superpowers — Copyright (c) 2025 Jesse Vincent

MIT. Source: the `superpowers` Claude Code plugin, version 6.1.1.

| File here | Upstream | Change |
|---|---|---|
| `skills/using-git-worktrees/SKILL.md` | `skills/using-git-worktrees/SKILL.md` | verbatim; attribution line added |
| `skills/verification-before-completion/SKILL.md` | `skills/verification-before-completion/SKILL.md` | verbatim; attribution line added |
| `skills/execute-tickets/SKILL.md` | `skills/subagent-driven-development/SKILL.md` | substantially rewritten — see below |
| `skills/execute-tickets/implementer-prompt.md` | `skills/subagent-driven-development/implementer-prompt.md` | adapted: brief-based, `/tdd`, Verify in the report contract |
| `skills/finish-branch/SKILL.md` | `skills/finishing-a-development-branch/SKILL.md` | Step 1 "Harvest" added; `.scratch/` cleanup added |
| `skills/diagnose/SKILL.md` (Phase 2.5, three-fix breaker) | `skills/systematic-debugging/SKILL.md` | two sections grafted onto a Pocock skill |
| `skills/receiving-code-review/SKILL.md` | `skills/receiving-code-review/SKILL.md` | verbatim; invoked by `/execute-tickets` when acting on review findings |

**Changes to `subagent-driven-development`:**

1. The unit of work is a **ticket plus its brief**, not a task extracted from a monolithic plan. The `scripts/task-brief` extraction script is dropped — every ticket is already its own file.
2. Per-ticket review is delegated to `verified-review`, which **runs the verification command**. This reverses upstream's rule at `subagent-driven-development/SKILL.md:166` ("Do not ask a reviewer to re-run tests the implementer already ran"). Rationale is documented in both skills.
3. `scripts/review-package` is not carried over; `verified-review` pins its own fixed point.

**Not ported, deliberately:** `using-superpowers`, `brainstorming`, `test-driven-development`, `systematic-debugging` (whole), `requesting-code-review`, `executing-plans`, `writing-plans`, `dispatching-parallel-agents`. Reasons are in `STACK.md` §8.

## mattpocock/skills — Copyright (c) 2026 Matt Pocock

MIT. Source: <https://github.com/mattpocock/skills>.

| File here | Upstream | Change |
|---|---|---|
| `skills/verified-review/SKILL.md` | `skills/engineering/code-review/SKILL.md` | Verify gate added: the reviewer runs the command and reports discrepancies against the implementer's report. Two-axis structure and the Fowler smell baseline are upstream's. |
| `skills/diagnose/SKILL.md` | `skills/engineering/diagnosing-bugs/SKILL.md` | Phase 2.5 and the three-fix breaker grafted in from superpowers; completion criterion and phase structure are upstream's. |

### Vendored, patched

| File here | Change |
|---|---|
| `skills/to-spec/SKILL.md` | step 3 also supports publishing to `.scratch/<feature>/spec.md` when the tracker is local markdown |
| `skills/to-tickets/SKILL.md` | closing section points at `/brief` + `/execute-tickets` instead of `/implement`, and states that briefs are generated at pickup, not at planning time |

Each patch is marked in-file with an `<!-- dev-stack: … -->` comment.

### Vendored verbatim

`grill-with-docs`, `grilling`, `domain-modeling`, `tdd`, `wayfinder`, `codebase-design`, `improve-codebase-architecture`, `prototype`, `research`, `handoff`, `setup-matt-pocock-skills`, `writing-great-skills`, `resolving-merge-conflicts`, `setup-pre-commit`, `git-guardrails-claude-code` — copied unmodified, including their supporting files (`CONTEXT-FORMAT.md`, `ADR-FORMAT.md`, `DEEPENING.md`, `DESIGN-IT-TWICE.md`, `tests.md`, `mocking.md`, `LOGIC.md`, `UI.md`, `HTML-REPORT.md`, `GLOSSARY.md`, the `issue-tracker-*.md` templates, and `git-guardrails-claude-code/scripts/`).

The upstream `agents/openai.yaml` harness metadata is **not** carried — this set is Claude-only (STACK.md §7).

These are frozen at the commit they were copied from. `check-upstream.sh` reports drift against current upstream.

### Not vendored

`implement`, `code-review`, `diagnosing-bugs`, `ask-matt`, `triage` — superseded, forked, or replaced. See README.

## Original

`skills/brief/`, `skills/cold-read/`, and `skills/route-me/` are new work. `route-me` is the set's router — it replaces Pocock's `ask-matt`, mapping every user-reachable skill and when to reach for it.

`cold-read`'s three construction constraints — never ask the reader to audit, no verdict, never tell it why it's reading — come from the design sketched in [mattpocock/skills#574](https://github.com/mattpocock/skills/issues/574) by @nikolaspadilla, which is unresolved upstream.

## MIT

Both upstream licences are the standard MIT text. The permission notice below covers the derived files in this directory:

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
