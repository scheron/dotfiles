# .dotfiles

Personal dotfiles. Configuration is installed by symlink; nothing here is built
or compiled.

## Environment

**Build.** none — this repository ships shell scripts and Markdown
**Typecheck.** none
**Lint.** none
**Tests.** none, this project has no test framework. Verification is by
inspection and by `./setup-symlinks.sh`, which is idempotent and reports what it
links
**Single test file.** none
**Dev server.** none
**E2E.** none
**Runtime.** the installed configuration itself. Observable behaviour is driven
by running `./setup-symlinks.sh` and checking that the expected symlinks exist
under `$HOME`, then opening the tool whose config changed

**bootstrap.** none — nothing to install; `python3`, `rsync` and the `claude`
CLI are all system-provided and already present
**link.** none — no untracked local files are needed

## Fresh device runbook

Trigger: the user says this is a new/fresh device and asks to install
everything. Work through the steps below in order, without asking which parts
to do — the whole list is the job. Report at the end what landed, what failed,
and the exact handoff list from step 7.

`.archive/` is retired configuration. Never install, link or restore anything
from it.

**1. Homebrew.** `command -v brew`. If missing, stop and have the user install
it from https://brew.sh — the installer is interactive and needs their
password.

**2. Repo location.** Everything assumes `~/.dotfiles`. If the repo is
elsewhere, move or re-clone it there first — `setup-symlinks.sh` hardcodes
`DOTFILES="$HOME/.dotfiles"` and would otherwise link into the wrong tree.

**3. Packages — the user runs this one.** Some casks (Karabiner, Logi Options+)
install privileged helpers and prompt for the macOS password, which you cannot
type. Have them run:

```
! ~/.dotfiles/setup-brew.sh
```

It installs packages one at a time, so a failure no longer aborts the run: it
prints a `FAILED` list and exits 1. Read that list, fix what is fixable, re-run.
Already-installed packages are skipped, so re-running is cheap.

**4. Symlinks — you run this.**

```sh
~/.dotfiles/setup-symlinks.sh
```

Idempotent; an existing real file is moved to `<path>.backup` first. It must
run *after* step 3, because it links hunk's Claude skill from
`brew --prefix hunk`; if hunk was not installed yet it prints a skip line for
that one entry and everything else still links. Re-run after fixing step 3.

**5. Neovim plugins.**

```sh
nvim --headless "+Lazy! sync" +qa
```

**6. Claude Code.** Nothing to do. `claude/settings.json` is symlinked in step 4
and already declares every marketplace and enabled plugin, including
`dev-skills`, with `autoUpdate` — they install themselves on the next `claude`
start. MCP servers live in the untracked `~/.claude.json` and do **not** come
back this way; list them as manual work.

**7. Hand off what needs a human.** You cannot do any of these — list them
explicitly at the end rather than attempting them:

- SSH keys + `~/.ssh/config`. The `includeIf` rules in `.gitconfig` only pick
  the right git identity per directory once the keys exist.
- `gh auth login`, `claude` sign-in, `npm login` — all interactive; suggest the
  `!` prefix.
- Accessibility / Input Monitoring approval in System Settings for AeroSpace and
  Karabiner, and Karabiner's driver extension.
- "Dank Mono" — the editor font in the configs is paid and installs by hand.
- MCP servers, per step 6.

**8. Verify before reporting.** Do not report success off a script's exit code
alone:

```sh
~/.dotfiles/setup-symlinks.sh   # second run: every line should say "ok"
zsh -i -c exit                  # must print nothing to stderr

# dangling symlinks — expect no output
find ~/.config "$HOME/Library/Application Support/Code" -maxdepth 3 -type l \
  | while read -r l; do [ -e "$l" ] || echo "$l"; done
```

Write the check that way rather than with `find ... ! -exec test -e {} \;`: the
`rtk` PreToolUse hook rewrites your Bash calls and rejects `find` with compound
predicates or `-exec`. That hook also filters command output — when a result
looks wrong or suspiciously short, re-run through `rtk proxy <cmd>` before
concluding anything from it.

Optional, only if the user asks: `setup-pnpm.sh` (prettierd) and the Excalidraw
renderer (`cd claude/skills/excalidraw-diagram/references && uv sync && uv run
playwright install chromium`).

## Gotchas

- macOS ships bash 3.2. In the setup scripts, expanding an empty array under
  `set -u` (`"${arr[@]}"`) is an unbound-variable error — spell the branches out
  or use `${arr[@]+"${arr[@]}"}`.
- `setup-brew.sh` taps `nikitabobko/tap`, `mediosz/tap` and `scheron/tap` before
  installing. Anything added from a tapped source needs its tap added there too,
  or a fresh machine fails to resolve it.
- Casks install with `--adopt` so an app already sitting in `/Applications` from
  a manual download is taken over instead of erroring.
- `setup-symlinks.sh` only ever creates links. Archiving a config leaves its old
  symlink dangling; the `find` in step 8 is what catches that.
