set -e
# Do not change variables below there
CURRENT_USER=$(who | awk '{print $1}')
# Colors
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'
LIGHT_BLUE='\e[94m'
NC='\e[39m'

# Verify and make an array of partitions to add to fstab
function addPartitionToFstab() {
    local PARTITION_NAME=$1
    local PARTITION_LABEL=$2
    local MOUNT_PATH="$PARTITION_MOUNT_PATH/$CURRENT_USER/$PARTITION_LABEL"
    local FSTAB_LINE=''

    local PARTITION_UUID="$(lsblk -no UUID $PARTITION_NAME)"
    if grep -q "$PARTITION_UUID" "$FSTAB_PATH"; then
        echo -e "${RED}Partition $PARTITION_NAME with UUID $PARTITION_UUID already is in the fstab"
        return
    elif grep -q "$MOUNT_PATH" "$FSTAB_PATH"; then
        echo -e "${RED}Label $PARTITION_LABEL already is in the fstab"
        return
    fi
    # Define that have changes to do
    HAS_CHANGES='1'
    # Mount line do add to the fstab
    FSTAB_LINE="UUID=$(lsblk -no UUID $PARTITION_NAME) $MOUNT_PATH"
    FSTAB_LINE="$FSTAB_LINE $(lsblk -no FSTYPE $PARTITION_NAME) defaults,noatime 0 2"
    NEW_DIRECTORIES+=("$MOUNT_PATH")
    NEW_FSTAB_LINES+=("$FSTAB_LINE")
}

# Confirm & apply the changes to the fstab
function executeFstabChanges() {
    if [ "$HAS_CHANGES" == '1' ];
    then
        echo -e "${YELLOW}fstab has changed, the new fstab will be displayed below:"
        echo -e "${NC}"
        cat $FSTAB_PATH
        echo -e "${YELLOW}#Added are below"
        
        for new_line in "${NEW_FSTAB_LINES[@]}"; do
            echo -e "${NC}$new_line"
        done

        read -r -p "Are you sure? [y/N] " response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
        then
            cp -f $FSTAB_PATH $(dirname "$0")/fstab.orig
            echo -e "${GREEN}Backup of fstab done!${NC}"

            for new_directory in "${NEW_DIRECTORIES[@]}"; do
                mkdir -p "$new_directory"
            done
            chown -R "$CURRENT_USER". "/run/media/$CURRENT_USER"

            for new_line in "${NEW_FSTAB_LINES[@]}"; do
                echo "$new_line" >> "$FSTAB_PATH"
            done
            mount -a
            exit 0
        fi
    fi
    echo -e "${LIGHT_BLUE}Nothing was changed in the fstab!"
}
