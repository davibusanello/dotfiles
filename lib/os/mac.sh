#!/usr/bin/env bash

# Set script verbosity level
# 0 -> Nothing
# 1 -> Basic info
# 2 -> Detailed info
DOTFILES_SCRIPT_LOG_LEVEL=${DOTFILES_SCRIPT_LOG_LEVEL:-1}

# Set forbidden formulae
export HOMEBREW_FORBIDDEN_FORMULAE="mysql mysql@8.0 postgresql@15 postgresql"

# Libs brew
# Architecture detection function
detect_system_architecture() {
    local arch
    if command -v uname >/dev/null 2>&1; then
        arch=$(uname -m)
    else
        # Fallback: assume x86_64 if uname not available
        arch="x86_64"
        echo "Warning: uname command not available, assuming x86_64 architecture" >&2
    fi
    echo "$arch"
}

# Get Homebrew path candidates based on architecture

# Find valid Homebrew path by checking for bin/brew executable
find_valid_homebrew_path() {
    local candidates=("$@")
    local path

    log_detail "Validating Homebrew paths..." >&2

    for path in "${candidates[@]}"; do
        log_detail "  Checking: $path" >&2

        # Check if directory exists
        if [[ ! -d "$path" ]]; then
            log_detail "    Directory does not exist" >&2
            continue
        fi

        # Check if bin directory exists
        if [[ ! -d "$path/bin" ]]; then
            log_detail "    bin/ directory does not exist" >&2
            continue
        fi

        # Check if brew executable exists and is executable
        if [[ -x "$path/bin/brew" ]]; then
            log_detail "    Valid Homebrew installation found" >&2
            echo "$path"
            return 0
        else
            log_detail "    brew executable not found or not executable" >&2
        fi
    done

    log_detail "  No valid Homebrew installation found" >&2
    # No valid path found
    echo ""
    return 1
}

# Setup Homebrew PATH and environment variables
setup_homebrew_path() {
    local homebrew_base="$1"

    if [[ -n "$homebrew_base" ]]; then
        log_detail "Setting up Homebrew environment..."

        # Export Homebrew environment variables
        export BREW_BASE="$homebrew_base"
        export BREW_OPT_PATH="$homebrew_base/opt"
        export BREW_SHARE_PATH="$homebrew_base/share"

        log_detail "  BREW_BASE: $BREW_BASE"
        log_detail "  BREW_OPT_PATH: $BREW_OPT_PATH"
        log_detail "  BREW_SHARE_PATH: $BREW_SHARE_PATH"

        # Add Homebrew paths to PATH (prepend to ensure priority)
        export PATH="$BREW_OPT_PATH/bin:$homebrew_base/bin:$homebrew_base/sbin:$PATH"

        log_detail "  Added to PATH: $BREW_OPT_PATH/bin:$homebrew_base/bin:$homebrew_base/sbin"
        log_info "Homebrew paths configured successfully"
        return 0
    else
        echo "Error: No valid Homebrew path provided to setup function" >&2
        return 1
    fi
}

# Verify brew command works after PATH setup
verify_brew_command() {
    log_detail "Verifying brew command functionality..."

    # Check if brew command exists in PATH
    if ! command -v brew >/dev/null 2>&1; then
        log_detail "  Error: brew command not found in PATH"
        return 1
    fi

    local brew_path
    brew_path=$(command -v brew)
    log_detail "  Found brew at: $brew_path"

    # Test brew command with timeout to avoid hanging
    if timeout 10s brew --version >/dev/null 2>&1; then
        local brew_version
        if command -v head >/dev/null 2>&1; then
            brew_version=$(brew --version 2>/dev/null | head -n1)
        else
            brew_version=$(brew --version 2>/dev/null | sed -n '1p')
        fi
        log_detail "  Brew command verified successfully: $brew_version"
        return 0
    else
        log_detail "  Error: brew command found but not working properly (timeout or error)"
        return 1
    fi
}

# Main Homebrew detection and setup
log_detail "Starting Homebrew detection..."

# Detect system architecture
SYSTEM_ARCH=$(detect_system_architecture)
log_detail "Detected architecture: $SYSTEM_ARCH"

# Get path candidates based on architecture
if [[ "$SYSTEM_ARCH" == "arm64" ]]; then
    HOMEBREW_CANDIDATES=("/opt/homebrew" "/usr/local")
else
    HOMEBREW_CANDIDATES=("/usr/local" "/opt/homebrew")
fi
log_detail "Checking Homebrew candidates: ${HOMEBREW_CANDIDATES[*]}"

# Find valid Homebrew installation
DETECTED_HOMEBREW_PATH=$(find_valid_homebrew_path "${HOMEBREW_CANDIDATES[@]}")

if [[ -n "$DETECTED_HOMEBREW_PATH" ]]; then
    log_detail "Found Homebrew at: $DETECTED_HOMEBREW_PATH"
    setup_homebrew_path "$DETECTED_HOMEBREW_PATH"

    # Verify brew command works
    if verify_brew_command; then
        BREW_AVAILABLE=true
        log_detail "Homebrew is fully functional"
    else
        BREW_AVAILABLE=false
        log_info "Homebrew directory found but command not working"
    fi
else
    log_info "No Homebrew installation found at standard locations"
    log_detail "Using fallback configuration for architecture: $SYSTEM_ARCH"

    # Use architecture-based fallback
    if [[ "$SYSTEM_ARCH" == "arm64" ]]; then
        FALLBACK_PATH="/opt/homebrew"
    else
        FALLBACK_PATH="/usr/local"
    fi

    setup_homebrew_path "$FALLBACK_PATH"
    BREW_AVAILABLE=false
    log_detail "Using fallback path: $FALLBACK_PATH (brew command may not work)"
fi

# Summary of Homebrew detection results
log_detail "=== Homebrew Detection Summary ==="
log_detail "Architecture: $SYSTEM_ARCH"
log_detail "Base Path: $BREW_BASE"
log_detail "Opt Path: $BREW_OPT_PATH"
log_detail "Share Path: $BREW_SHARE_PATH"
log_detail "Command Available: $BREW_AVAILABLE"
log_detail "=================================="

# Additional Homebrew-based tools setup
log_detail "Configuring additional Homebrew-based tools..."

# Function to create g-prefixed symlinks for uutils-coreutils
# It makes the shell compilant with building tools that are dependent on coreutils package with `g-prefixed` tools
# Usage:
#   create_g_links        (Skips creating links that already exist)
#   create_g_links -f     (Overwrites any existing conflicting files/links)
# shellcheck disable=SC2120
create_g_links() {
    local source_dir="$BREW_OPT_PATH/uutils-coreutils/libexec/uubin"
    local target_dir="$BREW_BASE/bin"

    local ln_opts="-s"
    if [[ "$1" == "-f" || "$1" == "--force" ]]; then
        echo "Force flag detected. Will overwrite existing links."
        ln_opts="-sf" # -s for symbolic, -f for force/overwrite
    fi

    log_detail "Scanning for utilities in $source_dir..."

    # shellcheck disable=SC2045
    for util in $(ls "$source_dir"); do
        local source_file="$source_dir/$util"
        local target_link="$target_dir/g$util"

        # Check if a file with the g-prefix already exists
        if [ -e "$target_link" ] && [[ "$ln_opts" != "-sf" ]]; then
            log_detail "Skipping: '$target_link' already exists. Use -f to overwrite."
        else
            log_detail "Creating link: $target_link -> $source_file"
            ln $ln_opts "$source_file" "$target_link"
        fi
    done

    log_detail "Done creating symlinks."
}

# Function to clean up the g-prefixed symlinks created
# Usage:
#   remove_g_links        (Prompts for confirmation if rm is aliased to rm -i)
#   remove_g_links -f     (Removes links without confirmation)
remove_g_links() {
    local source_dir="$BREW_OPT_PATH/uutils-coreutils/libexec/uubin"
    local target_dir="$BREW_BASE/bin"

    local force_remove=false
    if [[ "$1" == "-f" || "$1" == "--force" ]]; then
        echo "Force flag detected. Bypassing confirmation."
        force_remove=true
    fi

    log_detail "Scanning for symlinks to remove from $target_dir..."

    # shellcheck disable=SC2045
    for util in $(ls "$source_dir"); do
        local source_file="$source_dir/$util"
        local target_link="$target_dir/g$util"

        # Check if the target is a symbolic link pointing to our source file
        if [ -L "$target_link" ] && [ "$(readlink "$target_link")" = "$source_file" ]; then
            log_info "Removing link: $target_link"
            if [ "$force_remove" = true ]; then
                # Use 'command' to execute the real rm, bypassing any aliases like 'rm -i'
                command rm -f "$target_link"
            else
                # Use the regular 'rm', which will trigger the confirmation alias
                rm "$target_link"
            fi
        elif [ -L "$target_link" ]; then
            # This addresses the case where a g-prefixed link exists but points somewhere else
            log_info "Skipping: '$target_link' is a symlink but does not point to the expected uutils binary."
        fi
    done

    log_info "Done cleaning up symlinks."
}

ADDITIONAL_PATHS=()

# Additional libraries

# Rust coreutils implementation - only add if it exists
if [ -d "$BREW_OPT_PATH/uutils-coreutils/libexec/uubin" ]; then
    ADDITIONAL_PATHS+=("$BREW_OPT_PATH/uutils-coreutils/libexec/uubin")
    # UUTILS_COREUTILS_PATH="$BREW_OPT_PATH/uutils-coreutils/libexec/uubin"
    # export PATH="$UUTILS_COREUTILS_PATH:$PATH"
    # echo "Current path: $PATH"
    create_g_links
fi

# OpenSSL
OPENSSL_PREFIX="$BREW_OPT_PATH/openssl@3"
# Fallback to openssl@1.1 if openssl@3 doesn't exist
if [ ! -d "$OPENSSL_PREFIX" ]; then
    OPENSSL_PREFIX="$BREW_OPT_PATH/openssl@1.1"
fi
# Fallback to plain openssl if versioned ones don't exist
if [ ! -d "$OPENSSL_PREFIX" ]; then
    OPENSSL_PREFIX="$BREW_OPT_PATH/openssl"
fi

ADDITIONAL_PATHS+=("$OPENSSL_PREFIX/bin")

# PKG configs and compiling flags for PostgreSQL which is my go on DB to use
if [ -d "$BREW_OPT_PATH/libpq" ]; then
    export LDFLAGS="-L$BREW_OPT_PATH/libpq/lib"
    export CPPFLAGS="-I$BREW_OPT_PATH/libpq/include"
    export PKG_CONFIG_PATH="$BREW_OPT_PATH/libpq/lib/pkgconfig"
    # libpq PATh
    # LIBPQ_PATH="$BREW_OPT_PATH/libpq/bin"
    ADDITIONAL_PATHS+=("$BREW_OPT_PATH/libpq/bin")
fi

# MySQL Client - only add to PATH if it exists
if [ -d "$BREW_OPT_PATH/mysql-client/bin" ]; then
    ADDITIONAL_PATHS+=("$BREW_OPT_PATH/mysql-client/bin")
    # MYSQL_CLIENT_PATH="$BREW_OPT_PATH/mysql-client/bin"

    # Preferable to use .envrc per project on demand
    # export LDFLAGS="-L$BREW_OPT_PATH/mysql-client/lib"
    # export CPPFLAGS="-I$BREW_OPT_PATH/mysql-client/include"
    # export PKG_CONFIG_PATH="$BREW_OPT_PATH/mysql-client/lib/pkgconfig"
fi

# Ruby configs
if [ -d "$OPENSSL_PREFIX" ]; then
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$OPENSSL_PREFIX --enable-yjit"
else
    export RUBY_CONFIGURE_OPTS="--enable-yjit"
fi
export RUBY_YJIT_ENABLE=1
# MySQL Client bin and libraries (redundant - already handled above)
# MySQL Client compiled libraries

# Enhance PATH with additional Homebrew tools
function add_additional_homebrew_paths() {
    local new_paths=""
    log_detail "Adding additional Homebrew tool paths..."

    for homebrew_path in "${ADDITIONAL_PATHS[@]}"; do
        if [ -d "$homebrew_path" ]; then
            # Remove the path from PATH if it already exists to avoid duplicates
            PATH=$(echo "$PATH" | sed -e "s|:$homebrew_path:|:|g" -e "s|^$homebrew_path:||" -e "s|:$homebrew_path$||" -e "s|^$homebrew_path$||")
            new_paths="$new_paths:$homebrew_path"
            log_detail "  Added: $homebrew_path"
        fi
    done

    new_paths="${new_paths#:}" # Remove leading colon if present

    if [ -n "$new_paths" ]; then
        # Prepend new paths to ensure they take precedence over system paths
        export PATH="$new_paths:$PATH"
        log_info "Additional Homebrew paths configured with priority"

        # Validate that basic system commands are still accessible
        if ! command -v find >/dev/null 2>&1; then
            echo "WARNING: Basic system commands may not be accessible after PATH update"
        fi
    else
        log_detail "No additional paths to add"
    fi
}

add_additional_homebrew_paths

# End libs brew

# NVM
load-nvm-path() {
    export NVM_DIR="$HOME/.nvm"
    # Only load nvm if the directory and files exist
    if [ -d "$NVM_DIR" ]; then
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
        # shellcheck disable=SC1091
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
}

load-nvm-path

# How to identify architecture
# Apple Intel x86_64
# Apple Silicon arm64
# if [[ $(uname -m) == 'arm64' ]]; then
# fi

# Load Bun (idempotent)
load_bun_path() {
    command -v bun >/dev/null 2>&1 || [[ -d "$HOME/.bun" ]] || return
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"

    local bun_pm_bin
    bun_pm_bin="$(bun pm bin -g 2>/dev/null || true)"

    prepend_paths_if_exist \
        "$bun_pm_bin" \
        "$BUN_INSTALL/bin" \
        "$HOME/node_modules/.bin" \
        "$BUN_INSTALL/install/global/bin"
}

load_bun_path
