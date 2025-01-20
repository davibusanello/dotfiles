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
