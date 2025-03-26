#!/usr/bin/env bash

# File utils

# Extract files based on the extension
function unpack() {
    # Check if at least one file is provided
    if [ $# -lt 1 ]; then
        echo "Usage: unpack <file> [destination] [specific_files...]"
        echo "Example: unpack file.tar.zst                  # extract all files"
        echo "Example: unpack file.tar.zst destination      # extract all files to destination"
        echo "Example: unpack file.zip . file1.txt file2.txt  # extract only specific files"
        return 1
    fi

    # Check if file exists
    if [ ! -f "$1" ]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    # Get archive file and convert to absolute path
    local archive_file="$1"
    if [[ ! "$archive_file" = /* ]]; then
        archive_file="$(pwd)/$archive_file"
    fi
    shift

    # Set destination directory (use . if not provided)
    local dest="."
    if [ $# -gt 0 ] && [ -n "$1" ]; then
        dest="$1"
        shift
    fi

    # Check for specific files to extract
    local specific_files=()
    if [ $# -gt 0 ]; then
        specific_files=("$@")
    fi

    # Create destination if it doesn't exist
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    # Use 6 threads by default
    export THREADS=6

    # Function to check if we're extracting specific files
    has_specific_files() {
        [ ${#specific_files[@]} -gt 0 ]
    }

    case $archive_file in
    # Plain tar files
    *.tar)
        if has_specific_files; then
            if command_exists tar && tar --version | grep -q 'GNU tar'; then
                tar xvf "$archive_file" --parallel=$THREADS -C "$dest" "${specific_files[@]}"
            else
                tar xvf "$archive_file" -C "$dest" "${specific_files[@]}"
            fi
        else
            if command_exists tar && tar --version | grep -q 'GNU tar'; then
                tar xvf "$archive_file" --parallel=$THREADS -C "$dest"
            else
                tar xvf "$archive_file" -C "$dest"
            fi
        fi
        ;;

    # Gzip-based formats
    *.tgz | *.tar.gz)
        if has_specific_files; then
            if command_exists pigz; then
                tar --use-compress-program="pigz -d -p$THREADS" -xvf "$archive_file" -C "$dest" "${specific_files[@]}"
            else
                tar xvzf "$archive_file" -C "$dest" "${specific_files[@]}"
            fi
        else
            if command_exists pigz; then
                tar --use-compress-program="pigz -d -p$THREADS" -xvf "$archive_file" -C "$dest"
            else
                tar xvzf "$archive_file" -C "$dest"
            fi
        fi
        ;;
    *.gz | *.Z)
        if has_specific_files; then
            echo "Specific file extraction not supported for this format"
            return 1
        else
            if command_exists pigz; then
                pigz -d -p$THREADS -c "$archive_file" >"$dest/$(basename "$archive_file" .gz)"
            else
                gunzip -c "$archive_file" >"$dest/$(basename "$archive_file" .gz)"
            fi
        fi
        ;;

    # Bzip2-based formats
    *.tbz2 | *.tar.bz2)
        if has_specific_files; then
            if command_exists pbzip2; then
                tar --use-compress-program="pbzip2 -d -p$THREADS" -xvf "$archive_file" -C "$dest" "${specific_files[@]}"
            else
                tar xvjf "$archive_file" -C "$dest" "${specific_files[@]}"
            fi
        else
            if command_exists pbzip2; then
                tar --use-compress-program="pbzip2 -d -p$THREADS" -xvf "$archive_file" -C "$dest"
            else
                tar xvjf "$archive_file" -C "$dest"
            fi
        fi
        ;;

    # XZ-based formats
    *.tar.xz | *.txz)
        if has_specific_files; then
            if command_exists xz; then
                XZ_DEFAULTS="-T$THREADS" tar xvJf "$archive_file" -C "$dest" "${specific_files[@]}"
            else
                echo "Please install xz-utils to extract this file"
                return 1
            fi
        else
            if command_exists xz; then
                XZ_DEFAULTS="-T$THREADS" tar xvJf "$archive_file" -C "$dest"
            else
                echo "Please install xz-utils to extract this file"
                return 1
            fi
        fi
        ;;
    *.xz)
        if has_specific_files; then
            echo "Specific file extraction not supported for this format"
            return 1
        else
            if command_exists xz; then
                XZ_DEFAULTS="-T$THREADS" xz -d -c "$archive_file" >"$dest/$(basename "$archive_file" .xz)"
            else
                echo "Please install xz-utils to extract this file"
                return 1
            fi
        fi
        ;;

    # Zstandard formats
    *.tar.zst | *.tzst)
        if has_specific_files; then
            if command_exists zstd; then
                tar --use-compress-program="zstd -d -T$THREADS" -xvf "$archive_file" -C "$dest" "${specific_files[@]}"
            else
                echo "Please install zstd to extract this file"
                return 1
            fi
        else
            if command_exists zstd; then
                tar --use-compress-program="zstd -d -T$THREADS" -xvf "$archive_file" -C "$dest"
            else
                echo "Please install zstd to extract this file"
                return 1
            fi
        fi
        ;;
    *.zst)
        if has_specific_files; then
            echo "Specific file extraction not supported for this format"
            return 1
        else
            if command_exists zstd; then
                zstd -d -T$THREADS -c "$archive_file" >"$dest/$(basename "$archive_file" .zst)"
            else
                echo "Please install zstd to extract this file"
                return 1
            fi
        fi
        ;;

    # 7zip-handled formats
    *.7z | *.zip | *.rar)
        if has_specific_files; then
            if command_exists 7z; then
                # Create a list file with the files to extract
                local list_file=$(mktemp)
                printf "%s\n" "${specific_files[@]}" >"$list_file"

                # Extract only the selected files
                7z x -mmt=$THREADS "$archive_file" "-o$dest" "@$list_file"

                # Remove the list file
                rm -f "$list_file"
            elif [ "${archive_file##*.}" = "zip" ]; then
                # For zip, we need special handling of selected files
                if [[ "$archive_file" == *.zip ]]; then
                    # Extract all files to the temp directory
                    (cd "$dest" && unzip -o "$archive_file")
                    echo "Extracted all files to $dest"

                    # Create a subfolder for selected files
                    local selected_dir="${dest}/selected"
                    mkdir -p "$selected_dir"

                    # Find each selected file and copy it to the selected directory
                    for file in $specific_files; do
                        # Remove the root directory if present
                        local file_path="${file#*/}"

                        # Check if the file exists with its full path
                        if [ -f "${dest}/${file}" ]; then
                            # Copy with directory structure
                            mkdir -p "$(dirname "${selected_dir}/${file}")"
                            cp "${dest}/${file}" "${selected_dir}/${file}"
                            echo "Copied: ${file}"
                        elif [ -f "${dest}/${file_path}" ]; then
                            # Copy without root directory
                            mkdir -p "$(dirname "${selected_dir}/${file_path}")"
                            cp "${dest}/${file_path}" "${selected_dir}/${file_path}"
                            echo "Copied: ${file_path}"
                        else
                            echo "Warning: Could not find ${file} in the archive"
                        fi
                    done

                    # Check if we found any files
                    if [ -z "$(ls -A "$selected_dir")" ]; then
                        echo "No matching files were found in the archive."
                        # Keep all files since extraction failed
                        return
                    fi

                    # Clean up the full extraction safely
                    for item in "$dest"/*; do
                        if [ "$item" != "$selected_dir" ]; then
                            rm -rf "$item"
                        fi
                    done

                    # Move selected files back to dest
                    cp -R "${selected_dir}"/* "$dest" 2>/dev/null || true
                    rm -rf "$selected_dir"

                    echo "Successfully extracted selected files."
                    return
                fi
            elif [ "${archive_file##*.}" = "rar" ] && command_exists unrar; then
                (cd "$dest" && unrar x "$archive_file" "${specific_files[@]}")
            else
                echo "Please install 7zip to extract this file"
                return 1
            fi
        fi
        ;;

    # Cabinet files
    *.exe)
        if has_specific_files; then
            echo "Specific file extraction not supported for this format"
            return 1
        else
            if command_exists cabextract; then
                cabextract -d "$dest" "$archive_file"
            else
                echo "Please install cabextract to extract this file"
                return 1
            fi
        fi
        ;;

    *) echo "'$archive_file': unrecognized file compression" ;;
    esac
}

# Compress files based on desired mode or format
function pack() {
    # Check if correct number of parameters
    if [ $# -lt 2 ]; then
        echo "Usage: pack <source> <destination> [mode]"
        echo "Modes:"
        echo "  high   - Best compression using Zstd"
        echo "  speed  - Fastest compression using Zstd"
        echo "  Or specify destination file format: .tar.zst, .tar.xz, .tar.gz, .zip, .7z"
        echo "High compression mode (uses Zstd with level 19)"
        echo "pack source_file destination high"
        echo "Speed mode (uses Zstd with level 1)"
        echo "pack source_file destination speed"
        echo "Specific format mode"
        echo "pack source_file destination.tar.zst"
        return 1
    fi

    local source="$1"
    local dest="$2"
    local mode="${3:-speed}" # Default to speed mode if not specified
    export THREADS=6

    # Check if source exists
    if [ ! -e "$source" ]; then
        echo "'$source' does not exist"
        return 1
    fi

    # Create destination directory if needed
    local dest_dir=$(dirname "$dest")
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
    fi

    case $mode in
    "high")
        if command_exists zstd; then
            # Using 19 as 80% of max compression level (22)
            if [ -d "$source" ]; then
                tar --use-compress-program="zstd -19 -T$THREADS" -cf "${dest}.tar.zst" "$source"
            else
                zstd -19 -T$THREADS "$source" -o "$dest"
            fi
        else
            echo "Please install zstd for high compression mode"
            return 1
        fi
        ;;
    "speed")
        if command_exists zstd; then
            if [ -d "$source" ]; then
                tar --use-compress-program="zstd -1 -T$THREADS" -cf "${dest}.tar.zst" "$source"
            else
                zstd -1 -T$THREADS "$source" -o "$dest"
            fi
        else
            echo "Please install zstd for speed compression mode"
            return 1
        fi
        ;;
    *.tar.zst | *.tzst)
        if command_exists zstd; then
            tar --use-compress-program="zstd -T$THREADS" -cf "$dest" "$source"
        else
            echo "Please install zstd to create this format"
            return 1
        fi
        ;;
    *.tar.xz | *.txz)
        if command_exists xz; then
            XZ_DEFAULTS="-T$THREADS" tar -cJf "$dest" "$source"
        else
            echo "Please install xz-utils to create this format"
            return 1
        fi
        ;;
    *.tar.gz | *.tgz)
        if command_exists pigz; then
            tar --use-compress-program="pigz -p$THREADS" -cf "$dest" "$source"
        else
            tar -czf "$dest" "$source"
        fi
        ;;
    *.zip)
        if command_exists 7z; then
            7z a -mmt=$THREADS "$dest" "$source"
        else
            if command_exists zip; then
                if [ -d "$source" ]; then
                    zip -r "$dest" "$source"
                else
                    zip "$dest" "$source"
                fi
            else
                echo "Please install 7zip or zip to create this format"
                return 1
            fi
        fi
        ;;
    *.7z)
        if command_exists 7z; then
            7z a -mmt=$THREADS "$dest" "$source"
        else
            echo "Please install 7zip to create this format"
            return 1
        fi
        ;;
    *)
        echo "Unsupported mode or format: $mode"
        echo "Use: high, speed, or specify format (.tar.zst, .tar.xz, .tar.gz, .zip, .7z)"
        return 1
        ;;
    esac
}

# Convert audio files to AAC format
function convert_audio() {
    if [ $# -ne 2 ]; then
        echo "Usage: convert_audio <input_audio_file> <output_format>"
        return 1
    fi

    local input_file="$1"
    local output_format="$2"
    local output_file="${input_file%.*}_converted.${output_format}"
    local codec="aac"
    if [ "$output_format" = "mp3" ]; then
        codec="libmp3lame"
    fi

    ffmpeg -i "$input_file" \
        -c:a "$codec" \
        -b:a 256k \
        -ac 0 \
        -map 0:a \
        "$output_file"

    if [ $? -eq 0 ]; then
        echo "Conversion successful: $output_file"
    else
        echo "Conversion failed."
        return 1
    fi
}

# Convert video files format
function convert_video() {
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Usage output default to mp4: convert_video <input_video_file>"
        echo "Usage: convert_video <input_video_file> <output_format>"
        return 1
    fi

    # Expand tilde in the input path
    local input_file=$(eval echo "$1")

    if [ ! -f "$input_file" ]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    local output_format="mp4"

    if [ $# -eq 2 ]; then
        output_format="$2"
    fi

    local output_file="${input_file%.*}_converted.${output_format}"

    ffmpeg -hwaccel auto -i "$input_file" -c:v libx264 -preset slow -crf 22 -c:a libopus -b:a 256k -map_metadata 0 "$output_file"

    if [ $? -eq 0 ]; then
        echo "Conversion successful: $output_file"
    else
        echo "Conversion failed."
        return 1
    fi
}

# Search within compressed files for specific files or content
function search_archive() {
    if [ $# -lt 1 ]; then
        echo "Usage: search_archive <archive_file> [search_pattern] [extract_dir]"
        echo "Example: search_archive file.tar.gz                 # interactive browsing with fzf"
        echo "Example: search_archive file.zip \"*.txt\"            # search for specific pattern"
        echo "Example: search_archive file.tar.gz \"*.sql\" ./out   # extract matching files to ./out"
        return 1
    fi

    # Check if file exists
    if [ ! -f "$1" ]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    local archive_file="$1"
    local search_pattern="$2"
    local extract_dir="$3"
    export THREADS=6
    local archive_listing=""

    # Function to extract specific files if chosen
    extract_selected() {
        local selected_files="$1"
        local archive="$2"
        local temp_dir

        # Use provided extract dir or create a temp dir
        if [ -n "$extract_dir" ]; then
            # Create the directory if it doesn't exist
            mkdir -p "$extract_dir"
            temp_dir="$extract_dir"
            echo "Extracting selected files to $temp_dir"
        else
            temp_dir=$(mktemp -d)
            echo "Extracting selected files to $temp_dir"
        fi

        # Create a temporary archive with only selected files
        local temp_archive="${temp_dir}/temp_archive.${archive##*.}"

        case "$archive" in
        # For tar-based formats, we can extract specific files directly
        *.tar | *.tgz | *.tar.gz | *.tbz2 | *.tar.bz2 | *.tar.xz | *.txz | *.tar.zst | *.tzst)
            for file in $selected_files; do
                case "$archive" in
                *.tar)
                    tar xf "$archive" -C "$temp_dir" "$file"
                    ;;
                *.tgz | *.tar.gz)
                    tar xzf "$archive" -C "$temp_dir" "$file"
                    ;;
                *.tbz2 | *.tar.bz2)
                    tar xjf "$archive" -C "$temp_dir" "$file"
                    ;;
                *.tar.xz | *.txz)
                    tar xJf "$archive" -C "$temp_dir" "$file"
                    ;;
                *.tar.zst | *.tzst)
                    tar --use-compress-program="zstd -d -T$THREADS" -xf "$archive" -C "$temp_dir" "$file"
                    ;;
                esac
            done
            ;;
        # For non-tar formats, use unpack for the whole archive and then move selected files
        *.7z | *.zip | *.rar)
            # Create a subdirectory for the full extraction
            local full_extract_dir="${temp_dir}/full_extract"
            mkdir -p "$full_extract_dir"

            # Use unpack helper to extract the full archive
            unpack "$archive" "$full_extract_dir"

            # Move only the selected files to temp_dir
            for file in $selected_files; do
                # Make sure parent directories exist
                mkdir -p "$(dirname "${temp_dir}/${file}")"

                # Move selected file if it exists
                if [ -e "${full_extract_dir}/${file}" ]; then
                    mv "${full_extract_dir}/${file}" "${temp_dir}/${file}"
                fi
            done

            # Clean up the full extraction directory
            rm -rf "$full_extract_dir"
            ;;
        *)
            echo "Unsupported archive format for extraction"
            rm -rf "$temp_dir"
            return 1
            ;;
        esac

        echo "Files extracted to: $temp_dir"
        # Only show cleanup warning for temp directories
        if [ -z "$extract_dir" ]; then
            echo "Alert: This directory will not be automatically cleaned up"
        fi
    }

    # Get archive listing based on format
    case "$archive_file" in
    # Tar-based formats
    *.tar)
        archive_listing=$(tar tf "$archive_file")
        ;;
    *.tgz | *.tar.gz)
        archive_listing=$(tar tzf "$archive_file")
        ;;
    *.tbz2 | *.tar.bz2)
        archive_listing=$(tar tjf "$archive_file")
        ;;
    *.tar.xz | *.txz)
        archive_listing=$(tar tJf "$archive_file")
        ;;
    *.tar.zst | *.tzst)
        if command_exists zstd; then
            archive_listing=$(tar --use-compress-program="zstd -d -T$THREADS" -tf "$archive_file")
        else
            echo "Please install zstd to search this file"
            return 1
        fi
        ;;
    # 7zip-handled formats
    *.7z | *.zip | *.rar)
        if command_exists 7z; then
            archive_listing=$(7z l -ba "$archive_file" | awk '{print $6}')
        elif [ "${archive_file##*.}" = "zip" ] && command_exists unzip; then
            # Get total number of lines and calculate how many to keep (total - 6)
            local total_lines=$(unzip -l "$archive_file" | wc -l | tr -d ' ')
            local lines_to_keep=$((total_lines - 6)) # Skip 4 header + 2 footer lines
            archive_listing=$(unzip -l "$archive_file" | tail -n +5 | head -n $lines_to_keep | awk '{$1=$2=$3=""; sub(/^[ \t]+/, ""); print}')
        elif [ "${archive_file##*.}" = "rar" ] && command_exists unrar; then
            archive_listing=$(unrar l -p- "$archive_file" | tail -n +8 | head -n -3 | awk '{$1=$2=$3=$4=$5=""; sub(/^[ \t]+/, ""); print}')
        else
            echo "Please install 7zip to search inside this file"
            return 1
        fi
        ;;
    *)
        echo "'$archive_file': unsupported archive format for searching"
        return 1
        ;;
    esac

    # If no listing could be generated
    if [ -z "$archive_listing" ]; then
        echo "Could not list archive contents"
        return 1
    fi

    # If search pattern provided, filter using grep
    if [ -n "$search_pattern" ]; then
        # Convert common glob patterns to regex
        if [[ "$search_pattern" == *"*"* || "$search_pattern" == *"?"* ]]; then
            # Replace . with \. for regex
            local regex_pattern="${search_pattern//./\\.}"
            # Replace * with .* for regex
            regex_pattern="${regex_pattern//\*/.*}"
            # Replace ? with . for regex
            regex_pattern="${regex_pattern//\?/.}"

            if command_exists rg; then
                archive_listing=$(echo "$archive_listing" | rg "$regex_pattern")
            else
                archive_listing=$(echo "$archive_listing" | grep -E -i "$regex_pattern")
            fi
        else
            # Regular pattern (not glob)
            if command_exists rg; then
                archive_listing=$(echo "$archive_listing" | rg "$search_pattern")
            else
                archive_listing=$(echo "$archive_listing" | grep -i "$search_pattern")
            fi
        fi

        # If no matches found after filtering
        if [ -z "$archive_listing" ]; then
            echo "No matches found for pattern: $search_pattern"
            return 1
        fi

        # Continue to interactive selection with the filtered list
    fi

    # If fzf available, use interactive selection
    if command_exists fzf; then
        local selected_files=$(echo "$archive_listing" | fzf --multi --preview "echo {} | grep --color=always -E '.*'")

        if [ -n "$selected_files" ]; then
            echo "Selected files: "
            echo "$selected_files"

            printf "Do you want to extract these files? (y/n): "
            read extract_choice
            if [[ "$extract_choice" == "y" || "$extract_choice" == "Y" ]]; then
                extract_selected "$selected_files" "$archive_file" "$extract_dir"
            fi
        fi
    else
        # No fzf, just display with less or cat
        if command_exists less; then
            echo "$archive_listing" | less
        else
            echo "$archive_listing"
        fi
    fi
}

alias fdpack="search_archive"
