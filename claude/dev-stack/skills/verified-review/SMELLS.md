# The smell baseline

Fowler's code smells (*Refactoring*, ch. 3). They apply even when a repo documents nothing, which is why this is a baseline rather than a standard.

Two consumers read this file, and both pass its **path** rather than its contents: the **task reviewer**, judging smells inside one task's diff, and `/verified-review`'s **Standards axis**, judging the ones that only appear across tasks. One file so the two never drift apart.

## Two rules bind every use

- **The repo overrides.** A documented standard always wins; where it endorses something this baseline would flag, suppress the smell.
- **Always a judgement call.** Each entry is a labelled heuristic ("possible Feature Envy"), never a hard violation. Skip anything tooling already enforces.

## Visible inside one task's diff

The task reviewer owns these.

- **Mysterious Name** — a name that doesn't reveal what it does or holds. → rename; if no honest name comes, the design is murky.
- **Primitive Obsession** — a primitive standing in for a domain concept. → give the concept its own small type.
- **Data Clumps** — the same few fields keep travelling together. → bundle them into one type.
- **Feature Envy** — a method reaching into another object's data more than its own. → move it onto the data it envies.
- **Repeated Switches** — the same cascade on the same type recurs. → polymorphism, or one shared map.
- **Message Chains** — long `a.b().c().d()` the caller shouldn't depend on. → hide the walk.
- **Middle Man** — a unit that mostly delegates onward. → cut it.
- **Refused Bequest** — a subclass ignoring most of what it inherits. → composition.
- **Speculative Generality** — abstraction for needs the spec doesn't have. → delete it.

## Visible only across tasks or across the system

The Standards axis owns these — a task reviewer looking at one layer's diff structurally cannot see them.

- **Duplicated Code** — the same logic shape in more than one hunk or file. Two implementers working separate layers of one slice, neither seeing the other, is the case that produces it.
- **Shotgun Surgery** — one logical change forces scattered edits.
- **Divergent Change** — one module edited for several unrelated reasons.
