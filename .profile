export EDITOR=/usr/bin/vim
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
#export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export DOTFILES_PATH="$HOME/.dotfiles"
export GPG_TTY=$(tty)
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# Adds Rust cargo to path
source "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# Adds Pyenv to shell
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi
