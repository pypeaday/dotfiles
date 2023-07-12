export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
eval "$(pyenv init --path)"

eval "$(/opt/homebrew/bin/brew shellenv)"

# Created by `pipx` on 2023-07-12 20:56:34
export PATH="$PATH:/Users/npayne81/Library/Python/3.9/bin"
autoload -Uz compinit
compinit
