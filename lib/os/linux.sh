#!/usr/bin/env bash
if [ -n "$WSL_DISTRO_NAME" ]; then
    source "$(dirname $0)/wsl.sh"
fi

# TODO: It was needed for Tilix when using Linux as main OS
# TODO: Check if this is still needed
#source /etc/profile.d/vte-2.91.sh
if [ "$TILIX_ID" ] || [ "$VTE_VERSION" ]; then
    if [ -f /etc/profile.d/vte.sh ]; then
        # shellcheck source=/dev/null
        source /etc/profile.d/vte.sh
    fi
fi
