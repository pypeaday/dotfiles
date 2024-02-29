# If you come from bash you might have to change your $PATH.
export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/dotfiles

# just placeholder for nvim chatgpt plugin
export OPENAI_API_KEY="SETME"

# add pyenv to path
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# add appimages to path
export APPIMAGE_ROOT="$HOME/AppImages:"
export PATH="$APP_IMAGE_ROOT:$PATH"

# make sure .local/bin is on path
export PATH="$HOME/.local/bin:$PATH"

# make sure mason packages are on PATH

export MASON_PATH=$HOME/.local/share/nvim/mason/bin
export PATH="$PATH:$MASON_PATH"

# make sure npm packages are on path
export NPM_PACKAGES_ROOT="$HOME/.local/.npm-global"
export NPM_PACKAGES="$NPM_PACKAGES_ROOT/bin"
export PATH="$NPM_PACKAGES:$PATH"

# make sure brew is on path

export PYFLYBY_PATH="$HOME/dotfiles/pyflyby/.pyflyby"
export EDITOR=nvim

# use pyenv global python for pipx
export PIPX_DEFAULT_PYTHON="$HOME/.pyenv/shims/python"

# export TERM=screen-256color-bce
# export TERM=xterm-256color
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export ZSH_DISABLE_COMPFIX="true"
# ZSH_THEME="robbyrussell"
# ZSH_THEME=random
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
# ZSH_THEME_RANDOM_QUIET=true

plugins=(dotenv ag zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
# source ~/.zprofile

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# fuzzy find to directories with fzf
c() {
    cd && cd "$(find -maxdepth 2 -type d 2>/dev/null  | cut -c 3-  | fzf | awk '{print $1}')"
}

# Change backgrounds
background() {
    clear && feh --bg-scale "$(find ~/dotfiles/backgrounds ~/personal/anime -mindepth 1 -maxdepth 1 -type f | fzf)"
}

# aliases
alias vim="nvim"
alias bim="nvim"
alias cdw="cd ~/work"
alias cdp="cd ~/personal"
alias src="source ~/.zshrc"
alias envrc="cp $HOME/dotfiles/envrc ./.envrc"
alias inst="source ~/dotfiles/install"

alias nrows="awk 'END {print NR}'"
alias trackme='git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)'
alias set_openai='export OPENAI_API_KEY=$(cat ~/.openai/apikey)'

# interactively destroy tmux sessions
destroy() {
    tmux list-sessions -F '#{session_name}' | fzf -m | xargs -d $'\n' sh -c 'echo "killing $0"; tmux kill-session -t "$0"; for arg;do echo "killing $arg";tmux kill-session -t "$arg"; done'
}
bindkey -s '^d' 'destroy \n'
# alias destroy="tmux list-sessions -F '#{session_name}' | fzf -m | xargs -d $'\n' sh -c 'echo "killing $0"; tmux kill-session -t "$0"; for arg;do echo "killing $arg";tmux kill-session -t "$arg"; done'"

# pls if a nice python based ls
if command -v pls &> /dev/null
then
    alias lss='pls -d size -u decimal -d'
fi

# if rust-based utils replacements are install then set some nice aliases
if command -v exa &> /dev/null
then
    alias ls='exa'
fi

# temp git diff shortcuts
alias gdiff="git diff main.. | nvim - -R +Diffurcate"

# starship
eval "$(starship init zsh)"
# direnv
eval "$(direnv hook zsh)"
# homebrew
if [ -d "$HOME/.linuxbrew" ]; then
    export HOMEBREW_PREFIX="$HOME/.linuxbrew"
    export PATH="$HOME/.linuxbrew/bin:$PATH"
elif [ -d "/home/linuxbrew/.linuxbrew" ]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export PATH="home/linuxbrew/.linuxbrew/bin:$PATH"
else
    export HOMEBREW_PREFIX="/opt/homebrew"
    export PATH="/opt/homebrew/bin:$PATH"
fi
eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# rust
source "$HOME/.cargo/env"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Jump into a tmux session
# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#     tmux attach -t base || tmux new -s base
# fi

eval "$(pyenv init --path)"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init -)"
# BEGIN ANSIBLE MANAGED BLOCK: pyenv
if [ -e "$HOME/.pyenv/.pyenvrc" ]; then
    source $HOME/.pyenv/.pyenvrc
    if [ -e "$HOME/.pyenv/completions/pyenv.zsh" ]; then
        source $HOME/.pyenv/completions/pyenv.zsh
    elif [ -e "/usr/local/opt/pyenv/completions/pyenv.zsh" ]; then
        source /usr/local/opt/pyenv/completions/pyenv.zsh
    fi
fi
# END ANSIBLE MANAGED BLOCK: pyenv

# shortcuts

bindkey -s '^o' 'background \n'
bindkey '^e' edit-command-line

# when sourcing zshrc make sure PATH variables aren't duplicated
eval "typeset -U path"

# motd
hello() { clear && ~/dotfiles/scripts/.local/bin/login.sh }
bindkey -s '^k' 'hello \n'
bindkey -s '^l' 'clear \n'

hello \n

# terraform complete
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform


# gitignore
function gi() { curl -sLw n https://www.toptal.com/developers/gitignore/api/$@ ;}

# gitignored local aliases primarily for sensitive things at work
if [ -e "$HOME/.alias.local" ]; then
    source $HOME/.alias.local
fi
