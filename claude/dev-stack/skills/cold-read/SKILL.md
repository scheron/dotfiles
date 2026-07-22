---
name: cold-read
description: Read a finished spec and its tickets from the position the implementer will occupy — no planning context — and report what was understood. Surfaces drift between what you meant and what the artifact says, while fixing is still free. Use after /to-tickets and before any implementation.
disable-model-invocation: true
---

# Cold Read

The spec is written by an agent that sat through the whole grilling session. It carries the conversation whether or not it carries the decisions. The implementer reads it **cold**.

So nobody ever reads the artifact from the position the implementer actually occupies — and decisions quietly widen or go missing somewhere between the interview and the ticket. You find out at code review, after a branch was built on the misreading.

This skill puts one reader in that position on purpose, before any code exists, when the gap is free to close.

## When

After `/to-tickets`, before the first `/brief`. Once per feature.

Skip it when the grilling was short and the decisions few — on three tickets it's overhead. It earns its cost when the interview was long, the decision tree branched, or the feature touches an area with existing ADRs.

## The construction

**You know why the reader is reading. The reader must not.**

This skill runs the reader as a subagent with a plain comprehension prompt. Three things stay out of that prompt, because each one changes what comes back:

- **It is never asked to audit, review, or find ambiguities.** Asked for problems, a model manufactures them. Asked what it understood, the ambiguities surface on their own — as the places it had to pick.
- **It produces no verdict.** No readiness grade, no score, no "looks good to me". A verdict gives it something to justify, and justification bends the reading.
- **It is not told why it is reading.** Not that it's a cold reader, not that its answer will be checked against a decision it cannot see. An agent that knows drift is being hunted will produce drift.

It reads like a comprehension task. It has no idea it is an instrument.

## Process

### 1. Collect the artifact set

The spec, every ticket, and nothing else. **Not** `CONTEXT.md`, **not** the ADRs, **not** the conversation.

This is deliberate: the implementer will have the glossary and the ADRs, but they are durable and independently verified. What's under test here is whether the *feature-specific* decisions made it into the *feature-specific* artifact. Handing over the durable layer masks exactly the gap you're looking for.

### 2. Dispatch the reader

One `general-purpose` subagent, fresh context, on a standard model. It must not inherit this session.

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

- **Section 3 is populated** — the ticket genuinely reads more than one way. This is the highest-value finding: the implementer *will* pick, and it may not pick your reading.
- **Section 1 misses the point** — the spec's Problem Statement is not carrying. Everything downstream inherits this.
- **Section 2 rebuilds something you already rejected** — a decision from the grill never reached the artifact. Check whether it deserved an ADR; if it was hard to reverse, surprising, and a real trade-off, it did, and its absence is the real bug.

### 4. Fix the artifact, not the reader

Amend the spec or the tickets. Then decide whether to re-read: a second pass is worth it only if you changed something structural, not for wording.

Findings that turn out to be **decisions never recorded anywhere** go to `/domain-modeling` — a term that keeps sliding belongs in `CONTEXT.md`, a trade-off that keeps being re-litigated belongs in an ADR. Fixing the spec alone means re-fixing it next feature.

## Why not just re-read it yourself

You can't. You were in the grilling session. You will read the intended meaning into an ambiguous sentence every time, because you know which reading is right — that's precisely the knowledge the artifact is supposed to carry and you cannot un-know it while checking whether it does.

The cold reader isn't smarter than you. It's ignorant in exactly the way the implementer will be.

## Red flags

**Never:**
- Give the reader `CONTEXT.md`, the ADRs, or any of the conversation
- Tell the reader it's checking for drift, or that a warm session wrote the spec
- Ask it to rate, grade, audit, or find problems
- Run it in this session, or on a subagent that inherited this context
- Argue with the report — the reader is a measurement, not a reviewer. If it misread, the artifact permitted the misreading.
- Run it after implementation starts — the whole value is that fixing is free before code exists

**Related:** `/brief` is the next step for each frontier ticket · `/to-spec` and `/to-tickets` produce the artifacts this reads · `/domain-modeling` owns findings that outlive this feature
