#!/usr/bin/env bash

# Custom log directory
export CUSTOM_LOG_DIR="$HOME/logs"
if [[ ! -d "$CUSTOM_LOG_DIR" ]]; then
    mkdir -p "$CUSTOM_LOG_DIR"
fi

# Base functions

# Set script verbosity level
# 0 -> Nothing
# 1 -> Basic info
# 2 -> Detailed info
# 3 -> Debug info
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

# Prepend one or more directories to the front of $PATH if they exist. This helper:
#  - Accepts any number of path arguments (e.g. /opt/homebrew/bin "$HOME/.bun/bin" "$HOME/node_modules/.bin").
#  - Filters out empty or non-existent entries (uses -d test).
#  - Preserves the order of the provided arguments (first argument becomes highest priority).
#  - Removes any existing occurrences of those directories from the current $PATH to avoid duplicates.
#  - Prepends the resulting unique list to $PATH.
#
# Notes:
#  - Safe to call multiple times; the deduplication step prevents repeated entries.
#  - Works in bash and zsh. Accepts symlinked directories because -d returns true for them.
#  - If no candidate directories exist, the function returns without modifying $PATH.
#
# Example:
#   prepend_paths_if_exist \
#     "/opt/homebrew/bin" \
#     "$HOME/.bun/bin" \
#     "$HOME/node_modules/.bin"
#
# Edge cases:
#  - Empty string arguments are ignored.
#  - If the same path is passed multiple times, it is only added once (first occurrence kept).
#
prepend_paths_if_exist() {
    local working_path
    local -a uniques=()

    # Collect only existing directories and dedupe while preserving order
    for working_path in "$@"; do
        [[ -n "$working_path" && -d "$working_path" ]] || continue
        [[ " ${uniques[*]} " == *" $working_path "* ]] && continue
        uniques+=("$working_path")
    done

    # Nothing to do
    [[ ${#uniques[@]} -eq 0 ]] && return

    # Remove any occurrences of the selected paths from the existing PATH
    # using native bash/zsh string manipulation instead of sed to avoid bootstrapping issues
    local trimmed=":$PATH:"
    for working_path in "${uniques[@]}"; do
        trimmed="${trimmed//:$working_path:/:}"
    done
    trimmed="${trimmed#:}" # Remove leading colon
    trimmed="${trimmed%:}" # Remove trailing colon

    # Prepend the unique paths (in order) and export
    local new_path
    new_path="$(
        IFS=:
        echo "${uniques[*]}"
    )"
    if [[ -n "$trimmed" ]]; then
        export PATH="$new_path:$trimmed"
    else
        export PATH="$new_path"
    fi
}
