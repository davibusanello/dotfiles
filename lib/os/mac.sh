#!/usr/bin/env bash

# Libs brew
BREW_EXECUTABLES_PATH='/usr/local/sbin'
#For pkg-config to find libpq you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/libpq/lib/pkgconfig"
LIBPQ_PATH='/usr/local/opt/libpq/bin'

export PATH=$LIBPQ_PATH:$PATH

# End libs brew
