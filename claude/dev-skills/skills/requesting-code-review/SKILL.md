---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Dispatch code reviewer subagent:**

Dispatch the `code-reviewer` agent **by name**, filling the template at
[code-reviewer.md](code-reviewer.md). By name, because that definition pins the
model — a `general-purpose` dispatch inherits the session's model instead, and a
cheap reviewer does not merely miss defects, it argues for them.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{ENVIRONMENT_FILE}` - What this project actually offers (see below)
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**The environment file is not optional.** A reviewer plans what to verify from
what it believes the project offers; hand it nothing and it infers a
conventional project and goes looking — `npm test` in a repo with no test
framework, a browser launched for a screen it has no tool to drive. State three
facts: what test tooling exists or that none does, how this change is actually
verified and where that evidence lives, and how its runtime can be driven with
what is installed here.

Inside a `to-implement` run this file already exists at
`<workspace>/environment.md`. Outside one, write the same three facts to any
file and pass its path — a file rather than a block in the prompt, because
pasted text stays resident in your context and is re-read on every later turn.

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

**4. Mark the reviewed state:**

Once nothing Critical or Important is open, record that *this exact state*
passed review:

```bash
"$HOME/.dotfiles/claude/dev-skills/hooks/review-mark.sh"
```

This is what the `review-guard` Stop hook reads. Without it the guard blocks
wrap-up on the branch and there is no other way to satisfy it. Run it after the
last fix, not before — the marker fingerprints the current commit, the changed
files and the diff, so any edit after it invalidates the mark, which is the
behaviour you want.

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from .ai-workflow/plans/deployment-plan.md
  ENVIRONMENT_FILE: .ai-workflow/run/deployment-plan/environment.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll just review the diff myself instead of dispatching a reviewer" | You're the coordinator — reviewing the diff inline burns the context window you need to keep driving the work. Dispatch a reviewer subagent: the diff and the evaluation live in its context, and only the findings come back to you. |
| "The reviewer needs my whole session history to understand the change" | Hand it precisely crafted context, never your session's history. That keeps the reviewer on the work product, not your thought process. |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
