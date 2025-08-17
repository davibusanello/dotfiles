#!/usr/bin/env bash

# Common simple functions

# Fixes poetry instalation after brew update
# TODO: review if this is still needed
function fix_poetry() {
    curl -sSL https://install.python-poetry.org | sed 's/symlinks=False/symlinks=True/' | python3 -
}

# Get only the command name
function normalize_command() {
    echo "$1" | awk '{print $1}'
}

# Output and log command using tee
function log_command() {
    # Set default log directory if CUSTOM_LOG_DIR is not set
    local log_dir="${CUSTOM_LOG_DIR:-$HOME/logs}"

    # # Ensure log directory exists
    # if [[ ! -d "$log_dir" ]]; then
    #     mkdir -p "$log_dir"
    # fi

    # Generate timestamp and filename
    local timestamp_file
    timestamp_file="$(timestamp_iso8601_filename_with_epoch)"
    local command_name
    command_name="$(normalize_command "$@")"
    local filename="${timestamp_file}_${command_name}.log"
    local filepath="$log_dir/$filename"

    # Log command metadata
    {
        echo "Command: $*"
        echo "Path: $(pwd)"
        echo "PID: $$"
        echo "User: $(whoami)"
        echo "Timestamp: $(date +"%Y-%m-%d %H:%M:%S%z")"
        echo "----------------------------------------"
    } >> "$filepath"

    echo "Logging to $filepath"
    # Use eval to expand aliases and execute the command
    eval "$*" 2>&1 | tee -a "$filepath"
}

# Clean up log files older than x
# Usage: cleanup_logs <period>
# <period> is a time period string accepted by fd, e.g. "1d", "2w", "3m"
# cleanup_logs "1d"
function cleanup_logs() {
    fd . -tf -e log --change-older-than "$1" -X rm -f \; --full-path "$CUSTOM_LOG_DIR"
}

alias cleanup_logs_3_months="cleanup_logs 3M"
