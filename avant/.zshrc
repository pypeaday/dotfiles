# If you come from bash you might have to change your $PATH.
export ZSH=$HOME/.oh-my-zsh
export DOTFILES=$HOME/dotfiles

# just placeholder for nvim chatgpt plugin
export OPENAI_API_KEY="SETME"

# make sure .local/bin is on path
export PATH="$HOME/.local/bin:$PATH"

# make sure mason packages are on PATH

export MASON_PATH=$HOME/.local/share/nvim/mason/bin
export PATH="$PATH:$MASON_PATH"

# make sure npm packages are on path
export NPM_PACKAGES_ROOT="$HOME/.local/.npm-global"
export NPM_PACKAGES="$NPM_PACKAGES_ROOT/bin"
export PATH="$NPM_PACKAGES:$PATH"

export PYFLYBY_PATH="$HOME/dotfiles/pyflyby/.pyflyby"
export EDITOR=nvim
#

# use pyenv global python for pipx
export PIPX_DEFAULT_PYTHON="$HOME/.pyenv/shims/python"

# export TERM=screen-256color-bce
# export TERM=xterm-256color
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export ZSH_DISABLE_COMPFIX="true"

plugins=(dotenv ag zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# fuzzy find to directories with fzf
# from phind.com refactored for mac
# brew install fd
c() {
    cd && cd "$(fd -d 2 | cut -c 1- | fzf )"
}

# aliases
alias vim="nvim"
alias bim="nvim"
alias cdw="cd ~/work"
alias cdp="cd ~/personal"
alias src="source ~/.zshrc"
alias envrc="cp $HOME/dotfiles/envrc ./.envrc"
alias rconfig="cp $HOME/dotfiles/avant/.ruff.toml ./.ruff.toml"

alias otp="bash ~/dotfiles/avant/.local/bin/one-password-copy"
alias otw="bash ~/dotfiles/avant/.local/bin/one-password-copy-pw"

alias nrows="awk 'END {print NR}'"
alias trackme='git branch --set-upstream-to=origin/$(git symbolic-ref --short HEAD)'
alias set_openai='export OPENAI_API_KEY=$(cat ~/.openai/apikey)'

bindkey -s '^o' 'otp \n'
bindkey -s '^p' 'otw \n'

# interactively destroy tmux sessions
destroy() {
    tmux list-sessions -F '#{session_name}' | fzf -m | xargs -I{} tmux kill-session -t {}
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
eval "$(/opt/homebrew/bin/brew shellenv)"

# rust
source "$HOME/.cargo/env"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Jump into a tmux session
# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#     tmux attach -t base || tmux new -s base
# fi
# shortcuts

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
#
# add pyenv to path after brew on Mac at Avant
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PYENV_ROOT/shims:$PATH"

autoload -Uz compinit
compinit

# Created by `pipx` on 2023-07-12 20:56:34
export PATH="$PATH:/Users/npayne81/Library/Python/3.9/bin"


# From Dylan
# https://www.notion.so/avant/Aliases-c0d1dad2b9f24ad980702bee39a98f00
alias aws-whoami='aws sts get-caller-identity'
# assume-avant-prd-app='source ~/.assume-avant-prd-app.sh'
# assume-avant-prd-ds='source ~/.assume-avant-prd-ds.sh'
# unassume-aws-role='source ~/.unassume-aws-role'

assume-avant-prd-app () {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    CREDS=$(aws sts assume-role --role-arn arn:aws:iam::005228414382:role/OrganizationAccountAccessRole --role-session-name OrganizationRole --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text)

    export AWS_ACCESS_KEY_ID=$(echo ${CREDS}| cut -f1 -d$'\t')
    export AWS_SECRET_ACCESS_KEY=$(echo ${CREDS}| cut -f2 -d$'\t')
    export AWS_SESSION_TOKEN=$(echo ${CREDS}| cut -f3 -d$'\t')
}

assume-avant-prd-ds () {

    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    CREDS=$(aws sts assume-role --role-arn arn:aws:iam::654641313688:role/OrganizationAccountAccessRole --role-session-name OrganizationRole --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" --output text)

    export AWS_ACCESS_KEY_ID=$(echo ${CREDS}| cut -f1 -d$'\t')
    export AWS_SECRET_ACCESS_KEY=$(echo ${CREDS}| cut -f2 -d$'\t')
    export AWS_SESSION_TOKEN=$(echo ${CREDS}| cut -f3 -d$'\t')

}

aws-commands () {
    echo "aws-whoami"
    echo "assume-avant-prd-app"
    echo "assume-avant-prd-ds"
}

# EKS
# brew install kubecm
alias kc=kubecm
alias list-eks='echo `aws eks list-clusters`'
alias add-eks='aws eks update-kubeconfig --name '

eks-commands () {
    echo "list-eks"
    echo "add-eks"
}

# vault
vlogin='vault login -method ldap -no-print'
eval "$(atuin init zsh)"

# Spacelift stuff
alias get-space-stack='export MY_STACK_ID=$(spacectl stack list | fzf | awk -F"|" "{print \$1}" | awk "{\$1=\$1};1")'
alias space-stack-lp='spacectl stack local-preview --id $MY_STACK_ID'
alias space-stack-auto-local-preview='get-space-stack && space-stack-lp'


spacelift-commands () {
    echo "get-space-stack"
    echo "space-stack-lp"
    echo 'space-stack-auto-local-preview'
}
