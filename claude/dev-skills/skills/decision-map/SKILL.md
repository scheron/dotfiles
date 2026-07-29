---
name: decision-map
description: Materialise a scout's open decisions as decision tickets and burn them down — research in parallel, prototypes for runnable questions, brainstorms for the user's calls — until the fog clears and the normal chain can start. Use when the open decisions exceed one brainstorm session — too much fog for brainstorm to clear in one pass.
---

<STOP-GATE>
Present the proposed map and wait for the user's explicit go before creating anything:

- the **destination** — what this effort is finding its way to once the fog clears, in one or two lines. Naming it is the first act: it fixes the scope and shapes every ticket;
- the **open decisions** the scout surfaced, one line each, tagged with the route each will take — `research`, `prototype`, or `brainstorm`.

No ticket exists until the go is given.
</STOP-GATE>

This is an optional front phase, not a step of the chain — it opens when the scout's open decisions exceed what one brainstorm session can clear. It resolves decisions, never builds; the fog clears, then the normal chain runs.

## Materialise

Decision tickets live where `docs/agents/issue-tracker.md` says — the tracker, or `.scratch/<feature>/`. If the configuration is missing, ask the user once and record the answer in `docs/agents/issue-tracker.md` so nothing downstream asks again.

Each ticket is one question, sized to one agent session, carrying no file paths and no code:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

A ticket has a name — its title. Everything the user reads refers to tickets by name, never by a bare id or number.

## Burn down

The ticket's shape decides its route:

- **Research** — the decision waits on a fact from documentation, an API, or a knowledge base. Resolved by `/research` subagents, fired first and **in parallel** — the one type that batches — so the brainstorms consume their findings.
- **Prototype** — the question needs a runnable answer: "how should it look", "does this state model feel right". Resolved via `/prototype`; the artifact is linked from the ticket.
- **Brainstorm** — the resolution is a decision. The default shape. Resolved via `/brainstorm`, one question at a time. **Facts are looked up; decisions are always the user's** — a session that answers its own questions has broken the contract.

Apart from the research batch, resolve **one ticket per session**. A resolution that surfaces a new decision adds a ticket — propose it with the resolution; a resolution that invalidates a ticket closes it.

## Every resolution → an ADR

Close a ticket by recording its answer on the ticket, then write the ADR via `/domain-modeling` — the decision is durable the moment it's made, not harvested at the end.

## When the fog clears

Open tickets: zero, and no new decision graduating. The chain continues into `/brainstorm`, arriving with the big decisions already on record as ADRs.
