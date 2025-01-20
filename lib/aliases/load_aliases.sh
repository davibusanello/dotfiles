#!/usr/bin/env bash

# Aliases for common commands

# File System
# Tree Colorized, all files, follow symbolic links, list 3 levels
alias tree='tree -CalL 3 --dirsfirst'

# Replicate directory structure from source to destination
# Reason: It's going to replaces the Python script/cpr_structure.py
alias replicate_dir="rsync -av --include='*/' --exclude='*' \$1 \$2"

# Git
# Detailed git diff
alias gdd='git wdiff'
