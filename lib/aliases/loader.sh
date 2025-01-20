#!/usr/bin/env bash

# Load aliases and utility functions
# File names are load_<name>.sh or load_<name>.zsh
# Exception for load__utils.sh which is used for utility functions, which needs to be loaded first
for f in $(find $DOTFILES_PATH/lib/aliases -iname 'load_*.sh' -o -iname 'load_*.zsh'); do
    source $f
done
