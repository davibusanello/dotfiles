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
    echo "Loading direnv"
    unset -f direnv_auto_load
    function direnv_auto_load() {
        for skip_path in "${SKIP_AUTO_LOAD_DIRENV_PATHS[@]}"; do
            if [[ "$PWD" == "$skip_path"* ]]; then
                eval "$(direnv export zsh --unload)"
                return
            fi
        done

        eval "$(direnv export zsh)"
    }

    add-zsh-hook chpwd direnv_auto_load

    # Load direnv at startup
    direnv_auto_load
fi
