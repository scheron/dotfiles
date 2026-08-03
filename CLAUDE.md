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
