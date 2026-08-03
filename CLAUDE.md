# .dotfiles

Personal dotfiles. Configuration is installed by symlink; nothing here is built
or compiled.

## Environment

**Build.** none — this repository ships shell scripts and Markdown
**Typecheck.** none
**Lint.** none
**Tests.** none, this project has no test framework. Verification is by command:
`python3 scripts/check-links.py` from `claude/dev-skills`, and
`claude plugin validate . --strict`
**Single test file.** none
**Dev server.** none
**E2E.** none
**Runtime.** a live Claude Code session. Observable behaviour is driven by
starting a session (the SessionStart hook fires), invoking a skill by name, and
running the hook scripts directly: `bash hooks/session-start`,
`bash hooks/commit-guard.sh`

**bootstrap.** none — nothing to install; `python3`, `rsync` and the `claude`
CLI are all system-provided and already present
**link.** none — no untracked local files are needed
