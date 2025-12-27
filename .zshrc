# Minimal entrypoint: keep real logic in ~/.config/shell
[[ -f ~/.config/shell/common.sh ]] && source ~/.config/shell/common.sh
[[ -f ~/.config/shell/zsh.sh ]] && source ~/.config/shell/zsh.sh
