# dotfiles

Personal macOS configuration. Highly opinionated — fork it, don't run it blindly.

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

## Per-machine setup (not stored in this repo)

This repo is public, so secrets and per-machine state are configured by hand:

- **SSH & git identities** — add your SSH keys and a `~/.ssh/config` for your
  git accounts; the `includeIf` rules in `.gitconfig` pick the right identity
  per project directory once the keys exist.
- **npm** — `npm login` if you publish or install private packages.
- **GitHub CLI** — `gh auth login` (only `config.yml` is tracked; `hosts.yml` holds the token and is not).
- **Claude Code** — sign in on first `claude` run (`~/.claude/.claude.json` is not tracked).

## Notes

- Editor font "Dank Mono" is paid — install it manually.
- Some Cursor-era VSCode extensions (see `VSCode/extensions.txt`) come from
  OpenVSX and may differ on the Microsoft Marketplace.
