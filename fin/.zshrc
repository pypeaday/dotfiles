# Source my normal one
source $HOME/dotfiles/zsh/.zshrc

# fuzzy find to directories with fzf
# from phind.com refactored for mac
# brew install fd
c() {
    cd && cd "$(fd -d 2 | cut -c 1- | fzf )"
}

alias rconfig="cp $HOME/dotfiles/fin/.ruff.toml ./.ruff.toml"

alias otp="bash ~/dotfiles/fin/.local/bin/one-password-copy"
alias otw="bash ~/dotfiles/fin/.local/bin/one-password-copy-pw"
alias links="bash ~/dotfiles/fin/.local/bin/links"

# bindkey -s '^o' 'otp \n'
bindkey -s '^p' 'otw \n'
bindkey -s '^o' 'links \n'

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
alias get-space-stack='export SPACELIFT_STACK_ID=$(spacectl stack list | fzf | awk -F"|" "{print \$1}" | awk "{\$1=\$1};1")'
alias space-stack-lp='spacectl stack local-preview --id $SPACELIFT_STACK_ID'
alias space-stack-auto-local-preview='get-space-stack && space-stack-lp'

spacelift-commands () {
    echo "get-space-stack"
    echo "space-stack-lp"
    echo 'space-stack-auto-local-preview'
}

# Terraform
alias tint='terraform init'

get_stack_env_vars() {
    # check if SPACELIFT_STACK_ID exists
    if [ -z ${SPACELIFT_STACK_ID+x} ]; then
        # Define your stack ID
        SPACELIFT_STACK_ID=`spacectl stack list | fzf | awk -F'|' '{print $1}' | awk '{$1=$1};1'`
    fi

    # Save the output of the spacectl and awk commands to a variable
    output=$(spacectl stack environment list --id $SPACELIFT_STACK_ID | awk '{ gsub(/\x1b\[[0-9;]*m/, ""); gsub(/ +/, " "); print }')
 # Pass the output as an argument to the Python script
    python -c "
import sys
import json
import os

data = {}
_id = os.environ.get('SPACELIFT_STACK_ID')

for line in sys.argv[1].splitlines():
    parts = line.split('|')
    if len(parts) >= 3:
        key = parts[0].strip().replace('TF_VAR_', '')
        try:
            value = json.loads(parts[2].strip())
        except json.JSONDecodeError:
            print(f'could not load {key} due to json error')
            print(parts[2])
            print(type(parts[2]))
            value = parts[2].strip()
        data[key] = value

with open(f'spacelift.{_id}.tf.vars.json', 'w') as f:
    json.dump(data, f, indent=4)
" "$output"
}
