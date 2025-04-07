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

# OLLAMA
# Allow ollama to be used in browser extensions
alias ollama_serve='OLLAMA_MAX_LOADED_MODELS=2 OLLAMA_NUM_PARALLEL=3 OLLAMA_ORIGINS=moz-extension://*,chrome-extension://*,safari-web-extension://* ollama serve'

# Fix ZSH compinit broken cache
alias fix_zsh_compinit='brew cleanup && rm -f $ZSH_COMPDUMP && omz reload'

# GitHub Create repository
function ghrc() {
    gh repo create "$(basename $(pwd))" --source=. --remote=origin --push "$@"
}
