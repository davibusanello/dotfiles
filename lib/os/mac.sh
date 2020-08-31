#!/usr/bin/env bash

# Libs brew
BREW_EXECUTABLES_PATH='/usr/local/sbin'
#For pkg-config to find libpq you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/libpq/lib/pkgconfig"
LIBPQ_PATH='/usr/local/opt/libpq/bin'

# Python 3.8 bin path
MY_PYTHON_38_PATH="$HOME/Library/Python/3.8/bin"
export PATH=$LIBPQ_PATH:$PATH:$MY_PYTHON_38_PATH

# End libs brew

# Load NVM
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
