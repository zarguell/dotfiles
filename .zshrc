# ---- PATH (Cargo-installed CLIs) ----
export PATH="$HOME/.cargo/bin:$PATH"

# ---- Powerlevel10k (no instant prompt) ----
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ---- History “superpowers” ----
HISTFILE=~/.zsh_history
HISTSIZE=200000
SAVEHIST=200000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_NO_STORE

# Nice defaults
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# ---- Completion ----
autoload -Uz compinit
compinit

# ---- fzf: better history search (works with apt fzf) ----
# Ctrl-R: interactive reverse history search
bindkey '^R' fzf-history-widget 2>/dev/null || true

# ---- Modern defaults (guarded + Ubuntu compatibility) ----
command -v bat  >/dev/null 2>&1 && alias cat='bat'

command -v eza  >/dev/null 2>&1 && alias ls='eza --group-directories-first'
command -v rg   >/dev/null 2>&1 && alias grep='rg'

# Ubuntu often ships fd as fdfind; normalize to "fd"
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v fd >/dev/null 2>&1 && alias find='fd'

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Disk + process helpers
command -v duf  >/dev/null 2>&1 && alias df='duf'
command -v dust >/dev/null 2>&1 && alias du='dust'
command -v procs >/dev/null 2>&1 && alias ps='procs'

# Git: delta when present
if command -v delta >/dev/null 2>&1; then
  export GIT_PAGER=delta
fi
