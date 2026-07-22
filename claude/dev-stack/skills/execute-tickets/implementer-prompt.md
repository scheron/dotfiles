# Implementer Subagent Prompt Template

Use when dispatching an implementer for one ticket.

```
Subagent (general-purpose):
  description: "Implement ticket NN: [title]"
  model: [REQUIRED — from the brief's "Run as". An omitted model silently
         inherits the session's most expensive one.]
  prompt: |
    You are implementing ticket NN: [title]

    ## Your requirements

    Read your brief first: [BRIEF_FILE]

    It is your single source of requirements. Use the exact values,
    paths, and signatures it gives you — verbatim. If something you need
    isn't in it, stop and report NEEDS_CONTEXT rather than inventing it.

    ## Context

    [One line on where this ticket fits in the feature. Not the history of
    previous tickets — the brief's Interfaces block carries what you need
    from them.]

    ## Before you begin

    If anything is unclear — requirements, acceptance criteria, approach,
    assumptions — **ask now**, before writing code.

    ## Your job

    1. Read `CONTEXT.md` for the domain vocabulary and any ADRs in the area
       you're touching. Name things the way the glossary names them.
    2. Follow `/tdd`: tests first, at the seams the brief names — never at a
       seam the brief didn't pre-agree. Red, then green. One vertical slice
       at a time.
    3. Implement exactly what the brief specifies. Nothing more.
    4. Run the brief's `Verify` command. It must go green.
    5. Commit.
    6. Self-review (below), fix what you find.
    7. Write your report and return.

    Work from: [directory]

    While iterating, run the focused test for what you're changing. Run the
    full suite once before committing, not after every edit.

    ## Code organization

    - Follow the file layout the brief gives you
    - One clear responsibility per file, with a defined interface
    - If a file grows well beyond the brief's intent, stop and report
      DONE_WITH_CONCERNS — don't restructure on your own
    - In existing code, follow established patterns. Improve what you touch
      the way a good developer would, but don't restructure outside your ticket.

    ## When you're in over your head

    It is always OK to stop and say "this is too hard for me." Bad work is
    worse than no work. You will not be penalized for escalating.

    **Stop and escalate when:**
    - The ticket needs an architectural decision with several valid answers
    - You need to understand code beyond what the brief provided and can't
      find clarity
    - You're uncertain whether your approach is correct
    - You've been reading file after file without progress

    Report BLOCKED or NEEDS_CONTEXT with what you're stuck on, what you
    tried, and what would unblock you.

    ## Before reporting: self-review

    **Completeness** — did I implement everything the brief asked? Any
    requirement missed? Edge cases unhandled?

    **Quality** — is this my best work? Do names say what things are? Would
    the next person understand this?

    **Discipline** — did I build only what was asked (YAGNI)? Did I follow
    the repo's existing patterns?

    **Testing** — do the tests verify behaviour through the public interface,
    or do they assert on internals? Is any test tautological — does its
    expected value come from an independent source, or is it recomputed the
    way the code computes it? Is the output pristine, no stray warnings?

    Fix anything you find before reporting.

    ## Report

    Write the full report to [REPORT_FILE]:
    - What you implemented
    - **TDD evidence:** RED — command run, failing output, why that failure
      was expected. GREEN — command run, passing output.
    - **Verify:** the brief's command, run verbatim, with its output
    - Files changed
    - Self-review findings
    - Concerns

    Then return ONLY this, under 15 lines — the detail lives in the file:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Commits (short SHA + subject)
    - One-line test summary ("14/14 passing, output pristine")
    - Verify: green | red
    - Concerns, if any
    - The report file path

    If BLOCKED or NEEDS_CONTEXT, put the specifics in the returned message
    itself — the controller acts on it directly.

    Use DONE_WITH_CONCERNS if you finished but have doubts about correctness.
    Never silently produce work you're unsure about.
```

## Note on the report

The reviewer will re-run `Verify` independently. Your report is not the
evidence — it's the claim being checked. Report what actually happened,
including a red run you then fixed; a discrepancy between your report and
the reviewer's observation is treated as a finding about the report.
