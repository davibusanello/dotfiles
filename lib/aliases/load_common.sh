#!/usr/bin/env bash

# Common simple functions

# Fixes poetry instalation after brew update
# TODO: review if this is still needed
function fix_poetry() {
    curl -sSL https://install.python-poetry.org | sed 's/symlinks=False/symlinks=True/' | python3 -
}
