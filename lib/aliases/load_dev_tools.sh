#!/usr/bin/env bash

# Load developer tools

SKIP_AUTO_SWITCH_VERSION_PATHS=(
    "$HOME/Projects/project-examples"
    "$HOME/Projects/docs"
)

## Version managers

NODE_VERSION_MANAGER="fnm"

## NVM
if [ "$NODE_VERSION_MANAGER" = "nvm" ] && command_exists "nvm"; then
    load-nvmrc() {
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
    load-nvmrc
fi

## FNM
if [ "$NODE_VERSION_MANAGER" = "fnm" ] && command_exists "fnm"; then
    # Load fnm without using on-cd hook
    eval "$(fnm env --corepack-enabled --resolve-engines --shell=zsh)"

    fnm_auto_switch_version() {
        # Skip auto switch version if the current path is in the skip list
        for skip_path in "${SKIP_AUTO_SWITCH_VERSION_PATHS[@]}"; do
            if [[ "$PWD" == "$skip_path"* ]]; then
                return
            fi
        done

        eval "$(fnm env --use-on-cd --corepack-enabled --resolve-engines --shell zsh)"
    }

    add-zsh-hook chpwd fnm_auto_switch_version

    # fnm_auto_switch_version
fi
