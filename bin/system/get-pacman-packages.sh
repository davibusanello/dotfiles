#!/usr/bin/env bash
# paclist - creates list of all installed packages
# reinstall with pacman -S $(cat pkglist)


pacman -Qqet | grep -v "$(pacman -Qqg base)" | grep -v "$(pacman -Qqm)" > "$DOTFILES_PATH/$(uname -n).pacman_packages.txt"

# A list of local packages (includes AUR and locally installed)
pacman -Qm > "$DOTFILES_PATH/$(uname -n).pacman_packages_aur.txt"