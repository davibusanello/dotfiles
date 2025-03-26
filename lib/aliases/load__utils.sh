#!/usr/bin/env bash

# Utils functions

# Helper function to check if a command exists
function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Reload shell configuration without full dotfiles reload
function reload() {
    echo "🔄 Checking for recent changes from last hour..."
    local HOUR_IN_SECONDS=3600
    local current_time=$(date +%s)
    local needs_reload=false
    local shell_reloaded=false
    local dotfiles_path="${DOTFILES_PATH:-$HOME/.dotfiles}"

    # Helper function to check if file was modified in the last hour
    # Now follows symbolic links and handles both the symlink and real file
    function was_recently_modified() {
        local file="$1"
        local real_file

        # If it's a symlink, get the real file path
        if [ -L "$file" ]; then
            real_file=$(readlink -f "$file")
        else
            real_file="$file"
        fi

        # Check if file exists
        if [ ! -f "$real_file" ]; then
            return 1
        fi

        local file_time=$(stat -f %m "$real_file")
        local time_diff=$((current_time - file_time))
        [ $time_diff -le $HOUR_IN_SECONDS ]
    }

    # Check and reload shell specific config first
    if [ -n "$ZSH_VERSION" ]; then
        if [ -f "$HOME/.zshrc" ] && was_recently_modified "$HOME/.zshrc"; then
            echo "📝 Found recent changes in .zshrc"
            if [ -n "$ZSH" ] && [ -f "$ZSH/oh-my-zsh.sh" ]; then
                echo "🚀 Using Oh My Zsh reload"
                omz reload
            else
                source "$HOME/.zshrc"
            fi
            echo "✅ Reloaded zsh configuration"
            shell_reloaded=true
        fi
    elif [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
        if was_recently_modified "$HOME/.bashrc"; then
            echo "📝 Found recent changes in .bashrc"
            source "$HOME/.bashrc"
            echo "✅ Reloaded bash configuration"
            shell_reloaded=true
        fi
    fi

    # Only reload load_* files if shell wasn't reloaded (since shell configs typically source these files)
    if [ "$shell_reloaded" = false ]; then
        local load_files=()
        # Find all load_*.sh and load_*.zsh files
        while IFS= read -r -d '' file; do
            load_files+=("$file")
        done < <(find "$dotfiles_path/lib/aliases" -maxdepth 1 -type f \( -name "load_*.sh" -o -name "load_*.zsh" \) -print0)

        for load_file in "${load_files[@]}"; do
            if was_recently_modified "$load_file"; then
                echo "📝 Found recent changes in $(basename "$load_file")"
                source "$load_file"
                echo "✅ Reloaded $(basename "$load_file")"
                needs_reload=true
            fi
        done
    fi

    if [ "$shell_reloaded" = true ] || [ "$needs_reload" = true ]; then
        echo "✨ Shell configuration reload complete!"
    else
        echo "👌 No recent changes found, nothing to reload"
    fi
}

# Helper to dump Zellij pane scrollback
function dump_zellij_pane_scrollback() {
    local current_date_time="$(date +%Y%m%d_%H%M%S)"
    local output_file="/tmp/${current_date_time}_zellij_pane.log"

    zellij action dump-screen -f "$output_file"
}

# Helper to restore sessions after Zellij update
function restore_zellij_sessions() {
    # Check if zellij is installed
    if ! command_exists "zellij"; then
        echo "❌ Zellij is not installed. Cannot restore sessions."
        return 1
    fi

    # Get current zellij version
    local current_version=$(zellij --version | cut -d ' ' -f 2)
    local cache_dir="$HOME/Library/Caches/org.Zellij-Contributors.Zellij"

    if [ ! -d "$cache_dir" ]; then
        echo "❌ Zellij cache directory not found at $cache_dir"
        return 1
    fi

    # Find the most recent previous version (highest version number that's not current)
    local previous_version=$(find "$cache_dir" -maxdepth 1 -type d -name "[0-9]*.[0-9]*.[0-9]*" |
        grep -v "$current_version" |
        sort -Vr |
        head -n 1 |
        xargs basename 2>/dev/null)

    if [ -z "$previous_version" ]; then
        echo "❌ No previous Zellij version found to restore from."
        return 1
    fi

    # Check if the previous version directory exists and has content
    if [ ! -d "$cache_dir/$previous_version" ] || [ ! "$(ls -A "$cache_dir/$previous_version" 2>/dev/null)" ]; then
        echo "❌ Previous version directory ($previous_version) is empty or doesn't exist."
        return 1
    fi

    echo "🔄 Restoring Zellij sessions from version $previous_version to $current_version..."

    # Create the current version directory if it doesn't exist
    mkdir -p "$cache_dir/$current_version"

    # Copy data from previous version to current version
    cp -r "$cache_dir/$previous_version/"* "$cache_dir/$current_version/"

    if [ $? -eq 0 ]; then
        echo "✅ Successfully restored Zellij sessions from version $previous_version to $current_version"
    else
        echo "❌ Failed to restore Zellij sessions."
        return 1
    fi
}
