# Source my normal one
source $HOME/dotfiles/zsh/.zshrc

# fuzzy find to directories with fzf
# from phind.com refactored for mac
# brew install fd
c() {
    cd && cd "$(fd -d 2 | cut -c 1- | fzf )"
}

# work stuff
alias new_reman="cookiecutter https://reman-analytics-cat-com.visualstudio.com/reman_analytics_pipeline_project_template/_git/reman_analytics_pipeline_project_template"
alias sshrhel2="ssh arlremalyticp02.corp.cat.com"

# brew hack for x86_64
alias brew64='arch -x86_64 /usr/local/bin/brew'
alias pyenv64='arch -x86_64 /usr/local/bin/pyenv'

eval "$(atuin init zsh --disable-up-arrow)"

set_proxy() {

    echo "setting proxies"
    export HTTP_PROXY=http://proxy.cat.com:80
    export HTTPS_PROXY=http://proxy.cat.com:80
    export NO_PROXY=localhost,127.0.0.1,cat.com
    export http_proxy=http://proxy.cat.com:80
    export https_proxy=http://proxy.cat.com:80
    export no_proxy=localhost,127.0.0.1,cat.com
    export proxy_set="on"

}

unset_proxy() {
    echo "unsetting proxies"
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset proxy_set
    export proxy_set="off"
}

auto_proxy() {
    # gtimeout after brew install coreutils on mac
    gtimeout 0.5 ping ra.cat.com -c 1 > /dev/null && set_proxy || no_proxy
}
bindkey -s '^a' 'auto_proxy \n'
# alias aproxy="source ~/.local/bin/auto_proxy"