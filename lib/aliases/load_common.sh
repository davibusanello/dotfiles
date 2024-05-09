#!/usr/bin/env bash
#Common aliases

# Extract files based on the extension
function extract() {
    if [ -f $1 ]; then
        case $1 in
        *.tar.bz2) tar xvjf $1 ;;
        *.tar.gz) tar xvzf $1 ;;
        *.tar.xz) tar xvJf $1 ;;
        *.bz2) bunzip2 $1 ;;
        *.rar) unrar x $1 ;;
        *.gz) gunzip $1 ;;
        *.tar) tar xvf $1 ;;
        *.tbz2) tar xvjf $1 ;;
        *.tgz) tar xvzf $1 ;;
        *.zip) unzip $1 ;;
        *.Z) uncompress $1 ;;
        *.7z) 7z x $1 ;;
        *.xz) unxz $1 ;;
        *.exe) cabextract $1 ;;
        *) echo "\`$1': unrecognized file compression" ;;
        esac
    else
        echo "\`$1' is not a valid file"
    fi
}


# Tree Colorized, all files, follow symbolic links, list 3 levels
alias tree='tree -CalL 3 --dirsfirst'

function gi() { curl -sLw n https://www.toptal.com/developers/gitignore/api/$@ ;}

# Fixes poetry instalation after brew update
function fix_poetry() {
    #
    curl -sSL https://install.python-poetry.org | python3 - --uninstall
    curl -sSL https://install.python-poetry.org | python3
}

# @todo: Still not working
# function meld() {
#     open /Applications/Meld.app $1
# }
