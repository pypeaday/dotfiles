# Source my normal one
source $HOME/dotfiles/zsh/.zshrc

# fuzzy find to directories with fzf
# from phind.com refactored for mac
# brew install fd
c() {
    cd ~/projects && cd "$(fd -d 2 | cut -c 1- | fzf )"
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
        export SPACELIFT_STACK_ID=`spacectl stack list | fzf | awk -F'|' '{print $1}' | awk '{$1=$1};1'`
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
" "$output"
    json.dump(data, f, indent=4)
}

export K9S_CONFIG_DIR=$HOME/.config/k9s
#compdef k9s
compdef _k9s k9s

# zsh completion for k9s                                  -*- shell-script -*-

__k9s_debug()
{
    local file="$BASH_COMP_DEBUG_FILE"
    if [[ -n ${file} ]]; then
        echo "$*" >> "${file}"
    fi
}

_k9s()
{
    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    local lastParam lastChar flagPrefix requestComp out directive comp lastComp noSpace keepOrder
    local -a completions

    __k9s_debug "\n========= starting completion logic =========="
    __k9s_debug "CURRENT: ${CURRENT}, words[*]: ${words[*]}"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}")
    __k9s_debug "Truncated words[*]: ${words[*]},"

    lastParam=${words[-1]}
    lastChar=${lastParam[-1]}
    __k9s_debug "lastParam: ${lastParam}, lastChar: ${lastChar}"

    # For zsh, when completing a flag with an = (e.g., k9s -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    # Prepare the command to obtain completions
    requestComp="${words[1]} __complete ${words[2,-1]}"
    if [ "${lastChar}" = "" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go completion code.
        __k9s_debug "Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __k9s_debug "About to call: eval ${requestComp}"

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)
    __k9s_debug "completion output: ${out}"

    # Extract the directive integer following a : from the last line
    local lastLine
    while IFS='\n' read -r line; do
        lastLine=${line}
    done < <(printf "%s\n" "${out[@]}")
    __k9s_debug "last line: ${lastLine}"

    if [ "${lastLine[1]}" = : ]; then
        directive=${lastLine[2,-1]}
        # Remove the directive including the : and the newline
        local suffix
        (( suffix=${#lastLine}+2))
        out=${out[1,-$suffix]}
    else
        # There is no directive specified.  Leave $out as is.
        __k9s_debug "No directive found.  Setting do default"
        directive=0
    fi

    __k9s_debug "directive: ${directive}"
    __k9s_debug "completions: ${out}"
    __k9s_debug "flagPrefix: ${flagPrefix}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __k9s_debug "Completion received error. Ignoring completions."
        return
    fi

    local activeHelpMarker="_activeHelp_ "
    local endIndex=${#activeHelpMarker}
    local startIndex=$((${#activeHelpMarker}+1))
    local hasActiveHelp=0
    while IFS='\n' read -r comp; do
        # Check if this is an activeHelp statement (i.e., prefixed with $activeHelpMarker)
        if [ "${comp[1,$endIndex]}" = "$activeHelpMarker" ];then
            __k9s_debug "ActiveHelp found: $comp"
            comp="${comp[$startIndex,-1]}"
            if [ -n "$comp" ]; then
                compadd -x "${comp}"
                __k9s_debug "ActiveHelp will need delimiter"
                hasActiveHelp=1
            fi

            continue
        fi

        if [ -n "$comp" ]; then
            # If requested, completions are returned with a description.
            # The description is preceded by a TAB character.
            # For zsh's _describe, we need to use a : instead of a TAB.
            # We first need to escape any : as part of the completion itself.
            comp=${comp//:/\\:}

            local tab="$(printf '\t')"
            comp=${comp//$tab/:}

            __k9s_debug "Adding completion: ${comp}"
            completions+=${comp}
            lastComp=$comp
        fi
    done < <(printf "%s\n" "${out[@]}")

    # Add a delimiter after the activeHelp statements, but only if:
    # - there are completions following the activeHelp statements, or
    # - file completion will be performed (so there will be choices after the activeHelp)
    if [ $hasActiveHelp -eq 1 ]; then
        if [ ${#completions} -ne 0 ] || [ $((directive & shellCompDirectiveNoFileComp)) -eq 0 ]; then
            __k9s_debug "Adding activeHelp delimiter"
            compadd -x "--"
            hasActiveHelp=0
        fi
    fi

    if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
        __k9s_debug "Activating nospace."
        noSpace="-S ''"
    fi

    if [ $((directive & shellCompDirectiveKeepOrder)) -ne 0 ]; then
        __k9s_debug "Activating keep order."
        keepOrder="-V"
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local filteringCmd
        filteringCmd='_files'
        for filter in ${completions[@]}; do
            if [ ${filter[1]} != '*' ]; then
                # zsh requires a glob pattern to do file filtering
                filter="\*.$filter"
            fi
            filteringCmd+=" -g $filter"
        done
        filteringCmd+=" ${flagPrefix}"

        __k9s_debug "File filtering command: $filteringCmd"
        _arguments '*:filename:'"$filteringCmd"
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        subdir="${completions[1]}"
        if [ -n "$subdir" ]; then
            __k9s_debug "Listing directories in $subdir"
            pushd "${subdir}" >/dev/null 2>&1
        else
            __k9s_debug "Listing directories in ."
        fi

        local result
        _arguments '*:dirname:_files -/'" ${flagPrefix}"
        result=$?
        if [ -n "$subdir" ]; then
            popd >/dev/null 2>&1
        fi
        return $result
    else
        __k9s_debug "Calling _describe"
        if eval _describe $keepOrder "completions" completions $flagPrefix $noSpace; then
            __k9s_debug "_describe found some completions"

            # Return the success of having called _describe
            return 0
        else
            __k9s_debug "_describe did not find completions."
            __k9s_debug "Checking if we should do file completion."
            if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
                __k9s_debug "deactivating file completion"

                # We must return an error code here to let zsh know that there were no
                # completions found by _describe; this is what will trigger other
                # matching algorithms to attempt to find completions.
                # For example zsh can match letters in the middle of words.
                return 1
            else
                # Perform file completion
                __k9s_debug "Activating file completion"

                # We must return the result of this command, so it must be the
                # last command, or else we must store its result to return it.
                _arguments '*:filename:_files'" ${flagPrefix}"
            fi
        fi
    fi
}

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_k9s" ]; then
    _k9s
fi

# Added by Windsurf
export PATH="/Users/npayne81/.codeium/windsurf/bin:$PATH"
