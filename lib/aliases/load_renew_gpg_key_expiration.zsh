#!/bin/zsh
echo 'loaded '

renew_gpg_key() {
    # Check if an argument is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <new-expiration-date>"
        echo "Example: $0 2023-12-31"
        # exit 1
    fi

    # New expiration date from the argument
    NEW_EXPIRATION_DATE=$1

    # Function to update the expiration date of a GPG key
    update_key_expiration() {
        local key_id=$1
        local new_date=$2

        echo "Updating the expiration date of the GPG key: $key_id"

        # Start the GPG interactive shell
        gpg --command-fd 0 --edit-key $key_id <<EOF
            # Set expiration for the primary key
            expire
            $new_date
            y
            # Set expiration for each subkey
            key 1
            while true; do
                expire
                $new_date
                y
                key
                # Break if no more subkeys
                n && break
            done
            save
EOF

        if [ $? -eq 0 ]; then
            echo "Expiration date updated successfully."
        else
            echo "Failed to update expiration date."
            # exit 1
        fi
    }

    echo "Please enter the ID of the GPG key you want to update:"
    read KEY_ID

    update_key_expiration $KEY_ID $NEW_EXPIRATION_DATE

    # Optionally, export the updated public key
    # gpg --armor --export $KEY_ID > updated_$KEY_ID.asc

}
