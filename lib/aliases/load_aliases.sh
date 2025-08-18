#!/usr/bin/env bash

# Aliases for common commands

# File System
# Tree Colorized, all files, follow symbolic links, list 3 levels
alias tree='tree -CalL 3 --dirsfirst'

# Replicate directory structure from source to destination
# Reason: It's going to replaces the Python script/cpr_structure.py
replicate_dir() {
  rsync -av --include='*/' --exclude='*' "$1" "$2"
}

# OLLAMA
# Allow ollama to be used in browser extensions
alias ollama_serve='OLLAMA_MAX_LOADED_MODELS=2 OLLAMA_NUM_PARALLEL=3 OLLAMA_ORIGINS=moz-extension://*,chrome-extension://*,safari-web-extension://* ollama serve'

# Fix ZSH compinit broken cache
alias fix_zsh_compinit='brew cleanup && rm -f $ZSH_COMPDUMP && omz reload'

# Sync dirs
alias rsync-update='rsync -avh --update --progress'
alias sync-dir='rsync-update'

alias dump_path='pwd >> ~/dump_paths.md'

# Timestamp aliases
alias timestamp_iso8601='date +"%Y-%m-%d %H:%M:%S%z"'
alias timestamp_short='date +"%Y-%m-%d %H:%M"'
alias timestamp_iso8601_filename='date +"%Y%m%dT%H%M%S%z"'
alias timestamp_iso8601_filename_without_timezone='date +"%Y%m%dT%H%M%S"'
alias timestamp_iso8601_filename_with_epoch='date +"%Y%m%dT%H%M%S%N%z"'

# Ripgrep
# Search all patterns no necessarily in the same line
ripgrep_all_patterns() {
    if [ "$#" -eq 0 ]; then
        echo "Usage: rg_all_patterns <pattern1> <pattern2> ..."
        return 1
    fi

    rg -f <(printf "%s\n" "$@")
}

alias rg_pa='ripgrep_all_patterns'
