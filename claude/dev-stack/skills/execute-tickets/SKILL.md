---
name: execute-tickets
description: Execute a set of tickets by dispatching one fresh implementer per ticket, reviewing each with /verified-review before moving on, and tracking progress in a durable ledger. Use when tickets exist and you want them built in this session rather than one session per ticket.
disable-model-invocation: true
---

# Execute Tickets

Work the frontier by dispatching a fresh implementer per ticket, gating each on `/verified-review`, and recording progress in a file that survives compaction.

**Why subagents:** each implementer gets a context you construct deliberately — its brief, its interfaces, its constraints. It never inherits this session's history. That keeps the implementer sharp and keeps your own context free for coordination.

**Core loop:** frontier ticket → `/brief` → implementer → `/verified-review` → ledger → next.

> Port of superpowers' `subagent-driven-development` (MIT, Jesse Vincent). Three substantive changes: the unit is a **ticket + brief**, not a task extracted from a monolithic plan; review is delegated to `/verified-review`, which **runs the verification command** rather than trusting the implementer's report; and the `task-brief` extraction script is dropped — every ticket is already its own file.

## When

Tickets exist (from `/to-tickets`), their blocking edges are drawn, and you want them built without opening a session per ticket.

**Not for:** a single ticket (just `/brief`, then `/tdd` and `/verified-review` by hand), tightly-coupled tickets that can't be reviewed independently, or work that hasn't been specced yet.

**Prerequisite:** an isolated workspace. Use `using-git-worktrees` first.

## Continuous execution

Do not pause to check in between tickets. Execute the whole frontier. The only reasons to stop: a `BLOCKED` status you cannot resolve, ambiguity that genuinely prevents progress, or all tickets done. "Should I continue?" prompts waste the user's time — they asked for the tickets to be built.

Between tool calls, narrate at most one short line. The ledger and the tool results carry the record.

## Process

### 0. Pre-flight

Read all tickets once. Scan for:

- tickets that contradict each other or the spec's Global Constraints
- anything a ticket mandates that `/verified-review` would treat as a defect

Present everything you find as **one batched question** — each finding beside the text that mandates it, asking which governs — before execution starts. Not one interrupt per discovery mid-run. If the scan is clean, proceed without comment.

Then check the ledger (below) and resume at the first ticket not marked complete.

### 1. Pick the frontier

Any ticket whose blockers are all closed. If several qualify, take them in dependency order. **Never dispatch two implementers in parallel** — they conflict in the working tree.

### 2. Generate the brief

Run `/brief` for that ticket. It produces `.scratch/<feature>/brief-NN.md` with Files, Interfaces, Verify, and Run as — and it will refuse to finish without a verified `Verify` command.

Carry the previous ticket's `Produces` block into this one's `Consumes` verbatim. That is the only thing preventing slice 3's `clearLayers` from becoming slice 7's `clearAllRules`.

### 3. Dispatch the implementer

Honour the brief's **Run as**:

| Run as | Meaning |
|---|---|
| `[inline]` | Do it in this session. No dispatch. |
| `[subagent:cheap]` | Fast, cheap model. The brief leaves nothing to decide. |
| `[subagent:standard]` | Standard model. Multiple files, integration concerns. |

**Always specify the model explicitly.** An omitted model inherits this session's — usually the most expensive one — which silently defeats the whole point.

Turn count beats token price: a cheap model that takes 3× the turns costs more. Cheap tier only when the brief is transcription plus tests.

Use [implementer-prompt.md](implementer-prompt.md). Record the current commit SHA **before** dispatching — that's the review base.

### 4. Handle the status

**DONE** — proceed to review.

**DONE_WITH_CONCERNS** — read the concerns first. Correctness or scope concerns get addressed before review. Observations ("this file is getting large") get noted and carried to the review.

**NEEDS_CONTEXT** — supply what was missing and re-dispatch. Then ask why the brief didn't carry it, and fix `/brief`'s output for the next ticket.

**BLOCKED** — assess:
1. Context problem → provide more, re-dispatch same model
2. Needs more reasoning → re-dispatch on a more capable model
3. Ticket too large → split it; the slice was wrong
4. The ticket itself is wrong → escalate to the human

**Never** ignore an escalation or force the same model to retry unchanged. If the implementer said it's stuck, something has to change.

### 5. Review

Run `/verified-review` with the fixed point set to the SHA you recorded in step 3 — **never `HEAD~1`**, which silently drops all but the last commit of a multi-commit ticket.

It runs `Verify` itself, then the Standards and Spec axes in parallel. All three must pass.

**If the implementer's report claimed the command passed and it goes red, that discrepancy is a finding in its own right** — the report is not load-bearing, and its other claims are now suspect.

Dispatch **one** fix subagent with the complete findings list, not one fixer per finding — per-finding fixers each rebuild context and re-run suites. Every fix dispatch carries the implementer contract: re-run the tests covering the change, report the command and its output. Then re-review.

A finding that conflicts with what the ticket mandates is the human's decision: present the finding and the ticket text, ask which governs. Don't dismiss the finding, and don't dispatch a fix that contradicts the ticket without asking.

### 6. Close out the ticket

**A ticket is closed by `/verified-review` passing — nothing else.** No review, or a review not green on all three axes (Verify, Standards, Spec), means the ticket stays open. The implementer's `DONE` is never a close condition; it only unlocks step 5.

- Mark it done on the tracker (`docs/agents/issue-tracker.md` says how) or check the boxes in the local file
- Append one line to the ledger — it **must** carry all three verdicts (see Durable progress). A line that cannot state them is proof the review didn't run, and the ticket is not done.
- Delete nothing from `.scratch/` yet — `finish-branch` harvests it

Then back to step 1.

### 7. When the frontier is empty

Run `/verified-review` once over the whole branch (fixed point = `git merge-base main HEAD`), on the most capable model. Point it at the Minor findings the ledger accumulated so it can triage what must be fixed before merge.

Then `finish-branch`.

## Durable progress

Conversation memory does not survive compaction. Controllers that lost their place have re-dispatched entire completed sequences — the single most expensive failure mode there is.

```
.scratch/<feature>/ledger.md
```

- At skill start, read it. Tickets marked complete are **done** — do not re-dispatch. Resume at the first one that isn't.
- When `/verified-review` comes back clean, append: `Ticket NN: complete (commits <base7>..<head7>, Verify green, Standards ✓, Spec ✓)`. All three verdicts are mandatory — the line is the review's receipt. A missing verdict means the ticket is **not** closed, because the review that produces it didn't complete.
- Record Minor findings there as you go, for the final review to triage. A roll-up nobody reads is a silent discard.
- After any compaction, trust the ledger and `git log` over your own recollection.
- `git clean -fdx` destroys it (it's gitignored). If that happens, recover from `git log`.

## File handoffs

Everything pasted into a dispatch and everything a subagent prints back stays resident in your context for the rest of the session, re-read every turn. Move artifacts as **files**:

- **Brief** — the implementer reads `.scratch/<feature>/brief-NN.md`. It is the single source of requirements. Exact values (numbers, magic strings, signatures) appear **only** there.
- **Report** — name it after the brief (`brief-03.md` → `report-03.md`). The implementer writes the full report there and returns only status, commits, a one-line test summary, and concerns.
- **Review inputs** — `/verified-review` gets the brief path, the report path, and the fixed point.
- **Fix dispatches** append to the same report file and return a short summary.

A dispatch prompt describes **one ticket**, not the session's history. Never paste accumulated prior-ticket summaries into later dispatches — a real session's dispatch reached 42k characters of which 99% was pasted history. A fresh subagent needs its brief, its interfaces, and the global constraints. Nothing else.

## Why review re-runs the command

Upstream SDD forbids it:

> *"Do not ask a reviewer to re-run tests the implementer already ran on the same code — the implementer's report carries the test evidence."*
> — superpowers, `subagent-driven-development/SKILL.md:166`

An implementer's report is a hypothesis, not evidence. superpowers contradicts itself here — `verification-before-completion` names "trusting agent success reports" a red flag, and SDD is built on that trust. Running one command costs seconds; finding out at merge that the report was optimistic costs the branch.

## Red flags

**Never:**
- Mark a ticket complete without a passing `/verified-review` — the ledger line carries `Verify green, Standards ✓, Spec ✓`, or the ticket isn't closed
- Start on `main`/`master` without explicit consent
- Dispatch two implementers in parallel
- Dispatch an implementer without a brief, or with a brief whose `Verify` is unverified
- Use `HEAD~1` as the review base
- Skip the review, or accept a review missing any of Verify / Spec / Standards
- Move to the next ticket with open Critical or Important findings
- Re-dispatch a ticket the ledger already marks complete
- Tell a reviewer what not to flag, or pre-rate a finding's severity
- Paste prior-ticket history into a dispatch
- Let the implementer's self-review replace the review — both are needed
- Write a brief for a ticket with open blockers

**Related:** `/brief` feeds each dispatch · `/verified-review` is the gate · `/finish-branch` closes the run · `/using-git-worktrees` provides the isolated workspace · `/tdd` is what implementers follow inside each ticket
