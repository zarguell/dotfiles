# ---- PATH (Cargo-installed CLIs) ----
export PATH="$HOME/.cargo/bin:$PATH"

# ---- Modern defaults (guarded + Ubuntu compat) ----
command -v bat >/dev/null 2>&1 && alias cat='bat'
command -v batcat >/dev/null 2>&1 && alias cat='batcat'

command -v eza >/dev/null 2>&1 && alias ls='eza --group-directories-first'
command -v rg  >/dev/null 2>&1 && alias grep='rg'

# fd: Ubuntu package often provides fdfind; normalize
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v fd >/dev/null 2>&1 && alias find='fd'

# Disk + process helpers
command -v duf  >/dev/null 2>&1 && alias df='duf'
command -v dust >/dev/null 2>&1 && alias du='dust'
command -v procs >/dev/null 2>&1 && alias ps='procs'

# Git: delta when present
if command -v delta >/dev/null 2>&1; then
  export GIT_PAGER=delta
fi

export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export API_TIMEOUT_MS="3000000"
# export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"
# export ANTHROPIC_DEFAULT_SONNET_MODEL="GLM-4.7"
# export ANTHROPIC_DEFAULT_HAIKU_MODEL="GLM-4.5-Air"