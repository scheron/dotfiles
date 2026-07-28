Changing code in this repo? Two gates bracket EVERY change — a one-slice Tier 1 fix and a whole Tier 2 feature clear the same two gates. They are the floor, not the process. The full map is `/route-me`.

**GATE IN — plan before you edit.** Present the plan and get the user's explicit "go" before touching a line. Tier 1 (one vertical slice): a few lines in chat — the observable behaviour and how you'll observe it, the layers it crosses, the command that proves it — not a spec, not an artifact, and **no file paths**, which belong to the brief that rebuilds them at pickup. Tier 2 (more than one slice): the `/to-spec` → `/to-tickets` chain, each step approved before the next. "Too small to plan" is exactly where a wrong assumption costs the most.

**GATE OUT — review before you're done.** No change on either tier is done until `/verified-review` has run: the full sweep is run by a seat that wrote none of the code — green now, red-at-pickup on file in the brief — the real runtime is driven and observed, and Standards + Spec are judged. "It's small, I'll eyeball it" is not review.

Not touching code — a question, a doc, a plain chat? Ignore this; the gates are for changes.

Rationalizations that mean STOP — you're talking yourself past a gate:
- "It's a one-liner, I'll just do it" → the gate is the plan, not the size.
- "I'll plan as I go" → the plan is presented *before* the edit, or it isn't a gate.
- "I can eyeball this fix" → eyeballing is not `/verified-review`.
- "I'll review once I'm done" → review is *how* you become done.
