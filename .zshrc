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

# Per directory history keybind Ctrl+H
PER_DIRECTORY_HISTORY_TOGGLE=^H
HISTIGNORE="&:ls:[bf]g:exit:reset:clear:cd:cd ..:cd..:zh"
HIST_IGNORE_SPACE="true"

# History search enhancements
ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH=1

# ZOXIDE_CMD_OVERRIDE
ZOXIDE_CMD_OVERRIDE="cd"

# Load private envs and dotfiles that must remain outside of git or public repos
# Load private envs  --- IGNORE ---
if [ -f "$HOME/.vp-dotfiles.env" ]; then
# shellcheck disable=SC1091
    \. "$HOME/.vp-dotfiles.env"
fi

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-extras common-aliases compleat dircycle dirhistory encode64 history colorize docker docker-compose bun podman fnm npm yarn rbenv gem rails mix colored-man-pages zoxide zsh-autosuggestions zsh-syntax-highlighting rust per-directory-history cp pyenv bundler asdf poetry)

# User configuration

export MANPATH="/usr/local/man:$MANPATH"

# shellcheck disable=SC1091
source "$ZSH/oh-my-zsh.sh"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
else
    export EDITOR="vim"
    export VISUAL="vim"
fi

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
export SSH_KEY_PATH="$HOME/.ssh/dsa_id"
# gpg
GPG_TTY="$(tty)"
export GPG_TTY

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig='$EDITOR ~/.zshrc'
alias ohmyzsh='$EDITOR ~/.oh-my-zsh'

# Personal
export HISTSIZE=10000
export SAVEHIST=15000
# History display line and date time
export HISTTIMEFORMAT='%F %T '
export PAGER=less
export LESS="-F -X $LESS"
export PSQL_EDITOR=$EDITOR

# Identify and load OS specific shell scripts
if [ -z "$DOTFILES_PATH" ]; then
    export DOTFILES_PATH="$HOME/.dotfiles"
fi

# Set script verbosity level
# 0 -> Nothing
# 1 -> Basic info
# 2 -> Detailed info
DOTFILES_SCRIPT_LOG_LEVEL=${DOTFILES_SCRIPT_LOG_LEVEL:-1}
source  "$DOTFILES_PATH/lib/base_functions.sh"
source "$DOTFILES_PATH/lib/os_identifier.sh"

USER_LOCAL_BIN=$HOME/.local/bin
export PATH=$PATH:$USER_LOCAL_BIN

# Rust environment
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
fi

MYBIN=$HOME/bin
export PATH=$PATH:$MYBIN

# Enables iex shell history
export ERL_AFLAGS="-kernel shell_history enabled"
# My personal aliases librar
source "$DOTFILES_PATH/lib/aliases/loader.sh"

# Ruby gems
# TODO: Check if this is still needed
add_ruby_gems_to_path() {
    if command -v ruby >/dev/null 2>&1; then
        local rubygems_path
        rubygems_path="$(ruby -r rubygems -e 'puts Gem.user_dir' 2>/dev/null)/bin"
        if [[ -d "$rubygems_path" && ":$PATH:" != *":$rubygems_path:"* ]]; then
            export PATH="$PATH:$rubygems_path"
        fi
    fi
}
add_ruby_gems_to_path

# Tesseract
# TODO: Check if this is still needed
#export TESSDATA_PREFIX="$(brew --prefix)/Cellar/tesseract-lang/4.1.0/share"

# FZF
# Set up fzf key bindings and fuzzy completion
# source <(fzf --zsh)

export FZF_DEFAULT_OPTS="--height=70% --preview='bat --color=always --style=header,grid --line-range :300 {}' --preview-window=right:60%:wrap"
export FZF_DEFAULT_COMMAND="rg --files --line-number"
# export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

autoload -U add-zsh-hook

# GPG
export LC_ALL="en_US.UTF-8"
gpgconf --launch gpg-agent

# Load custom completions
fpath+=~/.zfunc

# CLI cheatsheets
# source <(navi widget zsh)
export HISTTIMEFORMAT='%F %T '

# Keep it at the ending of the file
# shellcheck source=/dev/null
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Load fzf
#  shellcheck source=/dev/null
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Zellij
# Disabled is messing with session list every time I open a terminal on editors or any other automation/script runs
# eval "$(zellij setup --generate-auto-start zsh)"

# Atuin
# eval "$(atuin init zsh)"

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
# shellcheck source=/dev/null
if [ -f "${HOME}/google-cloud-sdk/path.zsh.inc" ]; then . "${HOME}/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
# shellcheck source=/dev/null
if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then . "${HOME}/google-cloud-sdk/completion.zsh.inc"; fi

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
# Following shellcheck will break completations
# shellcheck disable=SC2206
if [[ -d "${HOME}/.docker/completions" ]]; then
    fpath=("${HOME}/.docker/completions" $fpath)
fi

# Initialize completion system once (handles zcompdump properly)
# Check for and remove stale zcompdump lock files
[[ -f ~/.zcompdump.zwc ]] && rm -f ~/.zcompdump.zwc 2>/dev/null
autoload -Uz compinit

# Run compinit with cache optimization (rebuild cache only once per day)
# The complex expression is a zsh glob qualifier - shellcheck doesn't understand it
# shellcheck disable=SC1009,SC1073,SC1072,SC1036
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
# End of completion initialization
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/davibusanello/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
