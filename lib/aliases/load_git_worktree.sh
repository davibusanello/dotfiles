#!/usr/bin/env bash

# Set a reliable PATH to ensure core utilities are found.
# export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# =============================================================================
# Git Worktree Productivity Enhancement Suite
# =============================================================================
#
# Transform your development workflow with intelligent git worktree automation
# that eliminates context switching friction while maintaining unified repository management.
#
# Features:
# - Zero build time when switching contexts
# - Emergency hotfix capability without disrupting ongoing work
# - Parallel feature development with shared repository benefits
# - Standardized team workflows with consistent naming and automation
# - Enterprise-grade reliability with proper submodule handling
#
# Git Version Compatibility:
# - Git 2.5+: Basic worktree support (minimum requirement)
# - Git 2.15+: Relative paths support (recommended)
# - Git 2.17+: Move command support
# - Git 2.20+: Worktree-specific config support (optimal)
#
# =============================================================================

# =============================================================================
# Configuration Variables
# =============================================================================

# Default configuration variables for worktree behavior
# WORKTREE_DEFAULT_BASE_DIR="~/worktrees/"

# Core behavior
WORKTREE_DEFAULT_BASE_DIR="${WORKTREE_DEFAULT_BASE_DIR:-../worktrees/}"
WORKTREE_AUTO_CD="${WORKTREE_AUTO_CD:-true}"
WORKTREE_CLEANUP_ON_REMOVE="${WORKTREE_CLEANUP_ON_REMOVE:-true}"

# Modern Git features (Git 2.15+)
WORKTREE_USE_RELATIVE_PATHS="${WORKTREE_USE_RELATIVE_PATHS:-true}"
WORKTREE_ENABLE_SPECIFIC_CONFIG="${WORKTREE_ENABLE_SPECIFIC_CONFIG:-false}"

# Enterprise features
WORKTREE_SUBMODULE_SUPPORT="${WORKTREE_SUBMODULE_SUPPORT:-disabled}"
WORKTREE_LOCK_TIMEOUT="${WORKTREE_LOCK_TIMEOUT:-14d}"
WORKTREE_AUTO_INSTALL_DEPS="${WORKTREE_AUTO_INSTALL_DEPS:-false}"
WORKTREE_STRICT_NAMING="${WORKTREE_STRICT_NAMING:-false}"

# =============================================================================
# Utility Functions
# =============================================================================

# Check if we're in a git repository
function _git_worktree_check_repo() {
    if ! git rev-parse --git-dir &>/dev/null; then
        echo "❌ Not in a git repository"
        return 1
    fi
    return 0
}

# Check Git version compatibility
function _git_worktree_check_version() {
    local required_version="$1"

    # Check if git is available
    if ! command -v git &>/dev/null; then
        echo "❌ Git not found in PATH"
        return 1
    fi

    local current_version=$(git --version | grep -oE '[0-9]+\.[0-9]+' | head -1)

    # Simple version comparison
    local current_major=$(echo "$current_version" | cut -d. -f1)
    local current_minor=$(echo "$current_version" | cut -d. -f2)
    local required_major=$(echo "$required_version" | cut -d. -f1)
    local required_minor=$(echo "$required_version" | cut -d. -f2)

    if [[ $current_major -gt $required_major ]] ||
        [[ $current_major -eq $required_major && $current_minor -ge $required_minor ]]; then
        return 0
    else
        return 1
    fi
}

if ! _git_worktree_check_version "2.17"; then
    echo "❌ Git version 2.17 or higher is required"
    return 1
fi

# Validate worktree name
function _git_worktree_validate_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "❌ Worktree name cannot be empty"
        return 1
    fi

    if [[ "$name" =~ [[:space:]] ]]; then
        echo "❌ Spaces not allowed in worktree names"
        return 1
    fi

    return 0
}

# Get worktree path
function _git_worktree_get_path() {
    local name="$1"
    echo "${WORKTREE_DEFAULT_BASE_DIR}${name}"
}

# Check if worktree exists
function _git_worktree_exists() {
    local name="$1"

    git worktree list 2>/dev/null | grep -q "$(_git_worktree_get_path "$name")"
}

# =============================================================================
# Core Worktree Functions
# =============================================================================

# Create worktree with enhanced features
function git_worktree_create() {
    local name="$1"
    local base="${2:-HEAD}"
    local use_existing_branch="${3:-auto}"

    if [[ -z "$name" ]]; then
        echo "❌ Please specify worktree name"
        return 1
    fi

    local worktree_path="${WORKTREE_DEFAULT_BASE_DIR}${name}"
    echo "worktree_path: $worktree_path"

    # Create parent directory if needed
    mkdir -p "$(dirname "$worktree_path")"

    # Create worktree with appropriate options
    local create_cmd=("git" "worktree" "add")

    if [[ "$WORKTREE_USE_RELATIVE_PATHS" == "true" ]]; then
        # Check if git supports relative paths (Git 2.15+)
        if git worktree add --help 2>/dev/null | grep -q "\-\-relative-paths"; then
            create_cmd+=("--relative-paths")
        fi
    fi

    # Determine if we should use existing branch or create new one
    local branch_exists=false
    if git show-ref --verify --quiet "refs/heads/$name"; then
        branch_exists=true
    fi

    local create_success=false

    if [[ "$use_existing_branch" == "true" ]] || [[ "$use_existing_branch" == "auto" && "$branch_exists" == "true" ]]; then
        if [[ "$branch_exists" == "true" ]]; then
            echo "📍 Using existing branch '$name'"
            if "${create_cmd[@]}" "$worktree_path" "$name"; then
                create_success=true
            fi
        else
            echo "❌ Branch '$name' does not exist"
            return 1
        fi
    else
        # Create with new branch name
        echo "🌱 Creating new branch '$name' from '$base'"
        if "${create_cmd[@]}" -b "$name" "$worktree_path" "$base"; then
            create_success=true
        fi
    fi

    if [[ "$create_success" == "true" ]]; then
        echo "✓ Worktree '$name' created at $worktree_path"

        # Setup worktree-specific configuration if enabled
        if [[ "$WORKTREE_ENABLE_SPECIFIC_CONFIG" == "true" ]]; then
            _git_worktree_setup_config "$worktree_path"
        fi

        # Handle submodules if enabled
        if [[ "$WORKTREE_SUBMODULE_SUPPORT" != "disabled" ]]; then
            _git_worktree_setup_submodules "$worktree_path"
        fi

        # Install dependencies if enabled
        if [[ "$WORKTREE_AUTO_INSTALL_DEPS" == "true" ]]; then
            _git_worktree_install_dependencies "$worktree_path"
        fi

        # Auto-change directory if enabled
        if [[ "$WORKTREE_AUTO_CD" == "true" ]]; then
            cd "$worktree_path"
            echo "📁 Changed to worktree directory: $worktree_path"
        fi
    else
        echo "❌ Failed to create worktree '$name'"
        return 1
    fi
}

# Create worktree using an existing branch
function git_worktree_checkout() {
    local branch_name="$1"
    local worktree_name="${2:-$branch_name}"

    if [[ -z "$branch_name" ]]; then
        echo "❌ Please specify branch name"
        return 1
    fi

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "❌ Branch '$branch_name' does not exist"
        echo "Available branches:"
        git branch -a | head -10
        return 1
    fi

    # Use the existing branch creation function with explicit flag
    git_worktree_create "$worktree_name" "$branch_name" "true"
}

# Remove worktree with safety checks
function git_worktree_remove() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "❌ Please specify worktree name to remove"
        return 1
    fi

    local worktree_path="${WORKTREE_DEFAULT_BASE_DIR}${name}"

    # Check if worktree exists
    if ! git worktree list | grep -q "$worktree_path"; then
        echo "❌ Worktree '$name' does not exist"
        return 1
    fi

    # Check for uncommitted changes if directory exists
    if [[ -d "$worktree_path" ]]; then
        (cd "$worktree_path" && if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "⚠ Worktree '$name' has uncommitted changes"
            git status --porcelain
            read -p "Continue with removal? (y/N): " confirm </dev/tty
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo "Removal cancelled"
                return 1
            fi
        fi)
    fi

    # Remove worktree
    if git worktree remove "$worktree_path"; then
        echo "✓ Worktree '$name' removed"

        # Cleanup branch
        if git show-ref --verify --quiet "refs/heads/$name"; then
            read -p "Delete associated branch '$name'? (y/N): " confirm </dev/tty
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                git branch -d "$name" && echo "✓ Branch '$name' deleted"
            fi
        fi
    else
        echo "❌ Failed to remove worktree '$name'"
        echo "Try: git worktree remove --force $worktree_path"
        return 1
    fi
}

# List worktrees with enhanced information
function git_worktree_list() {
    echo "=== Git Worktrees ==="
    git worktree list | while IFS= read -r line; do
        local worktree_path=$(echo "$line" | awk '{print $1}')
        local branch_info=$(echo "$line" | awk '{for(i=2; i<=NF; i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')

        if [[ "$line" =~ \[locked\] ]]; then
            echo "🔒 $worktree_path"
        else
            echo "📁 $worktree_path"
        fi
        echo "   └─ $branch_info"
    done
}

# Switch to worktree
function git_worktree_switch() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "❌ Please specify worktree name"
        return 1
    fi

    local worktree_path="${WORKTREE_DEFAULT_BASE_DIR}${name}"

    # Check if worktree exists
    if ! git worktree list | grep -q "$worktree_path"; then
        echo "❌ Worktree '$name' does not exist"
        echo "Available worktrees:"
        git_worktree_list
        return 1
    fi

    if [[ ! -d "$worktree_path" ]]; then
        echo "❌ Worktree path not accessible: $worktree_path"
        echo "Try running: git worktree repair"
        return 1
    fi

    cd "$worktree_path"
    echo "✓ Switched to worktree: $name"
    echo "📁 Current path: $(pwd)"
}

# Repair worktree links
function git_worktree_repair() {
    echo "🔧 Repairing worktree links..."
    git worktree repair "$@"
    echo "✓ Worktree repair completed"
}

# =============================================================================
# Configuration Management
# =============================================================================

# Enable worktree-specific configuration
function git_worktree_enable_config() {
    git config extensions.worktreeConfig true
    echo "✓ Worktree-specific configuration enabled"
}

# Set worktree-specific configuration
function git_worktree_config() {
    if [[ $1 == "--list" ]]; then
        git config --worktree --list
    else
        git config --worktree "$@"
    fi
}

# Setup worktree configuration
function _git_worktree_setup_config() {
    local worktree_path="$1"

    (cd "$worktree_path" && {
        # Enable worktree-specific config if not already enabled
        if ! git config extensions.worktreeConfig | grep -q true; then
            git config extensions.worktreeConfig true
        fi
    })
}

# =============================================================================
# Submodule Integration
# =============================================================================

# Setup submodules in worktree
function _git_worktree_setup_submodules() {
    local worktree_path="$1"

    if [[ ! -f "$worktree_path/.gitmodules" ]]; then
        return 0
    fi

    echo "📦 Setting up submodules..."
    (cd "$worktree_path" && {
        if [[ "$WORKTREE_SUBMODULE_SUPPORT" == "auto" ]]; then
            # Auto-detect and initialize only if submodules exist
            if git submodule status | grep -q '^-'; then
                echo "Initializing uninitialized submodules..."
                git submodule update --init --recursive
            fi
        elif [[ "$WORKTREE_SUBMODULE_SUPPORT" == "full" ]]; then
            # Always initialize all submodules
            git submodule update --init --recursive
        fi
    })
}

# =============================================================================
# Dependency Management
# =============================================================================

# Install dependencies based on project type
function _git_worktree_install_dependencies() {
    local worktree_path="$1"

    echo "📦 Checking for dependencies to install..."
    (cd "$worktree_path" && {
        # Node.js detection and installation
        if [[ -f package.json ]] && [[ ! -d node_modules ]]; then
            echo "📦 Installing Node.js dependencies..."
            if command -v npm &>/dev/null; then
                npm install
            elif command -v yarn &>/dev/null; then
                yarn install
            fi
        fi

        # Python detection
        if [[ -f requirements.txt ]]; then
            echo "🐍 Installing Python dependencies..."
            if command -v uv &>/dev/null; then
                uv pip install -r requirements.txt
            elif command -v pip &>/dev/null; then
                pip install -r requirements.txt
            fi
        fi

        # Ruby detection
        if [[ -f Gemfile ]] && [[ ! -d vendor/bundle ]]; then
            echo "💎 Installing Ruby dependencies..."
            if command -v bundle &>/dev/null; then
                bundle install --path vendor/bundle
            fi
        fi
    })
}

# =============================================================================
# FZF Integration
# =============================================================================

# Interactive worktree selector using fzf
function git_worktree_fzf_switch() {
    if ! command -v fzf &>/dev/null; then
        echo "⚠ fzf not installed - install for interactive worktree selection"
        return 1
    fi

    local selected_worktree
    selected_worktree=$(git worktree list | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --preview 'echo {} | awk "{print \$1}" | xargs ls -la' \
        --preview-window=right:50% \
        --header="Select worktree to switch to (ESC to cancel)")

    if [[ -n "$selected_worktree" ]]; then
        local target_path=$(echo "$selected_worktree" | awk '{print $1}')
        echo "Switching to: $target_path"
        cd "$target_path"
    fi
}

# Interactive worktree creation with branch selection
function git_worktree_fzf_create() {
    if ! command -v fzf &>/dev/null; then
        echo "⚠ fzf not installed - falling back to manual input"
        read -p "Enter worktree name: " worktree_name
        read -p "Enter base branch (default: HEAD): " base_branch
        git_worktree_create "$worktree_name" "${base_branch:-HEAD}"
        return
    fi

    # Select base branch interactively
    local base_branch
    base_branch=$(git branch -a | sed 's/^[* ] //' | fzf \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="Select base branch: " \
        --preview 'git log --oneline -10 {}' \
        --preview-window=right:50%)

    if [[ -n "$base_branch" ]]; then
        read -p "Enter worktree name: " worktree_name
        if [[ -n "$worktree_name" ]]; then
            git_worktree_create "$worktree_name" "$base_branch"
        fi
    fi
}

# =============================================================================
# Naming Conventions
# =============================================================================

# Show naming patterns
function git_worktree_show_naming_patterns() {
    cat <<'EOF'
=== Git Worktree Naming Conventions ===

## Standard Patterns:
feature-{ticket}-{description}    # feature-PROJ-123-user-authentication
hotfix-{severity}-{issue}         # hotfix-critical-login-bug
release-{version}-{stage}         # release-v2.1.0-rc1
experiment-{type}-{name}          # experiment-perf-async-rendering
refactor-{area}-{goal}           # refactor-auth-modernize-jwt

## Team-based Patterns:
{team}-{type}-{name}             # frontend-feature-responsive-design
{developer}-{type}-{name}        # john-experiment-new-algorithm

EOF
}

# Validate and suggest name improvements
function git_worktree_validate_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "❌ Please provide a worktree name"
        return 1
    fi

    # Check for common naming issues
    if [[ "$name" =~ [[:space:]] ]]; then
        echo "❌ Spaces not allowed in worktree names"
        echo "💡 Suggestion: ${name// /-}"
    fi

    if [[ "$name" =~ [A-Z] ]]; then
        echo "⚠ Consider using lowercase for consistency"
        echo "💡 Suggestion: $(echo "$name" | tr '[:upper:]' '[:lower:]')"
    fi

    # Suggest structured naming if no pattern detected
    if ! [[ "$name" =~ ^(feature|hotfix|release|experiment|refactor)- ]]; then
        echo "💡 Consider prefixing with type: feature-, hotfix-, experiment-, etc."
    fi

    return 0
}

# Interactive naming assistant
function git_worktree_name_assistant() {
    echo "🎯 Worktree Naming Assistant"
    echo "=========================="

    echo "Select worktree type:"
    echo "1) feature - New feature development"
    echo "2) hotfix - Urgent bug fixes"
    echo "3) experiment - Testing/research"
    echo "4) release - Release preparation"
    echo "5) custom - Custom type"

    read -p "Choice (1-5): " type_choice

    case "$type_choice" in
    1) local prefix="feature" ;;
    2) local prefix="hotfix" ;;
    3) local prefix="experiment" ;;
    4) local prefix="release" ;;
    5) read -p "Enter custom prefix: " prefix ;;
    *)
        echo "Invalid choice, using 'feature'"
        local prefix="feature"
        ;;
    esac

    read -p "Description/name: " description

    local suggested_name="${prefix}-${description}"
    echo "💡 Suggested name: $suggested_name"

    read -p "Use this name? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        read -p "Enter custom name: " custom_name
        echo "$custom_name"
    else
        echo "$suggested_name"
    fi
}

# =============================================================================
# Workflow Patterns
# =============================================================================

# Feature workflow
function git_worktree_feature() {
    local name="$1"
    local base="${2:-HEAD}"

    if [[ -z "$name" ]]; then
        read -p "Enter feature name: " name
    fi

    local full_name="feature-${name}"
    git_worktree_create "$full_name" "$base"
}

# Hotfix workflow
function git_worktree_hotfix() {
    local name="$1"
    local base="${2:-main}"

    if [[ -z "$name" ]]; then
        read -p "Enter hotfix name/ticket: " name
    fi

    local full_name="hotfix-${name}"
    git_worktree_create "$full_name" "$base"
}

# Experiment workflow
function git_worktree_experiment() {
    local name="$1"
    local base="${2:-HEAD}"

    if [[ -z "$name" ]]; then
        read -p "Enter experiment name: " name
    fi

    local full_name="experiment-${name}"
    git_worktree_create "$full_name" "$base"
}

# =============================================================================
# Maintenance & Health Checks
# =============================================================================

# Health check
function git_worktree_health_check() {
    echo "=== Git Worktree Health Check ==="

    # Check Git version
    echo "🔍 Git version: $(git --version)"

    # Check for broken links
    local broken_count=0
    git worktree list | while read -r line; do
        local worktree_path=$(echo "$line" | awk '{print $1}')
        if [[ ! -d "$worktree_path" ]]; then
            echo "❌ Broken worktree link: $worktree_path"
            ((broken_count++))
        fi
    done

    if [[ $broken_count -eq 0 ]]; then
        echo "✓ All worktree links valid"
    fi
}

# Cleanup stale worktrees
function git_worktree_cleanup() {
    echo "🧹 Cleaning up stale worktrees..."
    git worktree prune
    echo "✓ Cleanup completed"
}

# Diagnostic function to debug issues
function git_worktree_debug() {
    echo "🔍 Git Worktree Diagnostic Information"
    echo "======================================"
    echo ""
    echo "PATH: $worktree_path"
    echo ""
    echo "Git availability:"
    if command -v git &>/dev/null; then
        echo "✅ git found: $(command -v git)"
        echo "✅ git version: $(git --version)"
    else
        echo "❌ git not found in PATH"
    fi
    echo ""
    echo "Current directory: $(pwd)"
    echo "Git repository check:"
    if git rev-parse --git-dir &>/dev/null; then
        echo "✅ In git repository: $(git rev-parse --show-toplevel)"
    else
        echo "❌ Not in a git repository"
    fi
}

# =============================================================================
# Shell Aliases and Shortcuts
# =============================================================================

# Core operations (following git_ pattern like your load_git.sh)
alias gwtc='git_worktree_create'   # Create worktree (new branch)
alias gwtco='git_worktree_checkout' # Create worktree (existing branch)
alias gwtr='git_worktree_remove'   # Remove worktree
alias gwtl='git_worktree_list'     # List worktrees
alias gwts='git_worktree_switch'   # Switch to worktree

# Workflow patterns
alias gwtf='git_worktree_feature'    # Feature workflow
alias gwth='git_worktree_hotfix'     # Hotfix workflow
alias gwte='git_worktree_experiment' # Experimental workflow

# Maintenance (following kebab-case pattern like your other aliases)
alias git-worktree-repair='git_worktree_repair'       # Repair corrupted worktree links
alias git-worktree-cleanup='git_worktree_cleanup'     # Comprehensive cleanup
alias git-worktree-health='git_worktree_health_check' # Health check
alias git-worktree-debug='git_worktree_debug'         # Debug function

# FZF integration (if available)
alias gwtfzf='git_worktree_fzf_switch'  # Interactive worktree switching
alias gwtfzfc='git_worktree_fzf_create' # Interactive worktree creation

# Naming and validation
alias git-worktree-name='git_worktree_name_assistant'           # Interactive naming assistant
alias git-worktree-patterns='git_worktree_show_naming_patterns' # Show naming patterns
alias git-worktree-validate='git_worktree_validate_name'        # Validate name

# Advanced features
alias git-worktree-config='git_worktree_config' # Worktree-specific config

# =============================================================================
# Help Function
# =============================================================================

git_worktree_help() {
    cat <<'EOF'
🚀 Git Worktree Productivity Suite

Quick Start:
  gwtc <name> [base]     # Create worktree with new branch
  gwtco <branch> [name]  # Create worktree from existing branch
  gwts <name>            # Switch to worktree
  gwtl                   # List all worktrees
  gwtr <name>            # Remove worktree

Workflows:
  gwtf <name>            # Create feature worktree
  gwth <name>            # Create hotfix worktree
  gwte <name>            # Create experiment worktree

Interactive (requires fzf):
  gwtfzf                 # Interactive switching
  gwtfzfc                # Interactive creation
  git-worktree-name      # Naming assistant

Maintenance:
  git-worktree-health    # Health check
  git-worktree-cleanup   # Cleanup stale worktrees
  git-worktree-repair    # Repair broken links
  git-worktree-debug     # Debug PATH and environment issues

For naming patterns: git-worktree-patterns
EOF
}

# Auto-enable worktree-specific configuration if supported and enabled
if [[ "$WORKTREE_ENABLE_SPECIFIC_CONFIG" == "true" ]] && [[ -d .git ]]; then
    if ! git config extensions.worktreeConfig | grep -q true 2>/dev/null; then
        git config extensions.worktreeConfig true 2>/dev/null || true
    fi
fi
