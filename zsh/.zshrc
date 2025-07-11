# FROM AURORA STARTUP
# .zshrc is sourced in interactive shells.
# It should contain commands to set up aliases,
# functions, options, key bindings, etc.
#

autoload -U compinit
compinit

#allow tab completion in the middle of a word
setopt COMPLETE_IN_WORD

## keep background processes at full speed
#setopt NOBGNICE
## restart running processes on exit
#setopt HUP

## history
#setopt APPEND_HISTORY
## for sharing history between zsh processes
#setopt INC_APPEND_HISTORY
#setopt SHARE_HISTORY

## never ever beep ever
#setopt NO_BEEP

## automatically decide when to page a list of completions
#LISTMAX=0

## disable mail checking
#MAILCHECK=0

# autoload -U colors
#colors

export GSK_RENDERER=ngl

# If you come from bash you might have to change your $PATH.
export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/dotfiles

# just placeholder for nvim chatgpt plugin
export OPENAI_API_KEY="SETME"

# add pyenv to path
# export PYENV_ROOT="$HOME/.pyenv"
# export PATH="$PYENV_ROOT/bin:$PATH"

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
export PATH="$PATH:$NPM_PACKAGES"

# fly
export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

# make sure brew is on path

export PYFLYBY_PATH="$HOME/dotfiles/pyflyby/.pyflyby"
export EDITOR=nvim

# export TERM=screen-256color-bce
# export TERM=xterm-256color
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export ZSH_DISABLE_COMPFIX="true"
# ZSH_THEME="robbyrussell"
# ZSH_THEME=random
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )
# ZSH_THEME_RANDOM_QUIET=true
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ffff99,bg=italic,underline"

export K9S_CONFIG_DIR=$HOME/.config/k9s
plugins=(dotenv zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh
# source ~/.zprofile

# You may need to manually set your language environment
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# fuzzy find to directories with fzf
c() {
    cd ~/projects && cd "$(find -maxdepth 2 -type d 2>/dev/null  | cut -c 3-  | fzf | awk '{print $1}')"
}

# Change backgrounds
background() {
    clear && feh --bg-scale "$(find ~/dotfiles/backgrounds ~/projects/personal/anime -mindepth 1 -maxdepth 1 -type f | fzf)"
}

# aliases
alias vim="nvim"
alias bim="nvim"
alias cdw="cd ~/projects/work"
alias cdp="cd ~/projects/personal"
alias src="source ~/.zshrc"
alias envrc="cp $HOME/dotfiles/envrc ./.envrc"
alias inst="source ~/dotfiles/install"

alias nrows="awk 'END {print NR}'"
alias trackme='git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)'
alias set_openai='export OPENAI_API_KEY=$(cat ~/dotfiles/private/.openai.key)'

# Git aliases
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gcn="git commit --amend --no-edit"
alias gp="git push"
alias gl="git log --oneline --graph"
alias gd="git diff"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch"
alias gbd="git branch -d"
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# List directory contents
alias ll="ls -lha"

# Quick edit of common files
alias zshrc="$EDITOR ~/dotfiles/zsh/.zshrc"

# System shortcuts
alias df="df -h"
alias du="du -h"
alias free="free -m"
alias path="echo $PATH | tr ':' '\n'"
alias ports="netstat -tulanp"
alias myip="curl http://ipecho.net/plain; echo"
alias pubip="curl -s https://checkip.amazonaws.com"
alias localip="ip addr show | grep -E '\\b([0-9]{1,3}\\.){3}[0-9]{1,3}\\b' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1"
alias listen="lsof -i -P | grep LISTEN"
alias now='date +"%T"'
alias today='date +"%Y-%m-%d"'
alias timestamp='date +"%Y%m%d%H%M%S"'

hawk() {
    if [ "$1" = "tuah" ]; then
        command git push
    else
        echo "You forgot the tuah"
    fi
}

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

# Rust-based utility replacements
# File listing with eza (modern ls replacement, fork of exa)
if command -v eza &> /dev/null
then
    alias ls='eza'
    alias ll='eza -la'
    alias lt='eza -T --level=2'             # Tree view, 2 levels deep
    alias ltt='eza -T --level=3'            # Tree view, 3 levels deep
    alias lttt='eza -T'                     # Full tree view
    alias lg='eza -la --git'                # List with git status
    alias lm='eza -la --sort=modified'      # Sort by modified date
    alias lsize='eza -la --sort=size'       # Sort by size
fi

# Disk usage with dust (du replacement)
if command -v dust &> /dev/null
then
    alias du='dust'
    alias du1='dust -d 1'                   # Show only 1 level deep
    alias du2='dust -d 2'                   # Show 2 levels deep
    alias duh='dust -h'                     # Human readable
    alias dus='dust -s'                     # Sort by size
fi

# Directory tree with broot (interactive tree)
if command -v broot &> /dev/null
then
    alias br='broot'
    alias brs='broot --sizes'               # Show with sizes
    alias brh='broot --hidden'              # Show hidden files
fi

# Disk space with duf (df replacement)
if command -v duf &> /dev/null
then
    alias df='duf'
    alias dfa='duf -all'                    # Show all devices
fi

# Process viewer with procs (ps replacement)
if command -v procs &> /dev/null
then
    alias ps='procs'
    alias pst='procs --tree'                # Show process tree
    alias psc='procs --watch'               # Watch processes (like top)
fi

# Find with fd (find replacement)
if command -v fd &> /dev/null
then
    alias find='fd'
    alias fh='fd --hidden'                  # Include hidden files
    alias ft='fd --type f --exec-batch ls -la'  # Find files and show details
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
    export PATH="$PATH:$HOME/.linuxbrew/bin"
elif [ -d "/home/linuxbrew/.linuxbrew" ]; then
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    export PATH="$PATH:home/linuxbrew/.linuxbrew/bin"
else
    export HOMEBREW_PREFIX="/opt/homebrew"
    export PATH="$PATH:/opt/homebrew/bin"
fi
# eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# rust
source "$HOME/.cargo/env"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# shortcuts

bindkey -s '^o' 'background \n'
bindkey '^e' edit-command-line

# when sourcing zshrc make sure PATH variables aren't duplicated
eval "typeset -U path"

# motd
hello() { clear && ~/dotfiles/scripts/.local/bin/login.sh }
bindkey -s '^k' 'hello \n'
bindkey -s '^l' 'clear \n'

# terraform complete
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform


# gitignore
function gi() { curl -sLw n https://www.toptal.com/developers/gitignore/api/$@ ;}

# Installer functions for Rust utilities using jpillora/installer

# Install eza (modern replacement for ls)
function install_eza() {
  echo "Installing eza..."
  curl -s https://i.paynepride.com/eza! | bash
  echo "\nTo use eza, restart your terminal or run: source ~/.zshrc"
}

# Install dust (du replacement)
function install_dust() {
  echo "Installing dust..."
  curl -s https://i.paynepride.com/bootandy/dust! | bash
  echo "\nTo use dust, restart your terminal or run: source ~/.zshrc"
}

# Install broot (interactive tree)
function install_broot() {
  echo "Installing broot..."
  curl -s https://i.paynepride.com/Canop/broot! | bash
  echo "\nTo use broot, restart your terminal or run: source ~/.zshrc"
}

# Install duf (df replacement)
function install_duf() {
  echo "Installing duf..."
  curl -s https://i.paynepride.com/muesli/duf! | bash
  echo "\nTo use duf, restart your terminal or run: source ~/.zshrc"
}

# Install procs (ps replacement)
function install_procs() {
  echo "Installing procs..."
  curl -s https://i.paynepride.com/dalance/procs! | bash
  echo "\nTo use procs, restart your terminal or run: source ~/.zshrc"
}

# Install fd (find replacement)
function install_fd() {
  echo "Installing fd..."
  curl -s https://i.paynepride.com/sharkdp/fd! | bash
  echo "\nTo use fd, restart your terminal or run: source ~/.zshrc"
}

# Install all Rust utilities
function install_rust_utils() {
  echo "Installing all Rust utilities..."
  install_eza
  install_dust
  install_broot
  install_duf
  install_procs
  install_fd
  echo "\nAll utilities installed! To use them, restart your terminal or run: source ~/.zshrc"
}

# gitignored local aliases primarily for sensitive things at work
if [ -e "$HOME/.alias.local" ]; then
    source $HOME/.alias.local
fi

# completion scripts
source $HOME/dotfiles/zsh/.zsh.completion/.kind
source $HOME/dotfiles/zsh/.zsh.completion/.pixi

# get weather
wttr () { curl "wttr.in/$1?u" }
wttrd () { curl "v2d.wttr.in/$1?u" }

# Quick search functions
cheat() { curl -s "cheat.sh/$1" | less -R }
eval "$(atuin init zsh --disable-up-arrow)"