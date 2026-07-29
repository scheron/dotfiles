# What this fork changes

A fork of [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent, MIT licensed, taken at **v6.2.0**.

Upstream is not a remote — this lives inside the dotfiles, and their history does not belong here. So this file *is* the record of the divergence, not a summary of one a diff could reproduce. Keep it current: anything changed in a vendored skill without a line here becomes invisible the moment someone tries to pull a newer version across.

## Subtracted

**Every harness but Claude Code.** Upstream ships to Codex, Cursor, Kimi, OpenCode, Pi, Gemini and Antigravity. Their plugin directories, sync scripts, per-harness tool references and test suites are gone. This is what makes the model tiers below possible: upstream cannot name a model, because the name is wrong on most of the harnesses it targets.

**`spec-document-reviewer-prompt.md`.** Already orphaned upstream — nothing referenced it after the inline spec self-review replaced it.

**The skill-authoring artifacts under `diagnose/`** — creation log and pressure tests. They document how the skill was built, not how to use it.

## Renamed

| Upstream | Here |
|---|---|
| `subagent-driven-development` | `to-implement` |
| `writing-plans` | `to-plan` |
| `brainstorming` | `grill-me` |
| `test-driven-development` | `tdd` |
| `systematic-debugging` | `diagnose` |
| `finishing-a-development-branch` | `finish-branch` |
| `using-superpowers` | `using-dev-skills` |

Namespace `superpowers:` → `dev-skills:`. Artifacts move to `.ai-workflow/` and `docs/ai-workflow/`. Renames went through `git mv`, so upstream diffs still follow the files.

## Added

**Pinned model tiers, in `agents/`.** Upstream dispatches `general-purpose` with a prompt template carrying a `model:` placeholder marked REQUIRED — which still depends on the controller filling it in. Here each seat is an agent definition whose frontmatter carries the model, so omission is structurally impossible rather than merely forbidden. The agents stay thin and read upstream's prompt templates for the protocol, so upstream's changes to those keep arriving.

`code-reviewer` and `fixer` had no definition upstream at all; `fixer` in particular was dispatched by description only.

**Guard hooks**, wired into the plugin's own `hooks.json`: `branch-guard`, `commit-guard`, `review-guard`. Upstream ships none of these. They are what stops an agent committing on the default branch, staging blindly, or calling work done on a branch nothing has reviewed.

**Domain modelling.** `CONTEXT.md` and ADRs, written during the interview and committed to the default branch as the conversation goes. Upstream keeps no memory across features — it deletes the workspace when the branch lands and treats git history as the record.

**A code-smell baseline** (`SMELLS.md`, Fowler) carried by the task reviewer, and documented repo conventions as an explicit review axis.

**A runtime gate on the whole-branch review.** The plan header gains an `Observable outcome`; the reviewer must drive it and report what it saw, not what a test claims. Upstream's final review judges the diff.

**A gate on the plan.** Upstream approves the spec, then self-reviews the plan inline and proceeds. Here the plan is also presented for approval — with cold-read and an authored brief both gone, the plan has no second reader, and it is the last point where a correction is free.

**Skills with no upstream equivalent** — `domain-modeling`, `decision-map`, `codebase-design`, `improve-codebase-architecture`, `prototype`, `research`, `handoff`, `commit-work`, `setup-pre-commit`, `git-guardrails-claude-code`. Several descend from [Matt Pocock's skills](https://github.com/mattpocock/skills), MIT licensed.

## Kept deliberately

The measured parts of upstream's engine are unchanged, and changing them should require a reason at least as good as the evidence behind them: the five-round fix cap, the resume-then-escalate ladder, one fixer per findings list, the scoped re-review, the ledger, continuous execution, the context discipline, and the rule that a reviewer does not re-run tests the implementer already ran.
