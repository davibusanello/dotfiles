#!/usr/bin/env bash

# Base functions

# Set script verbosity level
# 0 -> Nothing
# 1 -> Basic info
# 2 -> Detailed info
DOTFILES_SCRIPT_LOG_LEVEL=${DOTFILES_SCRIPT_LOG_LEVEL:-1}

# Logging function that respects log level
log_info() {
    if [[ "${DOTFILES_SCRIPT_LOG_LEVEL:-1}" -gt 0 ]]; then
        echo "$@"
    fi
}

log_detail() {
    if [[ "${DOTFILES_SCRIPT_LOG_LEVEL:-1}" -gt 1 ]]; then
        echo "$@"
    fi
}
log_debug() {
    if [[ "${DOTFILES_SCRIPT_LOG_LEVEL:-1}" -gt 2 ]]; then
        echo "$@"
    fi
}
