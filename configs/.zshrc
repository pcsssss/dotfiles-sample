export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(zoxide init --cmd cd zsh)"

eval "$(fzf --zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FROM_NIX="YES"

eval "$(direnv hook zsh)"

echo "WELCOME"
echo $(which starship)

echo "PROMPT: $PROMPT"
echo "PROMPT2: $PROMPT2"
echo "PS1: $PS1"
echo "PS2: $PS2"

eval "$(starship init zsh)"