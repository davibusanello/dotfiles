# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

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

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# Using in docker
#  ruby rails gem bundler command-not-found
# Codestats key
CODESTATS_API_KEY=""

plugins=(git git-extras common-aliases compleat dircycle dirhistory encode64 history colorize docker docker-compose thefuck nvm npm yarn rbenv gem rails mix zsh_reload fzf fd colored-man-pages zsh-autosuggestions zsh-syntax-highlighting rust cargo per-directory-history cp zsh-interactive-cd pyenv)

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

#Personal
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

# export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr
#   /games:/usr/local/games:/snap/bin"

#Powerline themes
#if [[ -r /usr/local/lib/python2.7/dist-packages/powerline/bindings/zsh/powerline.zsh ]]; then
#    source /usr/local/lib/python2.7/dist-packages/powerline/bindings/zsh/powerline.zsh
#fi

#POWERLEVEL9K_MODE='awesome-patched'

# Identify and load OS specific shell scripts
if [ -z "$DOTFILES_PATH" ]; then
    export DOTFILES_PATH="$HOME/.dotfiles"
fi
source $DOTFILES_PATH/lib/os_identifier.sh

# export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
#Setting the GEM_PATH and GEM_HOME variables may not be necessary, check 'gem env' output to verify whether both variables already exist
# GEM_HOME=$(ls -t -U | ruby -e 'puts Gem.user_dir')
# GEM_PATH=$GEM_HOME/bin
# COMPOSER_HOME=$HOME/.composer
# COMPOSER_PATH=$COMPOSER_HOME/vendor/bin
# NPM_USER_BIN="$NPM_CONFIG_PREFIX/bin"
# NPM_PATH=$(npm bin)
# YARN_HOME=$(yarn global dir)
# YARN_GLOBAL_PATH=$YARN_HOME/node_modules/.bin
# YARN_PATH=$HOME/.yarn/bin
USER_LOCAL_BIN=$HOME/.local/bin
#RUBYGEMS_2_5_PATH=$HOME/.gem/ruby/2.5.0/bin
# ELIXIR_PATH=$(which elixir)
# export PATH=$PATH:$COMPOSER_PATH:$YARN_PATH:$YARN_GLOBAL_PATH:$NPM_PATH:$USER_LOCAL_BIN:$NPM_USER_BIN:$RUBYGEMS_2_5_PATH:$ELIXIR_PATH
# export PATH=$PATH:$COMPOSER_PATH:$NPM_PATH:$USER_LOCAL_BIN:$NPM_USER_BIN:$ELIXIR_PATH
export PATH=$PATH:$USER_LOCAL_BIN

# Rust environment
source $HOME/.cargo/env
MYBIN=$HOME/bin
export PATH=$PATH:$MYBIN

# Enables iex shell history
export ERL_AFLAGS="-kernel shell_history enabled"
# My personal aliases librar
source $DOTFILES_PATH/lib/aliases/loader.sh
#export PATH="$HOME/.rbenv/bin:$PATH"
#eval "$(rbenv init -)"
#source /usr/share/nvm/init-nvm.sh

CURRENT_RUBYGEMS_PATH=$(ruby -r rubygems -e 'puts Gem.user_dir')/bin
export PATH=$PATH:$CURRENT_RUBYGEMS_PATH
export FZF_DEFAULT_OPTS="--height=70% --preview='bat --color=always --style=header,grid --line-range :300 {}' --preview-window=right:60%:wrap"
export FZF_DEFAULT_COMMAND="rg --files --line-number"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
:
export NVM_DIR="$HOME/.nvm"

# Auto switch node version
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

eval "$(direnv hook zsh)"
export LC_ALL="en_US.UTF-8"
gpgconf --launch gpg-agent

# CLI cheatsheets
source <(navi widget zsh)
export HISTTIMEFORMAT='%F %T '
# Keep it at the ending of the file

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

