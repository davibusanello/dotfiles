#!/usr/bin/env bash

# Configuration variables for tag-based sync
# TODO: maybe move to .env
# Sync state directory
SYNC_STATE_DIR="${DOTFILES_PATH}/tmp/sync_state"
# Tag pattern
SYNC_REPOS_TAG_PATTERN="${SYNC_REPOS_TAG_PATTERN:-^v?[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9]+)?(\+[a-zA-Z0-9]+)?$}"
# Force push threshold
SYNC_REPOS_FORCE_PUSH_THRESHOLD="${SYNC_REPOS_FORCE_PUSH_THRESHOLD:-1 week ago}"
# Default sync mode
SYNC_REPOS_DEFAULT_MODE="${SYNC_REPOS_DEFAULT_MODE:-tag-first}"
# Tag first enabled
SYNC_REPOS_TAG_FIRST_ENABLED="${SYNC_REPOS_TAG_FIRST_ENABLED:-true}"

# Generate .gitignore file
function gitignore_generate_stack() { curl -sLw n https://www.toptal.com/developers/gitignore/api/"$*"; }

# Diff current file $2 with branch $1
function git_diff_file_vs_branch() { git diff "$1" -- "$2"; }

# Diff current file $2 with branch $1 to HEAD
function git_diff_head_file_vs_branch() { git diff "$1...HEAD" -- "$2"; }

# GitHub Create repository
function github_create_repository_from_current_dir() {
    gh repo create "$(basename "$(pwd)")" --source=. --remote=origin --push "$@"
}

function git_default_branch() {
    git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5
}

# =============================================================================
# Git Clone Helper Functions
# =============================================================================

# Function to handle git clone for URLs with additional parameters
# Usage:
#   @ <repository_url> [options]
#
# Description:
#   A wrapper around git clone that provides smart directory naming for repositories
#   and maintains compatibility with all git clone parameters.
#
# Parameters:
#   $1 - Repository URL (supports HTTPS, HTTP, and SSH formats)
#   $2+ - Additional parameters passed directly to git clone
#
# Behavior:
#   1. Without additional parameters:
#      Creates a directory named {user}_{repository} for GitHub repos
#      Example: @ https://github.com/user/repo.git -> user_repo
#      Example: @ https://github.com/user/repo     -> user_repo
#
#   2. With "." as parameter:
#      Clones into current directory (standard git clone behavior)
#      Example: @ https://github.com/user/repo.git . -> repo
#      Example: @ https://github.com/user/repo .     -> repo
#
#   3. With additional parameters:
#      Passes all parameters to git clone
#      Example: @ https://github.com/user/repo.git custom-dir --depth 1
#      Example: @ https://github.com/user/repo custom-dir --depth 1
#
# Returns:
#   0 - Success
#   1 - Invalid repository URL
function simplified_git_clone() {
    # Remove trailing slash if present and clean up the URL
    local url
    url=$(echo "$1" | sed 's/\/$//')
    # Git CLI app, prefer gix if available
    local git_cmd="git"
    if command_exists gix; then
        git_cmd="gix"
    fi

    # Add .git suffix if not present for HTTPS URLs
    if [[ "$url" =~ ^https?:// ]] && [[ ! "$url" =~ \.git$ ]]; then
        url="${url}.git"
    fi

    # Check if it's a valid git repository URL (including browser URLs)
    if [[ "$url" =~ ^(https://|http://|git@)([A-Za-z0-9.-]+\.[A-Za-z]{2,})(:[0-9]+)?(/|:).+ ]]; then
        local repo_name
        local repo_path
        local repo_user
        repo_name=$(basename "$url" .git)

        # Extract repository user and name
        repo_path=$(echo "$url" | sed 's|^https://[^/]*/||' | sed 's|^http://[^/]*/||' | sed 's|^git@[^:]*:||' | sed 's/.git$//')

        # Check if the repository path contains a user part
        if [[ "$repo_path" =~ ^[^/]+/[^/]+$ ]]; then
            repo_user=$(echo "$repo_path" | cut -d'/' -f1)
            local custom_dir="${repo_user}_${repo_name}"
        else
            local custom_dir="$repo_name"
        fi

        echo "Cloning repository: $url"

        # If no additional parameters or only "." is provided
        if [ $# -eq 1 ]; then
            $git_cmd clone "$url" "$custom_dir"
        elif [ $# -eq 2 ] && [ "$2" = "." ]; then
            $git_cmd clone "$url"
        else
            # Pass all arguments after $1 to git clone
            $git_cmd clone "$url" "${@:2}"
        fi
    else
        echo "Not a valid git repository URL"
        return 1
    fi
}

# Alias for @ symbol to trigger my simplified git clone helper
alias @='simplified_git_clone'

# =============================================================================
# Sync repositories begin

# =============================================================================
# Tag Detection and Semantic Version Handling
# =============================================================================

# Function to detect if repository uses semantic versioning tags
function _has_semantic_tags() {
    local tag_count
    tag_count=$(git tag -l | grep -E "$SYNC_REPOS_TAG_PATTERN" | wc -l)
    [ "$tag_count" -gt 0 ]
}

# Function to get all semantic version tags sorted
function _get_semantic_tags() {
    git tag -l | grep -E "$SYNC_REPOS_TAG_PATTERN" | sort -V
}

# Function to compare semantic versions (returns 0 if v1 > v2, 1 if v1 <= v2)
function _version_gt() {
    local v1="$1" v2="$2"
    # Remove 'v' prefix if present
    v1="${v1#v}" v2="${v2#v}"
    printf '%s\n%s\n' "$v1" "$v2" | sort -V -C && return 1 || return 0
}

# Function to get last synced tag for a repository
function _get_last_synced_tag() {
    local repo_path="$1"
    local root_path="${2:-$(pwd)}"
    local repo_name
    local root_name
    repo_name=$(basename "$repo_path")
    root_name=$(basename "$root_path")
    local state_file="${SYNC_STATE_DIR}/${root_name}_${repo_name}.last_tag"

    [ -f "$state_file" ] && cat "$state_file" || echo ""
}

# Function to save last synced tag for a repository
function _save_last_synced_tag() {
    local repo_path="$1" tag="$2"
    local root_path="${3:-$(pwd)}"
    local repo_name
    local root_name
    repo_name=$(basename "$repo_path")
    root_name=$(basename "$root_path")
    local state_file="${SYNC_STATE_DIR}/${root_name}_${repo_name}.last_tag"

    mkdir -p "$SYNC_STATE_DIR"
    echo "$tag" >"$state_file"
}

# =============================================================================
# Git Repository Maintenance Functions
# =============================================================================

# Function to detect and fix ambiguous refs (40-hex character refs)
# These refs are typically created by mistake and cause warnings during git operations
# Returns: 0 if no issues or successfully fixed, 1 if errors occurred
function _fix_ambiguous_refs() {
    local verbose="${1:-false}"
    local ambiguous_refs

    # Check if there are any 40-hex refs
    ambiguous_refs=$(git for-each-ref --format="%(refname)" 2>/dev/null | grep -E '/[0-9a-f]{40}$' || true)

    if [ -n "$ambiguous_refs" ]; then
        if $verbose; then
            echo "   🔧 Found ambiguous refs (40-hex), cleaning up..."
        fi

        # Delete each ambiguous ref
        if echo "$ambiguous_refs" | xargs -r -n1 git update-ref -d 2>/dev/null; then
            if $verbose; then
                echo "   ✅ Cleaned up ambiguous refs"
            fi
            return 0
        else
            echo "   ⚠️  Failed to clean up some ambiguous refs"
            return 1
        fi
    fi

    return 0
}

# =============================================================================
# Core Tag-Based Sync Logic
# =============================================================================

# Function to sync repository using tags
function _sync_repo_by_tags() {
    local repo_dir="$1" verbose="$2" root_path="$3"
    local has_changes=false
    local current_tag
    local last_synced_tag
    local latest_tag

    # Get current tag and last synced tag
    current_tag=$(git describe --tags --exact-match HEAD 2>/dev/null || echo "")
    last_synced_tag=$(_get_last_synced_tag "$repo_dir" "$root_path")
    latest_tag=$(git tag -l | grep -E "$SYNC_REPOS_TAG_PATTERN" | sort -V | tail -n1)

    if $verbose; then
        echo "   Current tag: ${current_tag:-'none'}"
        echo "   Last synced: ${last_synced_tag:-'none'}"
        echo "   Latest available: ${latest_tag:-'none'}"
    fi

    # Handle first-time sync state initialization
    local is_first_sync=false
    if [ -z "$last_synced_tag" ]; then
        is_first_sync=true
        # Don't set last_synced_tag yet, let the sync logic handle it
    fi

    # Determine if sync is needed
    local needs_sync=false
    local sync_target=""

    if $is_first_sync; then
        # First sync: if we're not on the latest tag, sync to it
        if [ -n "$latest_tag" ] && [ "$current_tag" != "$latest_tag" ]; then
            needs_sync=true
            sync_target="$latest_tag"
        elif [ -n "$latest_tag" ] && [ "$current_tag" = "$latest_tag" ]; then
            # Already on latest tag, just save state
            needs_sync=true
            sync_target="$latest_tag"
        fi
    else
        # Regular sync: check if there are newer tags
        if [ -n "$latest_tag" ] && [ -n "$last_synced_tag" ] && _version_gt "$latest_tag" "$last_synced_tag"; then
            needs_sync=true
            sync_target="$latest_tag"
        fi
    fi

    if $needs_sync; then
        has_changes=true
        if $verbose; then
            if $is_first_sync && [ "$current_tag" = "$sync_target" ]; then
                echo "   📝 Initializing sync state for current tag: $sync_target"
            else
                echo "   📝 Syncing to tag: $sync_target"
            fi
        fi

        # Checkout target tag (or stay if already there)
        if [ "$current_tag" != "$sync_target" ]; then
            if git checkout -q "$sync_target" 2>/dev/null; then
                _save_last_synced_tag "$repo_dir" "$sync_target" "$root_path"
                echo "🏷️  $repo_dir - Synced to tag: $sync_target"
            else
                echo "❌ $repo_dir - Failed to checkout tag: $sync_target"
                return 1
            fi
        else
            # Already on target tag, just save state
            _save_last_synced_tag "$repo_dir" "$sync_target" "$root_path"
            if $is_first_sync; then
                echo "🏷️  $repo_dir - Initialized sync state for tag: $sync_target"
            else
                echo "🏷️  $repo_dir - Synced to tag: $sync_target"
            fi
        fi
    elif $verbose; then
        echo "   ✓ No new tags to sync"
    fi

    echo "$has_changes"
}

# Function to detect force pushes in recent history
function _detect_force_push() {
    # Check if default branch has been force-pushed recently
    if git reflog --since="$SYNC_REPOS_FORCE_PUSH_THRESHOLD" 2>/dev/null | grep -q "forced-update\|reset\|rebase"; then
        return 0
    fi
    return 1
}

# Function to show tag sync status
function _show_tag_sync_status() {
    local repo_dir="${1:-.}"
    local root_path="${2:-$(pwd)}"
    local current_tag
    local last_synced_tag
    local latest_tag

    if [ ! -d "$repo_dir/.git" ]; then
        echo "❌ Not a git repository: $repo_dir"
        return 1
    fi
    cd "$repo_dir" || return 1

    current_tag=$(git describe --tags --exact-match HEAD 2>/dev/null || echo "none")
    last_synced_tag=$(_get_last_synced_tag "$repo_dir" "$root_path")
    latest_tag=$(git tag -l | grep -E "$SYNC_REPOS_TAG_PATTERN" | sort -V | tail -n1)

    echo "📊 Tag Status for $(basename "$repo_dir"):"
    echo "   Current: $current_tag"
    echo "   Last synced: ${last_synced_tag:-'none'}"
    echo "   Latest available: ${latest_tag:-'none'}"

    if _has_semantic_tags; then
        echo "   Uses semantic tags: ✅"
    else
        echo "   Uses semantic tags: ❌"
    fi
}

# Function to reset tag sync state for a repository
function _reset_tag_sync_state() {
    local repo_dir="${1:-.}"
    local root_path="${2:-$(pwd)}"
    local repo_name
    local root_name
    repo_name=$(basename "$repo_dir")
    root_name=$(basename "$root_path")
    local state_file="${SYNC_STATE_DIR}/${root_name}_${repo_name}.last_tag"

    if [ -f "$state_file" ]; then
        rm "$state_file"
        echo "✅ Reset tag sync state for $repo_name (from $root_name)"
    else
        echo "ℹ️  No tag sync state found for $repo_name (from $root_name)"
    fi
}

# Function to migrate from branch-based to tag-based sync
function _migrate_to_tag_sync() {
    local repo_dir="${1:-.}"
    local root_path="${2:-$(pwd)}"
    local latest_tag

    if [ ! -d "$repo_dir/.git" ]; then
        echo "❌ Not a git repository: $repo_dir"
        return 1
    fi

    cd "$repo_dir" || return 1

    if _has_semantic_tags; then
        latest_tag=$(git tag -l | grep -E "$SYNC_REPOS_TAG_PATTERN" | sort -V | tail -n1)
        if [ -n "$latest_tag" ]; then
            _save_last_synced_tag "$repo_dir" "$latest_tag" "$root_path"
            echo "✅ Migrated $(basename "$repo_dir") to tag-based sync (starting from $latest_tag)"
        else
            echo "❌ No semantic tags found in $(basename "$repo_dir")"
        fi
    else
        echo "❌ Repository $(basename "$repo_dir") doesn't use semantic versioning"
    fi
}

# =============================================================================
# Enhanced sync_git_repos Function
# =============================================================================

# Function to sync all git repositories in subdirectories in first level of the current directory
# This function will:
# 1. Check each directory for git repository
# 2. Handle pending changes (stash if needed)
# 3. Sync with remote based on current branch status or tags
# 4. Return to original branch if switched
# TODO: handle multiple remotes (origin, upstream, etc.)
#
# Usage:
#   sync_git_repos [OPTIONS] [REPOSITORY_PATH]
#
# Options:
#   -v, --verbose       Enable verbose output
#   -t, --tags          Force tag-based sync
#   -b, --branches-only Force branch-based sync
#
# Parameters:
#   REPOSITORY_PATH     Optional path to specific repository to sync
#                       If not provided, syncs all repositories in current directory
function sync_git_repos() {
    # Parse arguments
    local verbose=false
    local tag_mode=false
    local force_branch_mode=false
    local target_repo=""
    local args=()

    for arg in "$@"; do
        case "$arg" in
        -v | --verbose)
            verbose=true
            ;;
        -t | --tags)
            tag_mode=true
            ;;
        -b | --branches-only)
            force_branch_mode=true
            ;;
        *)
            if [ -z "$target_repo" ]; then
                target_repo="$arg"
            else
                args+=("$arg")
            fi
            ;;
        esac
    done

    # Store the original directory
    local original_dir
    original_dir=$(pwd)
    local exit_status=0
    local repos_checked=0
    local repos_updated=0
    local repos_failed=0

    if $verbose; then
        echo "🔄 Starting repository sync..."
        if $tag_mode; then
            echo "   Mode: Tag-based sync (forced)"
        elif $force_branch_mode; then
            echo "   Mode: Branch-based sync (forced)"
        else
            echo "   Mode: Auto-detect (default: $SYNC_REPOS_DEFAULT_MODE)"
        fi
        echo ""
    fi

    # Determine directories to process
    local dirs_to_process=()
    if [ -n "$target_repo" ]; then
        # Handle specific repository path
        if [ -d "$target_repo" ]; then
            dirs_to_process=("$target_repo")
            if $verbose; then
                echo "🎯 Targeting specific repository: $target_repo"
            fi
        else
            echo "❌ Repository path not found: $target_repo"
            return 1
        fi
    else
        # Process all directories in current path
        for dir in */; do
            if [ -d "$dir" ]; then
                dirs_to_process+=("$dir")
            fi
        done
    fi

    # Process each directory
    for dir in "${dirs_to_process[@]}"; do
        cd "$dir" || continue

        # Check if it's a git repository
        if git rev-parse --git-dir >/dev/null 2>&1; then
            ((repos_checked++))

            if $verbose; then
                echo "🔍 Checking $dir"
            fi

            # Fix any ambiguous refs (40-hex character refs) before performing operations
            _fix_ambiguous_refs "$verbose"

            # Store original git settings
            local original_autocrlf
            local original_safecrlf
            original_autocrlf=$(git config --get core.autocrlf)
            original_safecrlf=$(git config --get core.safecrlf)
            # Temporarily disable CRLF conversion and warnings
            if [ -n "$original_autocrlf" ]; then
                git config core.autocrlf false
            fi
            if [ -n "$original_safecrlf" ]; then
                git config core.safecrlf false
            fi

            # Get current branch/tag
            local current_ref
            local default_branch
            current_ref=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null || git rev-parse HEAD)
            # Get default branch
            default_branch=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)

            # Check for pending changes
            if ! git diff --quiet || ! git diff --cached --quiet; then
                echo "📦 $dir - Stashing changes"
                if ! git stash push -q -m "Auto-stash by sync_git_repos on $(date)"; then
                    echo "❌ $dir - Failed to stash changes"
                    ((repos_failed++))
                    # Restore git settings and continue
                    if [ -n "$original_autocrlf" ]; then
                        git config core.autocrlf "$original_autocrlf"
                    fi
                    if [ -n "$original_safecrlf" ]; then
                        git config core.safecrlf "$original_safecrlf"
                    fi
                    cd "$original_dir" || exit 1
                    continue
                fi
            fi

            # Fetch all changes from remote
            git fetch --all -q

            # Determine sync strategy (Phase 7: Tag-first behavior)
            local use_tag_sync=false
            if ! $force_branch_mode; then
                if $tag_mode; then
                    # Explicit tag mode
                    if _has_semantic_tags; then
                        use_tag_sync=true
                        if $verbose; then
                            echo "   Using tag-based sync (explicit mode)"
                        fi
                    else
                        if $verbose; then
                            echo "   ⚠️  No semantic tags found, falling back to branch sync"
                        fi
                    fi
                else
                    # Auto-detect based on configuration and repository characteristics
                    if [ "$SYNC_REPOS_DEFAULT_MODE" = "tags" ] && _has_semantic_tags; then
                        use_tag_sync=true
                        if $verbose; then
                            echo "   Using tag-based sync (explicit tags mode)"
                        fi
                    elif [ "$SYNC_REPOS_DEFAULT_MODE" = "tag-first" ] && _has_semantic_tags; then
                        # NEW: Tag-first behavior - always use tags when available
                        use_tag_sync=true
                        if $verbose; then
                            echo "   Using tag-based sync (tag-first mode)"
                        fi
                    elif [ "$SYNC_REPOS_DEFAULT_MODE" = "auto" ] && _has_semantic_tags && _detect_force_push; then
                        # Legacy auto mode: only use tags when force push detected
                        use_tag_sync=true
                        if $verbose; then
                            echo "   🔍 Force push detected, using tag-based sync"
                        fi
                    elif $verbose && _has_semantic_tags && [ "$SYNC_REPOS_DEFAULT_MODE" = "auto" ]; then
                        echo "   Repository has tags but no force push detected, using branch sync (legacy auto mode)"
                    elif $verbose && _has_semantic_tags; then
                        echo "   Repository has tags but using branch sync (mode: $SYNC_REPOS_DEFAULT_MODE)"
                    fi
                fi
            fi

            local has_changes=false

            # Execute appropriate sync strategy
            if $use_tag_sync; then
                local tag_sync_result
                tag_sync_result=$(_sync_repo_by_tags "$(pwd)" "$verbose" "$original_dir")
                if [ "$tag_sync_result" = "true" ]; then
                    has_changes=true
                fi
            else
                # Original branch-based sync logic
                local before_rev=""
                local after_rev=""

                # If we're on the default branch
                if [ "$current_ref" = "$default_branch" ]; then
                    # Store the current HEAD commit before pulling
                    before_rev=$(git rev-parse HEAD)

                    if ! git pull -q origin "$default_branch"; then
                        echo "❌ $dir - Failed to sync $default_branch"
                        ((repos_failed++))
                    else
                        # Store the HEAD commit after pulling
                        after_rev=$(git rev-parse HEAD)

                        # Check if there were any changes
                        if [ "$before_rev" != "$after_rev" ]; then
                            has_changes=true
                            # Show a summary of changes
                            if $verbose; then
                                echo "   📝 Changes pulled from remote:"
                                git --no-pager log --oneline --graph --decorate --abbrev-commit "$before_rev..$after_rev" | head -n 5
                            fi
                        fi
                    fi
                else
                    # Sync current branch/tag
                    local current_before_rev
                    current_before_rev=$(git rev-parse HEAD 2>/dev/null || echo "")

                    if ! git fetch -q origin "$current_ref:$current_ref" 2>/dev/null; then
                        if $verbose; then
                            echo "   ℹ️  Could not sync $current_ref directly"
                        fi
                    else
                        local current_after_rev
                        current_after_rev=$(git rev-parse HEAD 2>/dev/null || echo "")
                        if [ -n "$current_before_rev" ] && [ -n "$current_after_rev" ] && [ "$current_before_rev" != "$current_after_rev" ]; then
                            has_changes=true
                            if $verbose; then
                                echo "   📝 Changes fetched to $current_ref"
                            fi
                        fi
                    fi

                    # Switch to default branch and sync
                    if git checkout -q "$default_branch"; then
                        # Store the current HEAD commit before pulling
                        before_rev=$(git rev-parse HEAD)

                        if ! git pull -q origin "$default_branch"; then
                            echo "❌ $dir - Failed to sync $default_branch"
                            ((repos_failed++))
                        else
                            # Store the HEAD commit after pulling
                            after_rev=$(git rev-parse HEAD)

                            # Check if there were any changes
                            if [ "$before_rev" != "$after_rev" ]; then
                                has_changes=true
                                # Show a summary of changes
                                if $verbose; then
                                    echo "   📝 Changes pulled to $default_branch:"
                                    git --no-pager log --oneline --graph --decorate --abbrev-commit "$before_rev..$after_rev" | head -n 5
                                fi
                            fi
                        fi
                        git checkout -q "$current_ref"
                    else
                        echo "❌ $dir - Failed to switch to $default_branch"
                        ((repos_failed++))
                    fi
                fi
            fi

            if $has_changes; then
                echo "✅ $dir - Synced with remote"
                ((repos_updated++))
            elif $verbose; then
                echo "✓ $dir - Already up to date"
            fi

            # Restore original git settings
            if [ -n "$original_autocrlf" ]; then
                git config core.autocrlf "$original_autocrlf"
            fi
            if [ -n "$original_safecrlf" ]; then
                git config core.safecrlf "$original_safecrlf"
            fi
        fi

        # Return to original directory before processing next
        cd "$original_dir" || exit 1
    done

    # Print summary
    echo "📊 Summary: $repos_checked repositories checked, $repos_updated updated, $repos_failed failed"

    return $exit_status
}

# Sync repositories end
# =============================================================================

# =============================================================================
# Branch Reset Functions
# =============================================================================

# Resets default branch to origin/default_branch
# Parameters:
#   --hard: Use git reset --hard instead of pull (destructive)
#   Additional parameters are passed directly to git pull (if not using --hard)
# Example:
#   reset-default-branch --rebase
#   reset-default-branch --hard
function reset_default_branch() {
    local default_branch
    default_branch=$(git_default_branch)
    local use_hard_reset=false
    local args=()

    # Parse arguments
    for arg in "$@"; do
        if [ "$arg" = "--hard" ]; then
            use_hard_reset=true
        else
            args+=("$arg")
        fi
    done

    if ! git switch -q "$default_branch"; then
        echo "❌ Failed to switch to $default_branch"
        return 1
    fi

    if ! git fetch -q origin "$default_branch"; then
        echo "❌ Failed to fetch $default_branch"
        return 1
    fi

    if $use_hard_reset; then
        if ! git reset --hard "origin/$default_branch"; then
            echo "❌ Failed to hard reset to origin/$default_branch"
            return 1
        fi
    else
        if ! git pull -q origin "$default_branch" "${args[@]}"; then
            echo "❌ Failed to pull $default_branch"
            return 1
        fi
    fi

    echo "✅ Successfully reset $default_branch"
}

# Function to get all changed files in the current branch including staged changes that match an optional given pattern
# Usage: git_current_changed_files_pattern <pattern>
# Example: git_current_changed_files_pattern 'src/.*\.js'
# Example excluding jsx files:
# Example: git_current_changed_files_pattern '.js$'
function git_current_changed_files_pattern() {
    local pattern="$1"
    if [ -z "$pattern" ]; then
        split_lined_list_into_single_line "$(git status --porcelain | cut -c4-)"
    else
        split_lined_list_into_single_line "$(git status --porcelain | cut -c4- | rg "$pattern")"
    fi
}

# Function to get all changed files in the current branch compared to a given branch, excluding deleted or old moved file paths changes
# Usage: git_current_branch_changed_files_vs_branch_pattern <branch> [pattern]
# Example: git_current_branch_changed_files_vs_branch_pattern 'main'
# Example: git_current_branch_changed_files_vs_branch_pattern 'develop' 'src/.*\.js'
# Example excluding jsx files:
# Example: git_current_branch_changed_files_vs_branch_pattern 'main' '.js$'
function git_current_branch_changed_files_vs_branch_pattern() {
    local branch="$1"
    if [ -z "$branch" ]; then
        echo "Usage: git_current_branch_changed_files_vs_branch_pattern <branch> [pattern]"
        return 1
    fi

    local pattern="$2"
    if [ -z "$pattern" ]; then
        split_lined_list_into_single_line "$(git diff --name-only --diff-filter=AMR "$branch")"
    else
        split_lined_list_into_single_line "$(git diff --name-only --diff-filter=AMR "$branch" | rg "$pattern")"
    fi
}

# Function to get all changed files in the current branch compared to the default branch that match a given pattern, excluding deleted or old moved file paths changes
# Pattern is optional, if not provided, all changed files are returned
# Usage: git_current_branch_changed_files_vs_default_branch_pattern <pattern>
# Example: git_current_branch_changed_files_vs_default_branch_pattern 'src/.*\.js'
# Example: git_current_branch_changed_files_vs_default_branch_pattern '.md'
# Exempale excluding jsx files:
# Example: git_current_branch_changed_files_vs_default_branch_pattern '.js$'
function git_current_branch_changed_files_vs_default_branch_pattern() {
    git_current_branch_changed_files_vs_branch_pattern "$(git_default_branch)" "$@"
}

# =============================================================================
# Aliases and Commands
# =============================================================================

# Enhanced aliases for sync operations
# Usage: sync-repos [repository_path]
alias sync-repos='sync_git_repos'
alias sync-repos-v='sync_git_repos -v'
alias sync-repos-tags='sync_git_repos -t -v'
alias sync-repos-branches='sync_git_repos -b -v'

# Utility commands for tag management
alias reset-tag-sync='_reset_tag_sync_state'
alias show-tag-status='_show_tag_sync_status'
alias migrate-to-tags='_migrate_to_tag_sync'

alias reset-default-branch='reset_default_branch'
alias grdbh='reset_default_branch --hard'

alias gi='gitignore_generate_stack'
alias ghrc='github_create_repository_from_current_dir'

# =============================================================================
# Enhanced git diff

# Detailed git diff
alias gidd='git wdiff'
# Diff file vs branch
alias gdfb='git_diff_file_vs_branch'
# Diff head file vs branch
alias gdfbh='git_diff_head_file_vs_branch'
# Diff file vs HEAD
alias gdfh='git diff HEAD --'
# List changed files in current branch
alias gcf='git_current_changed_files_pattern'
alias g_list_changed_files='git_current_changed_files_pattern'
# List changed files in current branch vs default branch
alias gcfdb='git_current_branch_changed_files_vs_default_branch_pattern'
alias g_list_changed_files_vs_default='git_current_branch_changed_files_vs_default_branch_pattern'
# List changed files in current branch vs specific branch
alias gcfb='git_current_branch_changed_files_vs_branch_pattern'
# List changed files in current branch vs specific branch
alias g_list_changed_files_vs_branch='git_current_branch_changed_files_vs_branch_pattern'
