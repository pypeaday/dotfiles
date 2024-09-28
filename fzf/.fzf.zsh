# Setup fzf
# ---------
if [[ ! "$PATH" == */home/nic/.local/share/nvim/plugged/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/nic/.local/share/nvim/plugged/fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/home/nic/.local/share/nvim/plugged/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "/home/nic/.local/share/nvim/plugged/fzf/shell/key-bindings.zsh"
