export EDITOR=/usr/bin/vim
export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export DOTFILES_PATH="$HOME/.dotfiles"
export GPG_TTY=$(tty)
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
# Set history size
export HISTSIZE=10000
export HISTFILESIZE=15000

eval "$(/opt/homebrew/bin/brew shellenv)"

# Adds Rust cargo to path
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi
