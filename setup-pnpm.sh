#!/usr/bin/env bash
#
# Global npm tools not managed by Neovim's Mason.
#   ~/.dotfiles/setup-pnpm.sh

set -euo pipefail

# prettierd — prettier daemon; keeps prettier warm so :Format is instant.
pnpm add -g @fsouza/prettierd
