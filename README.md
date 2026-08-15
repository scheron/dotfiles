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

# 5. nvim plugins
nvim --headless "+Lazy! sync" +qa

# 6. Restart the shell
```

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
git pull && ~/.dotfiles/setup-symlinks.sh
```

Symlinked files pick up edits instantly; the script is only needed for **new**
configs. It's idempotent — just always run it.

## Adding a skill

Drop the folder into `claude/skills/` and re-run `setup-symlinks.sh`.

## After archiving a config

The script never removes links, so the old one dangles. Find and delete:

```sh
find ~/.config "$HOME/Library/Application Support/Code" -maxdepth 3 -type l \
  | while read -r l; do [ -e "$l" ] || echo "$l"; done
```
