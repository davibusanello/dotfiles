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
