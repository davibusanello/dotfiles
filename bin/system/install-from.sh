#!/usr/bin/env bash
# Install packages from file with a list
yay -S < $(cut -d ' ' -f 1 "$1")
