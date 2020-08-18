#!/usr/bin/env bash
function git_sync_forked_repository() {
    # trap 'echo ERROR: Operation failed; return' ERR
    main_branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
    echo "Syncing forked repository on branch: $main_branch.."
    echo "Press [y] to continue..."
    read  continue_sync
    if [[ $continue_sync == "Y" || $continue_sync == "y" ]]; then
        echo "Syncing forked repository..."
        git checkout $main_branch
        git fetch upstream
        git merge "upstream\\$main_branch"
        echo "Syncked"
    else
        echo "Syncing aborted!"
    fi
}

git_sync_forked_repository
