#!/usr/bin/env zsh

# Load developer tools

## Paths to skip auto switch version of runtime version managers
SKIP_AUTO_SWITCH_VERSION_PATHS=(
    "$HOME/Projects/project-examples"
    "$HOME/Projects/docs"
)

## Direnv
SKIP_AUTO_LOAD_DIRENV_PATHS=("${SKIP_AUTO_SWITCH_VERSION_PATHS[@]}")

## Version managers

### Node
NODE_VERSION_MANAGER="fnm"

#### NVM
if [ "$NODE_VERSION_MANAGER" = "nvm" ] && command_exists "nvm"; then
    if command_exists "load-nvmrc"; then
        unset -f load-nvmrc
    fi
    function load-nvmrc() {
        # Skip auto switch version if the current path is in the skip list
        for skip_path in "${SKIP_AUTO_SWITCH_VERSION_PATHS[@]}"; do
            if [[ "$PWD" == "$skip_path"* ]]; then
                return
            fi
        done

        local node_version="$(nvm version)"
        local nvmrc_path="$(nvm_find_nvmrc)"

        if [ -n "$nvmrc_path" ]; then
            local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

            if [ "$nvmrc_node_version" = "N/A" ]; then
                nvm install
            elif [ "$nvmrc_node_version" != "$node_version" ]; then
                nvm use
            fi
        elif [ "$node_version" != "$(nvm version default)" ]; then
            echo "Reverting to nvm default version"
            nvm use default
        fi
    }
    add-zsh-hook chpwd load-nvmrc

    # Load nvm at startup
    load-nvmrc
fi

#### FNM
if [ "$NODE_VERSION_MANAGER" = "fnm" ] && command_exists "fnm"; then
    if command_exists "fnm_auto_switch_version"; then
        unset -f fnm_auto_switch_version
    fi

    # Load fnm without using on-cd hook
    eval "$(fnm env --corepack-enabled --resolve-engines --shell=zsh)"
    function fnm_auto_switch_version() {
        # Skip auto switch version if the current path is in the skip list
        for skip_path in "${SKIP_AUTO_SWITCH_VERSION_PATHS[@]}"; do
            if [[ "$PWD" == "$skip_path"* ]]; then
                return
            fi
        done

        eval "$(fnm env --use-on-cd --corepack-enabled --resolve-engines --shell zsh)"
    }

    add-zsh-hook chpwd fnm_auto_switch_version

    # Load fnm at startup
    fnm_auto_switch_version
fi

## General tools
### Direnv
if command_exists "direnv"; then
    if command_exists "direnv_auto_load"; then
        unset -f direnv_auto_load
    fi

    function direnv_auto_load() {
        for skip_path in "${SKIP_AUTO_LOAD_DIRENV_PATHS[@]}"; do
            if [[ "$PWD" == "$skip_path"* ]]; then
                eval "$(direnv export zsh --unload 2>/dev/null)"
                return
            fi
        done

        eval "$(direnv export zsh)"
    }

    add-zsh-hook chpwd direnv_auto_load
    add-zsh-hook precmd direnv_auto_load

    # Load direnv at startup
    direnv_auto_load
fi

## Cursor

# Kind of Crazy workaround to get Cursor to work with multiple data-profiles
# Example of .cursor-profiles.conf file:
# <PROJECT_ROOT_PATH>=<PROFILE_DIRECTORY_NAME>
# <PROJECT_ROOT_PATH>=<PROFILE_DIRECTORY_NAME>
# ...
# <PROJECT_ROOT_PATH>=<PROFILE_DIRECTORY_NAME>
#
# Usage:
# $ cursor <PROJECT_ROOT_PATH>
#
# Example:
# $ cursor $HOME/Projects/Project-xyzt
# $ cursor .
if command_exists "cursor"; then
    unset -f cursor 2>/dev/null

    function cursor() {
        local profile_dir=""
        local current_dir="$PWD"
        local config_file="$HOME/.config/.cursor-profiles.conf"
        local base_profile_dir="$HOME/.config/.cursor-profiles"

        # Check for local .cursor-profile file
        if [[ -f ".cursor-profile" ]]; then
            local profile_name
            profile_name=$(cat .cursor-profile)
            profile_dir="$base_profile_dir/$profile_name"
        # Check configuration file
        elif [[ -f "$config_file" ]]; then
            local expanded_config
            expanded_config=$(eval "cat <<EOF
$(<"$config_file")
EOF")
            local best_match
            best_match=$(echo "$expanded_config" |
                awk -F'=' -v current="$current_dir" '
            {
                gsub(/^[ \t]+|[ \t]+$/, "", $1)  # trim path
                gsub(/^[ \t]+|[ \t]+$/, "", $2)  # trim profile
                if (current ~ "^" $1) {
                    print length($1), $1 "=" $2
                }
            }' |
                sort -rn |
                head -1 |
                cut -d' ' -f2-)

            if [[ -n "$best_match" ]]; then
                local profile
                profile=$(echo "$best_match" | cut -d'=' -f2)
                profile_dir="$base_profile_dir/$profile"
            fi
        fi

        # Convert arguments to absolute paths
        local args=()
        for arg in "$@"; do
            if [[ "$arg" == "." ]]; then
                args+=("$current_dir")
            elif [[ "$arg" == /* ]]; then
                # Already absolute path
                args+=("$arg")
            elif [[ -e "$arg" ]]; then
                # Convert relative path to absolute
                args+=("$(cd "$(dirname "$arg")" && pwd)/$(basename "$arg")")
            else
                # Not a path, keep as is
                args+=("$arg")
            fi
        done

        # # Launch Cursor
        if [[ -n "$profile_dir" ]]; then
            echo "🎯 Using profile: ${profile_dir##*/} for ${current_dir##*/}"
            echo "Profile directory: $profile_dir"
            # cursor --user-data-dir="$profile_dir" --args "$@"
            open -a Cursor --args --user-data-dir="$profile_dir" "${args[@]}"
        else
            echo "🎯 Using default profile for ${current_dir##*/}"
            open -a Cursor "${args[@]}"
        fi
    }
fi
