# dotfiles

Personal macOS config. Installed by symlink. Retired stuff in [`.archive/`](.archive).

## New machine

```sh
# 1. Homebrew — https://brew.sh
# 2. Clone
git clone https://github.com/scheron/dotfiles.git ~/.dotfiles

# 3. Packages (re-run until it exits 0; failures are listed at the end)
~/.dotfiles/setup-brew.sh

# 4. Symlinks (idempotent; existing files moved to <path>.backup)
~/.dotfiles/setup-symlinks.sh

# 5. macOS preferences (idempotent defaults write)
~/.dotfiles/setup-macos.sh

# 6. nvim plugins
nvim --headless "+Lazy! sync" +qa

# 7. herdr plugins (not symlinked; restart herdr afterwards)
~/.dotfiles/setup-herdr-plugins.sh

# 8. Log out and back in
```

`setup-macos.sh` is the only record of the `defaults write` settings — nothing
symlinks them. Add new ones there instead of running `defaults` by hand. Same
deal for `setup-herdr-plugins.sh`: herdr keeps plugins outside this repo, so
that script is the only list of which ones to install.

Claude Code plugins (dev-skills and the rest) install themselves from the
symlinked `claude/settings.json` on the next `claude` start. MCP servers are not
tracked — re-add those by hand.

Then sign in by hand: SSH keys + `~/.ssh/config` (`.gitconfig` `includeIf` picks
the identity per directory), `gh auth login`, `claude`, `npm login` if needed.

Optional: `setup-pnpm.sh` (just prettierd), Excalidraw renderer — `cd
claude/skills/excalidraw-diagram/references && uv sync && uv run playwright
install chromium`.

## Existing machine

```sh
git pull
~/.dotfiles/setup-symlinks.sh
~/.dotfiles/setup-macos.sh --check
~/.dotfiles/setup-macos.sh
```

Symlinked files pick up edits instantly; the script is only needed for **new**
configs. It's idempotent — just always run it. `setup-macos.sh --check` is a
read-only preview and can be omitted once a machine is known to match.

If the pull changed `herdr/config.toml` or `setup-herdr-plugins.sh`, run that
one too. It needs herdr 0.8.2+ and says so if the version is short; restart the
herdr server after it installs anything.

### Raycast settings

Raycast keeps command hotkeys in its encrypted application database, so they
cannot be represented safely as `defaults` entries or symlinked dotfiles. Use
Raycast's **Export Settings & Data** command, then **Import Settings & Data** on
another Mac and select **Settings, Aliases & Hotkeys**. This carries the
`Maximize` and `Restore` shortcuts. The export is an encrypted `.rayconfig`
file; keep its passphrase outside this repository.

Official instructions: <https://manual.raycast.com/import-export>

### Native Spaces

Application-to-Space bindings contain machine-specific Space UUIDs and cannot
be copied safely between Macs. The current layout, for quick manual setup
after creating the Desktops, is:

- Main display, Desktop 1: Brave
- Main display, Desktop 3: Ghostty
- Main display, Desktop 5: Daily
- Secondary display, Desktop 1: Zen

Use each app's Dock menu: **Options → Assign To → This Desktop**. Everything
else about Spaces, including `Option+1` through `Option+5`, is handled by
`setup-macos.sh`.

## Adding a skill

Drop the folder into `claude/skills/` and re-run `setup-symlinks.sh`.

## After archiving a config

The script never removes links, so the old one dangles. Find and delete:

```sh
find ~/.config "$HOME/Library/Application Support/Code" -maxdepth 3 -type l \
  | while read -r l; do [ -e "$l" ] || echo "$l"; done
```
