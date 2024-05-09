#!/usr/bin/env bash

# Libs brew
# M1 probably
if [ -d '/opt/homebrew/opt' ]; then
    BREW_OPT_PATH='/opt/homebrew/opt';
fi

# Intel
if [ -d '/usr/local/opt' ]; then
    BREW_OPT_PATH='/usr/local/opt';
fi

BREW_EXECUTABLES_PATH='/usr/local/sbin'
#For pkg-config to find libpq you may need to set:
export PKG_CONFIG_PATH="$BREW_OPT_PATH/libpq/lib/pkgconfig"
LIBPQ_PATH="$BREW_OPT_PATH/libpq/bin"

# Python 3.8 bin path
MY_PYTHON_38_PATH="$HOME/Library/Python/3.8/bin"
export PATH=$LIBPQ_PATH:$PATH:$MY_PYTHON_38_PATH:$BREW_OPT_PATH/bin
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1) --enable-yjit"
export RUBY_YJIT_ENABLE=1
# MySQL Client bin and libraries
export PATH=$PATH:$BREW_OPT_PATH/mysql-client/bin
# MySQL Client compiled libraries
# export LDFLAGS="-L$BREW_OPT_PATH/mysql-client/lib"
# export CPPFLAGS="-I$BREW_OPT_PATH/mysql-client/include"
# export PKG_CONFIG_PATH="$BREW_OPT_PATH/mysql-client/lib/pkgconfig"

# End libs brew

# Load NVM
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# How to identify architecture
# Apple Intel x86_64
# Apple Silicon arm64
# if [[ $(uname -m) == 'arm64' ]]; then
# fi
