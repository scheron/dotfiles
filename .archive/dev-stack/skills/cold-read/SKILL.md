---
name: cold-read
description: Read a finished spec and its tickets from the position the brief-writer will occupy — no planning context — and report what was understood. Surfaces drift between what you meant and what the artifact says, while fixing is still free. Use after /to-tickets and before any implementation.
---

# Cold Read

The spec is written by an agent that sat through the whole grilling session. It carries the conversation whether or not it carries the decisions. The **brief-writer** reads it cold — and it is the brief-writer's reading that turns the ticket into the tasks everything downstream executes.

This skill puts one reader in that position on purpose, before any code exists, when the gap is free to close.

**No gate.** This is the last point where fixing a spec is free, so asking whether to run it buys nothing. Run it and report.

## When

After `/to-tickets`, before the first `/brief`. Once per feature. **Required** on a Tier 2 spec.

One rule decides the exception, not a question to the user: **skip only when the grill ran short and the tickets number three or fewer.** Below that line it is overhead. It earns its cost when the interview was long, the decision tree branched, or the feature touches an area with existing ADRs.

Its counterpart one level down is the brief check in `/to-implement`: cold-read catches **spec → ticket** drift, the brief check catches **ticket → brief** drift. Same instrument, two levels — neither replaces the other.

## The construction

**You know why the reader is reading. The reader must not.** Three rules, and each one changes what comes back:

- **Never ask it to audit, review, or find ambiguities.** Asked for problems, a model manufactures them. Asked what it understood, the ambiguities surface on their own — as the places it had to pick.
- **Take no verdict.** No readiness grade, no score, no "looks good to me" — a verdict gives it something to justify, and justification bends the reading.
- **Never tell it why it is reading.** An agent that knows drift is being hunted will produce drift.

It reads like a comprehension task. It has no idea it is an instrument.

## Process

### 1. Collect the artifact set

The spec, every ticket, and nothing else. **Not** `CONTEXT.md`, **not** the ADRs, **not** the conversation.

This is deliberate: the brief-writer will have the glossary and the ADRs, but they are durable and independently verified. What's under test here is whether the *feature-specific* decisions made it into the *feature-specific* artifact. Handing over the durable layer masks exactly the gap you're looking for.

### 2. Dispatch the reader

One `general-purpose` subagent, fresh context, on the session's default model — no override. It must not inherit this session.

Prompt it with only the artifact paths and this:

> Read the spec and tickets at the paths below. Report three things.
>
> 1. **Purpose** — one paragraph, in your own words: what is this feature for?
> 2. **What you would build** — per ticket: the files you'd expect to touch, the shape of the change, and the behaviour that exists at the end.
> 3. **Where you had to choose** — any ticket that reads more than one way, and the readings you picked between.
>
> Do not evaluate the documents. Do not rate readiness. Report only what you understood.

### 3. Read the report against what you meant

You hold the decisions. The subagent's report is the artifact's actual signal strength. The gap between them is the drift.

Three signals, in descending order of cost:

- **Section 3 is populated** — the ticket genuinely reads more than one way. This is the highest-value finding: the brief-writer *will* pick, and it may not pick your reading — and its pick becomes the tasks.
- **Section 1 misses the point** — the spec's Problem Statement is not carrying. Everything downstream inherits this.
- **Section 2 rebuilds something you already rejected** — a decision from the grill never reached the artifact. Check whether it deserved an ADR; if it was hard to reverse, surprising, and a real trade-off, it did, and its absence is the real bug.

### 4. Fix the artifact, not the reader

Amend the spec or the tickets. Then decide whether to re-read: a second pass is worth it only if you changed something structural, not for wording.

Findings that turn out to be **decisions never recorded anywhere** go to `/domain-modeling` — a term that keeps sliding belongs in `CONTEXT.md`, a trade-off that keeps being re-litigated belongs in an ADR. Fixing the spec alone means re-fixing it next feature.

## Red flags

**Never:**
- Give the reader `CONTEXT.md`, the ADRs, or any of the conversation
- Tell the reader it's checking for drift, or that a warm session wrote the spec
- Ask it to rate, grade, audit, or find problems
- Run it in this session, or on a subagent that inherited this context
- Argue with the report — the reader is a measurement, not a reviewer. If it misread, the artifact permitted the misreading.
- Run it after implementation starts — the whole value is that fixing is free before code exists

**Related:** `/brief` is the next step for each frontier ticket · `/to-spec` and `/to-tickets` produce the artifacts this reads · `/domain-modeling` owns findings that outlive this feature
