# Install

dev-stack ships as a single Claude Code plugin. Installing the plugin brings **everything** — the Tier 1/2/3 skills, the `commit-work` skill, and the `commit-guard` / `branch-guard` hooks (bundled via `hooks/hooks.json`, no `settings.json` edits needed).

## On any machine

```
/plugin marketplace add bmox0/dev-skills
/plugin install dev-stack@dev-stack
```

That's it. When the plugin is enabled, its `hooks/hooks.json` auto-activates the guards; `${CLAUDE_PLUGIN_ROOT}` resolves the bundled scripts, so there are no machine-specific paths.

## What you get

- All Tier 1/2/3 engineering skills — start with `/route-me` (map) and STACK.md (the *why*).
- `commit-work` skill + the `commit-guard` hook that enforces it: Conventional Commits (a leading ticket prefix like `ABC-123:` is allowed), and no `Co-Authored-By` / "Generated with Claude Code" footnote / `Claude-Session:` trailer / blanket `git add .`.
- `branch-guard` hook: in a repo carrying a `.branch-guard` marker, edits and commits on the default branch are blocked until you cut a dedicated branch (`/new-branch`, Tier 1) or a worktree (`/using-git-worktrees`, Tier 2/3).

## Opt a repo into the branch guard

Drop an empty `.branch-guard` file at the repo root. Without it, the branch guard does nothing — it is opt-in per repo.

## Requirements

- `jq` on `PATH` (the guard hooks use it).
- Repo access (SSH or HTTPS).

## Local development

`./install.sh` symlinks each `skills/<name>` into `~/.claude/skills` so live edits are picked up without reinstalling. The plugin is the supported install; the linker is only for iterating on skills.
