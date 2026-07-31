---
name: ds-grill
description: Interview an idea into a shared understanding before anything is planned. Ends in alignment and a stop — no document, no code. Invoke when the task is not yet clear enough to plan.
disable-model-invocation: true
---

# Grilling an idea into a shared understanding

Turn an idea into a design both of you actually agree on, through questions.

The output is **alignment**, and then a stop. No spec file, no plan, no code. If
the work turns out to need more than one plan, `ds-spec` writes the document; if
it needs one, the alignment lands in that plan's header.

**Announce at start:** "Using ds-grill to work out what we are building."

<HARD-GATE>
Do not write code, scaffold anything, or invoke an implementation skill from
here. This applies to every task regardless of how simple it looks.
</HARD-GATE>

## Depth scales; the alignment does not

A clear rearrangement of two buttons does not need a long design interview. A new
subsystem does. What does not scale is *whether* you and the human end up meaning
the same thing — that is required either way, and on a small task it may take one
restatement and a yes.

"This is too simple to need a design" is where unexamined assumptions do their
most expensive work. Keep the design short instead of skipping it.

## The process

1. **Look at the project first.** Files, docs, recent commits. Checking a premise
   — does that component exist, where does the theme live — is part of grilling,
   not a reason to reach for another skill. Reach for `ds-scout` only when you
   genuinely need a map of unfamiliar territory.
2. **Check the scope early.** If the request describes several independent
   subsystems, say so before spending questions on the details of something that
   has to be decomposed first.
3. **Ask one question per message.** Multiple choice where it fits, open where it
   does not. Aim at purpose, constraints, and what success looks like.
4. **Offer two or three approaches** with their trade-offs, lead with the one you
   recommend and say why. Cut ruthlessly — every approach loses whatever nobody
   asked for.
5. **Present the design in sections**, each scaled to its own complexity: a few
   sentences where it is straightforward, a couple of hundred words where it is
   not. Ask after each whether it still looks right.
6. **Cover** the shape of the thing, how the pieces talk, what happens when it
   fails, and how it will be checked.

Be ready to go back. A question that lands badly usually means an earlier answer
was understood differently by the two of you.

## Designing so it can be built and checked

- Break the system into units with one clear purpose each, talking through
  well-defined interfaces, understandable and testable on their own.
- For each unit you should be able to say what it does, how it is used, and what
  it depends on. If you cannot say what it does without describing its internals,
  the boundary is in the wrong place.
- In an existing codebase, follow the patterns already there. Where existing code
  genuinely gets in the way of this work, include the targeted improvement in the
  design — the way a careful developer improves the code they are working in. Do
  not propose unrelated refactoring.

## Where this ends

Present the design, take approval, then **stop** and say what the next step is:

- the work fits one plan → the human invokes `ds-plan`;
- the work needs several → the human invokes `ds-spec`, which writes the shared
  document and the list of plans.

**You invoke neither.** The human decides when to move on, and how much process
the work gets. Same rule as everywhere else here: the model proposes, the human
calls.

Nothing is written to a file. Vocabulary and hard-to-reverse decisions that
deserve to outlive the conversation belong to `ds-grill-with-docs`, which is a
separate skill precisely because it leaves a durable artifact and this one does
not.

## Visual companion

A browser companion for showing mockups, diagrams and visual options during the
interview. A tool, not a mode: accepting it means it is available for the
questions that benefit, not that every question goes through a browser.

**Offer it just in time, never up front.** Wait until a question would genuinely
be clearer shown than told — a real mockup, layout or diagram question, not
merely a UI *topic*. The first time that happens, offer it as **its own message**,
with nothing else in it:

> "This next part might be easier if I show you — I can put together mockups,
> diagrams and comparisons in a browser tab as we go. It's still new and can be
> token-intensive. Want me to? I'll open it for you."

Wait for the answer. If they accept, start the server with `--open`. If they
decline, continue text-only and do not offer again unless they raise it.

**Decide per question even after they accept.** The test: would they understand
this better by seeing it than by reading it? Mockups, wireframes, layout
comparisons, architecture diagrams — browser. Requirements, conceptual choices,
trade-off lists, scope decisions — terminal. A question about a UI topic is not
automatically a visual question.

If they accept, read [visual-companion.md](visual-companion.md) before going on.
