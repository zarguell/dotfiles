# ---- History (bash) ----
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=200000
export HISTFILESIZE=200000

shopt -s histappend
export HISTCONTROL=ignoreboth:erasedups

# Append after each command to help multi-terminal workflows
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-:}"

# ---- fzf bindings (bash) ----
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
elif [ -f /usr/share/fzf/key-bindings.bash ]; then
  source /usr/share/fzf/key-bindings.bash
fi

if [ -f /usr/share/doc/fzf/examples/completion.bash ]; then
  source /usr/share/doc/fzf/examples/completion.bash
elif [ -f /usr/share/fzf/completion.bash ]; then
  source /usr/share/fzf/completion.bash
fi

# zoxide (bash)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"
