Changing code in this repo? Two gates bracket EVERY change — Tier 1 fixes included. They are the floor, not the process. The full map is `/route-me`; the *why* is STACK.md.

**GATE IN — plan before you edit.** Present the plan and get the user's explicit "go" before touching a line: a few lines in chat (what changes, which files, how you'll verify) — not a spec, not an artifact. "Too small to plan" is exactly where a wrong assumption costs the most.

**GATE OUT — review before you're done.** A change is not done until `/verified-review` has run: the reviewer runs the Verify command *itself* (red before, green after) and checks Standards + Spec. "It's small, I'll eyeball it" is not review.

Not touching code — a question, a doc, a plain chat? Ignore this; the gates are for changes.

Rationalizations that mean STOP — you're talking yourself past a gate:
- "It's a one-liner, I'll just do it" → the gate is the plan, not the size.
- "I'll plan as I go" → the plan is presented *before* the edit, or it isn't a gate.
- "I can eyeball this fix" → eyeballing is not `/verified-review`.
- "I'll review once I'm done" → review is *how* you become done.
