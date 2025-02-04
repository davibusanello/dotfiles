# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Load autocompletations instaled by brew
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

#   autoload -Uz compinit
#   compinit
fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export TERM='xterm-256color'

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
#ZSH_THEME="agnoster"

POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_PROMPT_ON_NEWLINE=true

POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_SHORTEN_STRATEGY=truncate_middle
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time root_indicator background_jobs ssh history time)
ZSH_THEME="powerlevel9k/powerlevel9k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
export HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Codestats key
CODESTATS_API_KEY=""

# Per directory history keybind Ctrl+H
PER_DIRECTORY_HISTORY_TOGGLE=^H
HISTIGNORE="&:ls:[bf]g:exit:reset:clear:cd:cd ..:cd..:zh"
HIST_IGNORE_SPACE="true"

# ZOXIDE_CMD_OVERRIDE
ZOXIDE_CMD_OVERRIDE="cd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-extras common-aliases compleat dircycle dirhistory encode64 history colorize docker docker-compose thefuck nvm npm yarn rbenv gem rails mix colored-man-pages zoxide zsh-autosuggestions zsh-syntax-highlighting rust per-directory-history cp pyenv bundler asdf poetry)

# User configuration

export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='vim'
fi
export VISUAL="vim"

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="~/.ssh/dsa_id"
# gpg
export GPG_TTY=$(tty)

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# Personal
# TODO: It was needed for Tilix when using Linux as main OS
# TODO: Check if this is still needed
#source /etc/profile.d/vte-2.91.sh
if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
    source /etc/profile.d/vte.sh
fi

export HISTSIZE=5000
export SAVEHIST=10000
# History display line and date time
export HISTTIMEFORMAT='%F %T '
export PAGER=less
export LESS="-F -X $LESS"
export PSQL_EDITOR=/usr/bin/vim

# Identify and load OS specific shell scripts
if [ -z "$DOTFILES_PATH" ]; then
    export DOTFILES_PATH="$HOME/.dotfiles"
fi
source $DOTFILES_PATH/lib/os_identifier.sh

USER_LOCAL_BIN=$HOME/.local/bin
export PATH=$PATH:$USER_LOCAL_BIN

# Rust environment
source $HOME/.cargo/env
MYBIN=$HOME/bin
export PATH=$PATH:$MYBIN

# Enables iex shell history
export ERL_AFLAGS="-kernel shell_history enabled"
# My personal aliases librar
source $DOTFILES_PATH/lib/aliases/loader.sh

# Ruby gems
# TODO: Check if this is still needed
CURRENT_RUBYGEMS_PATH=$(ruby -r rubygems -e 'puts Gem.user_dir')/bin
export PATH=$PATH:$CURRENT_RUBYGEMS_PATH

# Tesseract
# TODO: Check if this is still needed
#export TESSDATA_PREFIX="$(brew --prefix)/Cellar/tesseract-lang/4.1.0/share"

# FZF
export FZF_DEFAULT_OPTS="--height=70% --preview='bat --color=always --style=header,grid --line-range :300 {}' --preview-window=right:60%:wrap"
export FZF_DEFAULT_COMMAND="rg --files --line-number"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Auto switch node version (nvm)
autoload -U add-zsh-hook
load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
        local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

        if [ "$nvmrc_node_version" = "N/A" ]; then
            nvm install
        elif [ "$nvmrc_node_version" != "$node_version" ]; then
            nvm use
        fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
        echo "Reverting to nvm default version"
        nvm use default
    fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Direnv
eval "$(direnv hook zsh)"

# GPG
export LC_ALL="en_US.UTF-8"
gpgconf --launch gpg-agent

# Load custom completions
fpath+=~/.zfunc

# CLI cheatsheets
# source <(navi widget zsh)
export HISTTIMEFORMAT='%F %T '

# Keep it at the ending of the file
export GPG_TTY=$(tty)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Zellij
eval "$(zellij setup --generate-auto-start zsh)"

# Atuin
# eval "$(atuin init zsh)"

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f "${HOME}/google-cloud-sdk/path.zsh.inc" ]; then . "${HOME}/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then . "${HOME}/google-cloud-sdk/completion.zsh.inc"; fi
