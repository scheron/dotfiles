---
name: diagnose
description: Diagnosis loop for hard bugs and performance regressions — feedback loop first, then reproduce, minimise, pattern-analyse, rank hypotheses, instrument, fix. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

# Diagnose

A discipline for hard bugs. Skip phases only when explicitly justified.

When exploring the codebase, read `CONTEXT.md` (if it exists) for a clear mental model of the relevant modules, and check ADRs in the area you're touching.

> Fork of Matt Pocock's `diagnosing-bugs` (MIT), with two grafts from superpowers' `systematic-debugging` (MIT): **Phase 2.5 Pattern Analysis** and the **three-fix breaker** in Phase 5.

## Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. With a **tight** pass/fail signal that goes red on *this* bug, you will find the cause — bisection, hypothesis-testing, and instrumentation all just consume it. Without one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one — roughly in this order

1. **Failing test** at whatever seam reaches the bug.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** — drives the UI, asserts on DOM/console/network.
5. **Replay a captured trace.** Save a real request/payload/event log, replay it through the path in isolation.
6. **Throwaway harness.** Minimal subset of the system that hits the bug path in one call.
7. **Property / fuzz loop.** For "sometimes wrong output": 1000 random inputs, look for the mode.
8. **Bisection harness.** Automate "boot at state X, check, repeat" so `git bisect run` works.
9. **Differential loop.** Same input through old vs new (or two configs), diff outputs.
10. **HITL bash script.** Last resort — if a human must click, drive *them* so the loop stays structured.

### Tighten the loop

Treat the loop as a product. Once you have *a* loop: make it faster (cache setup, narrow scope), sharper (assert the specific symptom, not "didn't crash"), more deterministic (pin time, seed RNG, isolate filesystem, freeze network).

A 30-second flaky loop is barely better than none; a 2-second deterministic one is a superpower.

### Non-deterministic bugs

The goal is not a clean repro but a **higher reproduction rate**. Loop 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; 1% is not.

### Completion criterion

Phase 1 is done when you can name **one command** you have **already run at least once** (paste the invocation and its output) that is:

- [ ] **Red-capable** — drives the actual bug path and asserts the **user's exact symptom**. Not "runs without erroring".
- [ ] **Deterministic** — same verdict every run.
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — runs unattended.

If you catch yourself reading code to build a theory before this command exists — **stop. Jumping to a hypothesis is the exact failure this skill prevents.** No red-capable command, no Phase 2.

### When you genuinely cannot build one

Say so explicitly. List what you tried. Ask for: (a) access to an environment that reproduces it, (b) a captured artifact (HAR, log dump, core dump, timestamped recording), or (c) permission to add temporary production instrumentation. Do **not** hypothesise without a loop.

## Phase 2 — Reproduce + minimise

Run the loop. Watch it go red.

- [ ] The failure is the one the **user** described — not a different one nearby. Wrong bug = wrong fix.
- [ ] Reproducible across runs (or at a high enough rate to debug against).
- [ ] The exact symptom is captured, so later phases can verify the fix addresses it.

### Minimise

Shrink to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, steps — one at a time, re-running after each cut.

Done when **every remaining element is load-bearing**: removing any one makes it go green.

A minimal repro shrinks the hypothesis space in Phase 3 and becomes the regression test in Phase 5. Do not proceed until you have reproduced **and** minimised.

## Phase 2.5 — Pattern analysis

*Grafted from superpowers' `systematic-debugging`.*

Before hypothesising, look for **something similar that works**. Almost every codebase already contains a working instance of the thing that's broken — a sibling endpoint, another consumer of the same hook, a parallel migration, the same widget on a different screen.

1. Find the closest working analogue **in this repo**.
2. Write down **every** difference between it and the broken path — imports, config, ordering, lifecycle, types, wrappers, environment. All of them, before judging any.
3. Only then rank which differences could plausibly produce the observed symptom.

The discipline is in the *exhaustive listing*. The cause is routinely a difference you'd have dismissed as irrelevant if you'd been filtering while you looked.

If there is genuinely no working analogue, say so and move on — that absence is itself information: nothing in this codebase does this correctly yet.

## Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any. Single-hypothesis generation anchors on the first plausible idea.

Each must be **falsifiable** — state its prediction:

> "If \<X\> is the cause, then \<changing Y\> will make the bug disappear / \<changing Z\> will make it worse."

If you cannot state the prediction, it's a vibe — discard or sharpen it.

Differences surfaced in Phase 2.5 are hypothesis material: each unexplained difference is a candidate.

**Show the ranked list to the user before testing.** They often re-rank instantly ("we deployed a change to #3 yesterday") or know what's already ruled out. Cheap checkpoint, big saver. Don't block on it — proceed with your ranking if they're AFK.

## Phase 4 — Instrument

Each probe maps to a specific prediction from Phase 3. **Change one variable at a time.**

1. **Debugger / REPL** if the environment supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]` — cleanup becomes one grep. Untagged logs survive; tagged logs die.

**Perf branch.** For performance regressions logs are usually wrong. Establish a baseline measurement (timing harness, profiler, query plan), then bisect. Measure first, fix second.

## Phase 5 — Fix + regression test

Write the regression test **before the fix** — but only if a **correct seam** exists.

A correct seam exercises the **real bug pattern as it occurs at the call site**. If the only available seam is too shallow (a single-caller test when the bug needs several, a unit test that can't replicate the triggering chain), a test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it — the architecture is preventing the bug from being locked down.

With a correct seam:

1. Turn the minimised repro into a failing test there.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 loop against the original, un-minimised scenario.

### The three-fix breaker

*Grafted from superpowers' `systematic-debugging`.*

**If three fix attempts have failed, stop fixing.** Do not attempt a fourth.

Three failures is not bad luck — it means the model of the system you're working from is wrong, and further attempts are guesses dressed as iteration. Escalate to an architectural conversation: state the symptom, the three attempts, and why each failed. That report is more valuable than a fourth attempt, and it's what `/improve-codebase-architecture` needs.

Count attempts explicitly. Under time pressure this is the rule that gets silently skipped, which is exactly when it pays.

## Phase 6 — Cleanup + post-mortem

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or the absence of a seam is documented)
- [ ] All `[DEBUG-...]` instrumentation removed (grep the prefix)
- [ ] Throwaway harnesses deleted or moved somewhere clearly marked
- [ ] The hypothesis that turned out correct is stated in the commit message — so the next debugger learns

**Then ask: what would have prevented this?** If the answer is architectural (no good seam, tangled callers, hidden coupling), surface it, with the specifics, as a finding for `/improve-codebase-architecture`. Make that recommendation **after** the fix is in — you know more now than when you started.

If a decision came out of this that is hard to reverse, surprising without context, and the result of a real trade-off, it's an ADR. `/domain-modeling` owns that.

**Related:** `/verified-review` shares the agent-runnable-command criterion · `/improve-codebase-architecture` receives the no-seam and three-fix findings
