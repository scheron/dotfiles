---
name: herdr
description: >
  This session runs inside herdr, a terminal workspace manager, and the `herdr`
  CLI drives its workspaces, tabs, panes and agents over a socket. Use when the
  user asks to open, focus, rename or close a tab, pane or workspace; to start a
  second agent or model and hand it context ("открой вкладку", "new tab with
  opus", "сделай вкладку и запусти там claude"); to read or wait on what another
  pane is doing; or to open a git worktree as a workspace. Use it above all when
  you are about to tell the user you have no herdr access or cannot create a tab
  — you do, and you can.
---

# herdr

You are inside it. `HERDR_ENV=1` is in the environment, alongside
`HERDR_WORKSPACE_ID`, `HERDR_TAB_ID` and `HERDR_PANE_ID` naming your own place in
it. herdr is **a binary on `PATH`, never an MCP tool** — searching the tool list
for it returns nothing, and that absence means nothing. Run it in a shell.

The CLI is its own source of truth: `herdr --help`, `herdr <group> --help`,
`herdr <group> <command> --help`. What follows is a cheat sheet — where it
disagrees with `--help`, `--help` wins.

Every command prints one JSON object on stdout — **except `agent read` and
`pane read`, which print raw terminal text**. Parse the rest; ids are not
guessable. A failure exits 1 and prints `{"error":{"code":…,"message":…}}`, so
read the code rather than the exit status to know what went wrong.

## Open a new tab running an agent

Three commands, in order. Do not skip the name in step 2.

**1. Create the tab.**

```bash
herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" \
  --label "<short label>" --no-focus
```

`--no-focus` leaves the user where they are; focusing yanks them out of the tab
they are reading mid-turn. Take `result.root_pane.pane_id` from the JSON — step 2
needs it. Done when you hold a `pane_id`.

**2. Start the agent in that pane, with a name.**

```bash
herdr agent start <name> --kind claude --pane <pane_id> -- --model opus
```

Everything after `--` goes to the agent binary, and it is the only way to choose
the model. **An agent started without a name reports `name: null` and is then
addressable only by pane id** — name it here or lose the handle. `--kind` also
accepts codex, gemini, cursor, copilot, droid, amp and more (`--help` lists
them). Done when the result says `agent_started` and `interactive_ready: true`.

The pane must sit at an interactive shell prompt, and **a pane fresh out of step
1 is not there yet**. Run back-to-back in one script, step 2 fails while the
shell is still starting; across two commands the delay hides it. Retry until it
succeeds rather than assuming the pane is ready, and never discard this
command's output — a silent failure here leaves every later call answering
`agent_not_found`.

**3. Send the brief.**

```bash
herdr agent prompt <name> "$(cat brief.md)"
```

Write a brief longer than a line to a file first and pass it with `$(cat …)`;
quoting multi-paragraph text inline is where this breaks. Done when
`herdr agent get <name>` reports `agent_status: working` — the submission result
itself carries the *pre*-submission status and proves nothing.

A fresh agent starts with an empty context and cannot see this conversation. Hand
it conclusions you have already verified, and say what it must not do — a brief
that only restates the request buys a first turn spent re-deriving what you know.

## Waiting for an agent to finish

A turn moves `working` → `done`. **`done` is the completion signal, and `idle`
may never arrive** — a finished agent has been observed sitting at `done` for
over 100 seconds. Wait for `done`:

```bash
herdr agent wait <name> --until done --timeout 600000
```

Bare `herdr agent wait <name>` with no `--until` matches idle, done or blocked,
and returns on `done` as well — prefer it when a permission prompt should also
break the wait.

`--until idle` is the trap. It does not fire when the turn ends: it burns the
entire timeout and then exits 1 with `{"error":{"code":"timeout"}}`. A wait that
returns after exactly its timeout has told you nothing about the agent.

Two preconditions, each of which quietly costs a whole run when skipped:

- **Confirm `working` before waiting.** A `wait` issued too soon after `prompt`
  matches the *pre*-submission `idle` and returns success in milliseconds, as
  though the work were already done.
- **Read the `agent_status` that comes back.** `wait` returning is not the same
  as the agent having finished.

The shape that holds up:

```bash
herdr agent prompt <name> "$(cat brief.md)" >/dev/null
until [ "$(herdr agent get <name> | jq -r .result.agent.agent_status)" = working ]
do sleep 0.25; done
herdr agent wait <name> --until done --timeout 600000
```

Waits are independent — run several in the background and join them to fan out
across agents.

## When an agent stops on a prompt

`agent_status: blocked` means the agent is sitting on a permission prompt or a
question and will wait there forever. Unattended automation hangs here unless it
watches for it. Read the pane, then answer with a keypress:

```bash
herdr agent read <name> --lines 20    # see what it is asking
herdr agent send-keys <name> 1        # choose option 1
```

`esc` is the canonical Escape key name. After the keypress the agent goes back to
`working` on its own.

Passing `--permission-mode default` after `--` guarantees a block on the first
command needing approval; an agent that inherits auto mode mostly runs straight
through.

## Addressing an agent

| Target | Resolves |
|---|---|
| name, from `agent start` | yes |
| pane id (`w7:pY`) | yes |
| tab id (`w7:tS`) | **no** — `agent_not_found` |

## Command surface

| Group | Commands |
|---|---|
| `tab` | list · create · get · focus · rename · close |
| `pane` | list · current · get · split · swap · move · resize · zoom · read · send-text · rename · close · layout · neighbor · edges · process-info |
| `agent` | list · get · start · prompt · read · wait · send-keys · rename · focus · attach · explain |
| `workspace` | list · create · get · focus · rename · close |
| `worktree` | list · create · open · remove |
| `session` | list · attach · stop · delete |
| `api` | snapshot · schema |
| `notification` | show |
| `config` · `channel` · `integration` · `server` | see `--help` |

Flags are not uniform across groups. `tab create` takes `--workspace <id>`, but
`tab close` takes the tab id **positionally** (`herdr tab close w9:t2`); passing
`--tab` prints a usage line and changes nothing. Check `--help` before scripting
a group you have not used.

Watching another pane without disturbing it:

```bash
herdr agent read <name> --lines 40   # --source visible|recent|recent-unwrapped|detection
```

`herdr worktree create --branch <name> --base <ref>` opens the checkout as its
own workspace, ready for step 2. `herdr worktree remove --workspace <id> --force`
drops the checkout and the workspace but **leaves the branch behind** — delete it
yourself if it was throwaway.

`herdr api snapshot` returns the whole live workspace tree in one call — reach
for it instead of stitching `list` calls together, but filter it in the same
command: it runs to ~11 KB and does not belong in context whole.

## herdr or SendMessage

`ListAgents` and `SendMessage` address **Claude sessions as conversational
peers**; a message lands in the other session's conversation. herdr drives **the
terminal**: it creates the pane, starts any supported agent kind in it, reads raw
terminal output, and can target a pane that is not a Claude session at all.

Talk to an existing peer with `SendMessage`. Use herdr to make the place one runs
in, to pick its model, or to drive something that is not Claude.
