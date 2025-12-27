# Only interactive shells
case $- in *i*) ;; *) return ;; esac

# Minimal entrypoint: keep real logic in ~/.config/shell
[ -f "$HOME/.config/shell/common.sh" ] && source "$HOME/.config/shell/common.sh"
[ -f "$HOME/.config/shell/bash.sh" ] && source "$HOME/.config/shell/bash.sh"
