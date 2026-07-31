---
name: ds-bootstrap
description: Injected at session start. States one rule — do not start building a task silently — and names the entries that exist.
disable-model-invocation: true
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to do a specific job, ignore this. Your
brief is your instructions.
</SUBAGENT-STOP>

# Before you start building

There is a workflow in this environment for turning a task into reviewed,
integrated code. It is invoked **by the human, never by you.**

## The one rule

```text
a pinpoint edit in a place the human named   → just do it
anything that looks like a task              → stop and offer the route
```

Do not begin implementing a task off a bare prompt. Say what you would reach for,
and let them call it:

> "This looks like a task rather than a one-line edit. `ds-grill` to work out
> what we're building, then `ds-plan` — say the word."

That is the whole rule. You are not routing anything and you are not invoking
anything.

The boundary between "pinpoint edit" and "task" is your judgement, and it will
sometimes be wrong. It is a cheap kind of wrong: it shows up as one unnecessary
question, not as a context filled with work nobody asked for.

## What exists

Entries — the human types one:

| | |
|---|---|
| `ds-grill` | the task is not clear yet; interview it into a shared understanding |
| `ds-grill-with-docs` | same, and it also captures vocabulary and earned ADRs |
| `ds-bug` | a bug: reproduce, find the cause, pin it with a failing test |
| `ds-scout` | explain how existing code works; read-only |
| `ds-refactor` | restructure, migrate, upgrade — behaviour must not change |
| `ds-tests` | the tests are the deliverable: cover code, or repair tests that lie |

Then the pipeline: `ds-spec` (only when the work needs more than one plan) →
`ds-plan` → `ds-implement` → `ds-finish`.

Outside a run: `ds-review`, `ds-improve`, `ds-research`, `ds-prototype`,
`ds-domain-modeling`.

`ds-bug` is the one entry you may reach for yourself — a bug arrives as a
symptom, and the mistake it prevents happens in the first reply.

## Why you are being told this

Not only to stop you. Over time it is easy to forget a skill exists at all, and a
route nobody remembers is a route nobody uses. Naming the option is half the
point.

## What this is not

There is no rule here that a skill must be invoked whenever one might apply. That
rule, together with the reading that questions are tasks too, is what produced
false starts — skills firing on questions, on small edits, on anything at all. It
is gone deliberately. Do not reconstruct it.

The human's instructions — `CLAUDE.md`, and whatever they just said — outrank all
of this.
