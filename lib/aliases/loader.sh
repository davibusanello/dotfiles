#!/usr/bin/env bash
# for f in $DOTFILES_PATH/lib/aliases/load_*; do source $f; done
for f in $(find $DOTFILES_PATH/lib/aliases -iname 'load_*.sh'); do source $f; done