#!/usr/bin/env bash
# Load OS specific shell scripts and shell settings

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=linux;;
    Darwin*)    machine=mac;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)    machine=windows;;
    *)          machine="UNKNOWN:${unameOut}"
esac

echo "Loading $machine OS specific scripts..."
source "$(dirname $0)/os/$machine.sh"
