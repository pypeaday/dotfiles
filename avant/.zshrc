# Source my normal one
source $HOME/dotfiles/zsh/.zshrc

# fuzzy find to directories with fzf
# from phind.com refactored for mac
# brew install fd
c() {
    cd && cd "$(fd -d 2 | cut -c 1- | fzf )"
}

alias rconfig="cp $HOME/dotfiles/avant/.ruff.toml ./.ruff.toml"

alias otp="bash ~/dotfiles/avant/.local/bin/one-password-copy"
alias otw="bash ~/dotfiles/avant/.local/bin/one-password-copy-pw"

bindkey -s '^o' 'otp \n'
bindkey -s '^p' 'otw \n'

# interactively destroy tmux sessions
destroy() {
    tmux list-sessions -F '#{session_name}' | fzf -m | xargs -I{} tmux kill-session -t {}
}
bindkey -s '^d' 'destroy \n'

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# add pyenv to path after brew on Mac at Avant
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PATH="$PYENV_ROOT/shims:$PATH"

autoload -Uz compinit
compinit

# Created by `pipx` on 2023-07-12 20:56:34
export PATH="$PATH:/Users/npayne81/Library/Python/3.9/bin"

# nvim
export YAMLFIX_SEQUENCE_STYLE="block_style"

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
eval "$(atuin init zsh --disable-up-arrow)"

# Spacelift stuff
alias get-space-stack='export MY_STACK_ID=$(spacectl stack list | fzf | awk -F"|" "{print \$1}" | awk "{\$1=\$1};1")'
alias space-stack-lp='spacectl stack local-preview --id $MY_STACK_ID'
alias space-stack-auto-local-preview='get-space-stack && space-stack-lp'

spacelift-commands () {
    echo "get-space-stack"
    echo "space-stack-lp"
    echo 'space-stack-auto-local-preview'
}

# Terraform
alias tint='terraform init'
