# dotfiles

Personal macOS configuration

**What's inside:** zsh (oh-my-zsh + starship), git (with per-project identities),
Ghostty, AeroSpace, Karabiner, Neovim (NvChad), Zed, VSCode, lazygit, yazi,
Claude Code, and gh. Retired configs live in [`.archive/`](.archive).

## Fresh machine setup

1. Install [Homebrew](https://brew.sh).
2. Clone this repo to `~/.dotfiles`:
   ```sh
   git clone https://github.com/scheron/dotfiles.git ~/.dotfiles
   ```
3. Install formulae, casks and fonts:
   ```sh
   ~/.dotfiles/setup-brew.sh
   ```
4. Symlink everything into place (idempotent; backs up any existing file to `<path>.backup`):
   ```sh
   ~/.dotfiles/setup-symlinks.sh
   ```
5. Open Neovim once and let it install plugins: `nvim` → `:Lazy sync`.
6. Restart the shell.

`setup-pnpm.sh` (global pnpm packages) is optional — language servers are now
managed by Neovim's Mason, so most machines don't need it.

## Updating an existing machine

After `git pull`, re-run `setup-symlinks.sh` whenever the pull adds a **new**
tracked config. Existing symlinks pick up edits instantly, but new files aren't
linked until the script runs again — skipping it can leave a config referencing
a not-yet-linked file (e.g. a hook pointing at a missing script). It's
idempotent, so re-running it every time is safe.

## Claude Code skills

`claude/skills/` is a bucket for standalone skills: every
`claude/skills/<name>/` is symlinked into `~/.claude/skills/` by
`setup-symlinks.sh`.

The engineering workflow no longer lives here. It is a Claude Code plugin in
its own repository, [bmox0/dev-skills](https://github.com/bmox0/dev-skills),
and installs itself:

```sh
git clone git@github.com:bmox0/dev-skills.git
cd dev-skills && ./install.sh
```

That creates one symlink at `~/.claude/skills/dev-skills` and carries its own
agents and guard hooks with it, so nothing about it is wired from this repo —
`claude/settings.json` holds no hook entry for it. **`setup-symlinks.sh` does
not install it**: a fresh machine needs the clone above as a separate step.
The generation before it is retired in `.archive/dev-stack/`.

To add a standalone skill, drop its folder into `claude/skills/` and re-run
`setup-symlinks.sh` — the glob picks it up, no script edit needed:

```sh
cp -r some-skill ~/.dotfiles/claude/skills/some-skill
~/.dotfiles/setup-symlinks.sh
```

## Per-machine setup (not stored in this repo)

This repo is public, so secrets and per-machine state are configured by hand:

- **SSH & git identities** — add your SSH keys and a `~/.ssh/config` for your
  git accounts; the `includeIf` rules in `.gitconfig` pick the right identity
  per project directory once the keys exist.
- **npm** — `npm login` if you publish or install private packages.
- **GitHub CLI** — `gh auth login` (only `config.yml` is tracked; `hosts.yml` holds the token and is not).
- **Claude Code** — sign in on first `claude` run (`~/.claude/.claude.json` is not tracked).
- **Excalidraw skill renderer** — optional Playwright pipeline that lets the
  agent render and visually check its diagrams:
  `cd claude/skills/excalidraw-diagram/references && uv sync && uv run playwright install chromium`
  (the `.venv`, `uv.lock`, and rendered PNGs are git-ignored).

## Notes

- Editor font "Dank Mono" is paid — install it manually.
- Some Cursor-era VSCode extensions (see `VSCode/extensions.txt`) come from
  OpenVSX and may differ on the Microsoft Marketplace.
