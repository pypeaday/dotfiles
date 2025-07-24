export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
eval "$(pyenv init --path)"

eval "$(/opt/homebrew/bin/brew shellenv)"

# Created by `pipx` on 2023-07-12 20:56:34
export PATH="$PATH:/Users/npayne81/Library/Python/3.9/bin"
autoload -Uz compinit
compinit

export SLICE_HOME=/Users/npayne81/work/slice/
alias slice="${SLICE_HOME}/slice.sh"
# use 1password
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# let me hold a key
eval `defaults write -g ApplePressAndHoldEnabled -bool false`
