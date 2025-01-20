#!/usr/bin/env bash

# Libs brew
# Determine Homebrew base path based on architecture
if [ -d '/opt/homebrew/opt' ]; then
    BREW_BASE='/opt/homebrew' # Apple Silicon
    BREW_OPT_PATH="$BREW_BASE/opt"
elif [ -d '/usr/local/opt' ]; then
    BREW_BASE='/usr/local' # Intel
    BREW_OPT_PATH="$BREW_BASE/opt"
fi

# Set up base Homebrew paths first
export PATH="$BREW_BASE/bin:$BREW_BASE/sbin:$PATH"

# PKG configs
export PKG_CONFIG_PATH="$BREW_OPT_PATH/libpq/lib/pkgconfig"
LIBPQ_PATH="$BREW_OPT_PATH/libpq/bin"

# Build the PATH
export PATH="$LIBPQ_PATH:$PATH"
export PATH="$BREW_OPT_PATH/bin:$PATH"
export PATH="$BREW_OPT_PATH/mysql-client/bin:$PATH"

# Ruby configs
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl) --enable-yjit"
export RUBY_YJIT_ENABLE=1
# MySQL Client bin and libraries
export PATH=$PATH:$BREW_OPT_PATH/mysql-client/bin
# MySQL Client compiled libraries
# export LDFLAGS="-L$BREW_OPT_PATH/mysql-client/lib"
# export CPPFLAGS="-I$BREW_OPT_PATH/mysql-client/include"
# export PKG_CONFIG_PATH="$BREW_OPT_PATH/mysql-client/lib/pkgconfig"

# End libs brew

# Load NVM
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"                                       # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# How to identify architecture
# Apple Intel x86_64
# Apple Silicon arm64
# if [[ $(uname -m) == 'arm64' ]]; then
# fi
