# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH=$HOME/local/bin:$PATH
export PATH=/usr/local/bin:$PATH
export XDG_CONFIG_HOME="$HOME/.config"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z fzf zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# aliases
alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"
alias ll="ls -l"
alias cl="clear"
alias tm=tmux
alias vim="nvim"
alias pn=pnpm
alias gg=lazygit

alias g=git
alias gc="git commit"
alias ga="git add"
alias gP="git push"
alias gp="git pull"
alias gs="git status"
alias gd="git diff"
alias gco="git checkout"
alias gfa="git fetch --all --prune"


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
source ~/powerlevel10k/powerlevel10k.zsh-theme






___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi

# bun completions
[ -s "/Users/olegato/.bun/_bun" ] && source "/Users/olegato/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by Windsurf
export PATH="/Users/olegato/.codeium/windsurf/bin:$PATH"
