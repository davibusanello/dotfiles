[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profile

if command -v nvim >/dev/null 2>&1; then
    export EDITOR=nvim
    export VISUAL=nvim
fi
