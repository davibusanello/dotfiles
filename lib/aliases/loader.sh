#!/usr/bin/env bash

# Load aliases and utility functions
# File names are load_<name>.sh or load_<name>.zsh
# Exception for load__utils.sh which is used for utility functions, which needs to be loaded first

# Always source utils first as it contains general utility functions
UTILS="$DOTFILES_PATH/lib/aliases/load__utils.sh"
if [ -f "$UTILS" ]; then
    source "$UTILS"
fi

# Now source the rest, excluding load__utils.sh
for f in $(find $DOTFILES_PATH/lib/aliases \( -iname 'load_*.sh' -o -iname 'load_*.zsh' \) ! -name 'load__utils.sh'); do
    source "$f"
done
