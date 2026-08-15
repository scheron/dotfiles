# Homebrew first — everything below resolves through $HOMEBREW_PREFIX.
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- path ---
export PATH="$HOMEBREW_PREFIX/opt/python@3.14/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# --- history ---
# oh-my-zsh used to set these; it is gone, so they live here now.
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt append_history share_history inc_append_history
setopt hist_ignore_dups hist_ignore_space hist_reduce_blanks
setopt extended_history hist_verify

# --- completion ---
# -i skips insecure completion files instead of stopping to ask about them:
# Homebrew occasionally lays down group-writable dirs, and a bare `compinit`
# then blocks shell startup on an interactive prompt.
autoload -Uz compinit
compinit -i

# --- aliases ---
alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"
alias lt="eza --tree --level=2 --icons=always --no-time --no-user --no-permissions"
alias ll="ls -l"
alias cl="clear"
alias tm=tmux
alias vim="nvim"
alias pn=pnpm
alias gg=lazygit
alias h=herdr
alias aty="antigravity"

alias g=git
alias gc="git commit"
alias ga="git add"
alias gP="git push"
alias gp="git pull"
alias gs="git status"
alias gd="git diff"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gcl="git clone"

# --- plugins ---
# Every source is guarded: a fresh machine that has not run setup-brew.sh yet
# gets a working shell instead of a screenful of "no such file or directory".
# zsh-syntax-highlighting stays last — it wraps the widgets set up above it.
[ -f "$HOMEBREW_PREFIX/etc/profile.d/z.sh" ] \
  && . "$HOMEBREW_PREFIX/etc/profile.d/z.sh"
[ -f "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] \
  && . "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -t 0 ] && [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ] \
  && . "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
[ -t 0 ] && [ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ] \
  && . "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
[ -f "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] \
  && . "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- prompt ---
command -v starship >/dev/null && eval "$(starship init zsh)"
