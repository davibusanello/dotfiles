#!/usr/bin/env bash

# Common simple functions

# Generate .gitignore file
function gi() { curl -sLw n https://www.toptal.com/developers/gitignore/api/$@; }

# Fixes poetry instalation after brew update
# TODO: review if this is still needed
function fix_poetry() {
    #
    curl -sSL https://install.python-poetry.org | python3 - --uninstall
    curl -sSL https://install.python-poetry.org | python3
}

function git_default_branch() {
    git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5
}

# Function to handle git clone for URLs with additional parameters
# Usage:
#   @ <repository_url> [options]
#
# Description:
#   A wrapper around git clone that provides smart directory naming for repositories
#   and maintains compatibility with all git clone parameters.
#
# Parameters:
#   $1 - Repository URL (supports HTTPS, HTTP, and SSH formats)
#   $2+ - Additional parameters passed directly to git clone
#
# Behavior:
#   1. Without additional parameters:
#      Creates a directory named {user}_{repository} for GitHub repos
#      Example: @ https://github.com/user/repo.git -> user_repo
#
#   2. With "." as parameter:
#      Clones into current directory (standard git clone behavior)
#      Example: @ https://github.com/user/repo.git . -> repo
#
#   3. With additional parameters:
#      Passes all parameters to git clone
#      Example: @ https://github.com/user/repo.git custom-dir --depth 1
#
# Returns:
#   0 - Success
#   1 - Invalid repository URL
function simplified_git_clone() {
    if [[ "$1" =~ "^(https://|http://|git@)([A-Za-z0-9.-]+\.[A-Za-z]{2,})(:[0-9]+)?/.+(.git)?$" ]]; then
        local url="$1"
        local repo_name=$(basename "$url" .git)

        # Extract repository user and name
        local repo_path=$(echo "$url" | sed 's|^https://[^/]*/||' | sed 's|^http://[^/]*/||' | sed 's|^git@[^:]*:||' | sed 's/.git$//')

        # Check if the repository path contains a user part
        if [[ "$repo_path" =~ ^[^/]+/[^/]+$ ]]; then
            local repo_user=$(echo "$repo_path" | cut -d'/' -f1)
            local custom_dir="${repo_user}_${repo_name}"
        else
            local custom_dir="$repo_name"
        fi

        echo "Cloning repository: $url"

        # If no additional parameters or only "." is provided
        if [ $# -eq 1 ]; then
            git clone "$url" "$custom_dir"
        elif [ $# -eq 2 ] && [ "$2" = "." ]; then
            git clone "$url"
        else
            # Pass all arguments after $1 to git clone
            git clone "$url" "${@:2}"
        fi
    else
        echo "Not a valid git repository URL"
        return 1
    fi
}

# Alias for @ symbol to trigger my simplified git clone helper
alias @='simplified_git_clone'

# Function to sync all git repositories in subdirectories in first level of the current directory
# This function will:
# 1. Check each directory for git repository
# 2. Handle pending changes (stash if needed)
# 3. Sync with remote based on current branch status
# 4. Return to original branch if switched
# TODO: handle multiple remotes (origin, upstream, etc.)
function sync_git_repos() {
    # Store the original directory
    local original_dir=$(pwd)
    local exit_status=0

    # Find all directories in the current path
    for dir in */; do
        if [ -d "$dir" ]; then
            cd "$dir" || continue

            # Check if it's a git repository
            if git rev-parse --git-dir >/dev/null 2>&1; then
                # Store original git settings
                local original_autocrlf=$(git config --get core.autocrlf)
                local original_safecrlf=$(git config --get core.safecrlf)
                # Temporarily disable CRLF conversion and warnings
                if [ -n "$original_autocrlf" ]; then
                    git config core.autocrlf false
                fi
                if [ -n "$original_safecrlf" ]; then
                    git config core.safecrlf false
                fi
                # Get current branch/tag
                local current_ref=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)
                # Get default branch
                local default_branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)

                # Check for pending changes
                if ! git diff --quiet || ! git diff --cached --quiet; then
                    echo "📦 $dir - Stashing changes"
                    if ! git stash push -q -m "Auto-stash by sync_git_repos on $(date)"; then
                        echo "❌ $dir - Failed to stash changes"
                    fi
                fi

                local has_changes=false
                # If we're on the default branch
                if [ "$current_ref" = "$default_branch" ]; then
                    if ! git pull -q origin "$default_branch"; then
                        echo "❌ $dir - Failed to sync $default_branch"
                    elif [ "$(git rev-list HEAD...origin/$default_branch --count)" != "0" ]; then
                        has_changes=true
                    fi
                else
                    # Sync current branch/tag
                    if ! git fetch -q origin "$current_ref:$current_ref" 2>/dev/null; then
                        echo "ℹ️  $dir - Could not sync $current_ref directly"
                    elif [ "$(git rev-list HEAD...origin/$current_ref --count 2>/dev/null)" != "0" ]; then
                        has_changes=true
                    fi

                    # Switch to default branch and sync
                    if git checkout -q "$default_branch"; then
                        if ! git pull -q origin "$default_branch"; then
                            echo "❌ $dir - Failed to sync $default_branch"
                        elif [ "$(git rev-list HEAD...origin/$default_branch --count)" != "0" ]; then
                            has_changes=true
                        fi
                        git checkout -q "$current_ref"
                    else
                        echo "❌ $dir - Failed to switch to $default_branch"
                    fi
                fi

                if $has_changes; then
                    echo "✅ $dir - Synced with remote"
                fi

                # Restore original git settings
                if [ -n "$original_autocrlf" ]; then
                    git config core.autocrlf "$original_autocrlf"
                fi
                if [ -n "$original_safecrlf" ]; then
                    git config core.safecrlf "$original_safecrlf"
                fi
            fi

            # Return to original directory before processing next
            cd "$original_dir" || exit 1
        fi
    done

    return $exit_status
}

# Alias for the sync_git_repos helper function
alias sync-repos='sync_git_repos'

# Resets default branch to origin/default_branch
# Parameters:
#   --hard: Use git reset --hard instead of pull (destructive)
#   Additional parameters are passed directly to git pull (if not using --hard)
# Example:
#   reset-default-branch --rebase
#   reset-default-branch --hard
function reset_default_branch() {
    local default_branch=$(git_default_branch)
    local use_hard_reset=false
    local args=()

    # Parse arguments
    for arg in "$@"; do
        if [ "$arg" = "--hard" ]; then
            use_hard_reset=true
        else
            args+=("$arg")
        fi
    done

    if ! git switch -q "$default_branch"; then
        echo "❌ Failed to switch to $default_branch"
        return 1
    fi

    if ! git fetch -q origin "$default_branch"; then
        echo "❌ Failed to fetch $default_branch"
        return 1
    fi

    if $use_hard_reset; then
        if ! git reset --hard "origin/$default_branch"; then
            echo "❌ Failed to hard reset to origin/$default_branch"
            return 1
        fi
    else
        if ! git pull -q origin "$default_branch" "${args[@]}"; then
            echo "❌ Failed to pull $default_branch"
            return 1
        fi
    fi

    echo "✅ Successfully reset $default_branch"
}

# Alias for the reset_default_branch helper function
alias reset-default-branch='reset_default_branch'
alias grdbh='reset_default_branch --hard'
