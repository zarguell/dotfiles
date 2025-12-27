# ---- Powerlevel10k (no instant prompt) ----
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ---- History (zsh) ----
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=200000

setopt APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
setopt HIST_VERIFY HIST_NO_STORE

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS

autoload -Uz compinit
compinit

# Ctrl-R fzf widget (only if defined)
bindkey '^R' fzf-history-widget 2>/dev/null || true

# zoxide (zsh)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
