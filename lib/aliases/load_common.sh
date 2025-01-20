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
