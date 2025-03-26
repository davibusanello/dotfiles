#!/usr/bin/env bash

# File utils

# Extract files based on the extension
function unpack() {
    # Check if at least one file is provided
    if [ $# -lt 1 ]; then
        echo "Usage: unpack <file> [destination]"
        echo "Example: unpack file.tar.zst"
        echo "Example: unpack file.tar.zst destination"
        return 1
    fi

    # Check if file exists
    if [ ! -f "$1" ]; then
        echo "'$1' is not a valid file"
        return 1
    fi

    # Set destination directory (use . if not provided)
    local dest="${2:-.}"

    # Create destination if it doesn't exist
    if [ ! -d "$dest" ]; then
        mkdir -p "$dest"
    fi

    # Use 6 threads by default
    export THREADS=6

    case $1 in
    # Plain tar files
    *.tar)
        if command_exists tar && tar --version | grep -q 'GNU tar'; then
            tar xvf "$1" --parallel=$THREADS -C "$dest"
        else
            tar xvf "$1" -C "$dest"
        fi
        ;;

    # Gzip-based formats
    *.tgz | *.tar.gz)
        if command_exists pigz; then
            tar --use-compress-program="pigz -d -p$THREADS" -xvf "$1" -C "$dest"
        else
            tar xvzf "$1" -C "$dest"
        fi
        ;;
    *.gz | *.Z)
        if command_exists pigz; then
            pigz -d -p$THREADS -c "$1" >"$dest/$(basename "$1" .gz)"
        else
            gunzip -c "$1" >"$dest/$(basename "$1" .gz)"
        fi
        ;;

    # Bzip2-based formats
    *.tbz2 | *.tar.bz2)
        if command_exists pbzip2; then
            tar --use-compress-program="pbzip2 -d -p$THREADS" -xvf "$1" -C "$dest"
        else
            tar xvjf "$1" -C "$dest"
        fi
        ;;

    # XZ-based formats
    *.tar.xz | *.txz)
        if command_exists xz; then
            XZ_DEFAULTS="-T$THREADS" tar xvJf "$1" -C "$dest"
        else
            echo "Please install xz-utils to extract this file"
            return 1
        fi
        ;;
    *.xz)
        if command_exists xz; then
            XZ_DEFAULTS="-T$THREADS" xz -d -c "$1" >"$dest/$(basename "$1" .xz)"
        else
            echo "Please install xz-utils to extract this file"
            return 1
        fi
        ;;

    # Zstandard formats
    *.tar.zst | *.tzst)
        if command_exists zstd; then
            tar --use-compress-program="zstd -d -T$THREADS" -xvf "$1" -C "$dest"
        else
            echo "Please install zstd to extract this file"
            return 1
        fi
        ;;
    *.zst)
        if command_exists zstd; then
            zstd -d -T$THREADS -c "$1" >"$dest/$(basename "$1" .zst)"
        else
            echo "Please install zstd to extract this file"
            return 1
        fi
        ;;

    # 7zip-handled formats
    *.7z | *.zip | *.rar)
        if command_exists 7z; then
            7z x -mmt=$THREADS "$1" "-o$dest"
        elif [ "${1##*.}" = "zip" ]; then
            unzip "$1" -d "$dest"
        elif [ "${1##*.}" = "rar" ] && command_exists unrar; then
            unrar x "$1" "$dest"
        else
            echo "Please install 7zip to extract this file"
            return 1
        fi
        ;;

    # Cabinet files
    *.exe)
        if command_exists cabextract; then
            cabextract -d "$dest" "$1"
        else
            echo "Please install cabextract to extract this file"
            return 1
        fi
        ;;

    *) echo "'$1': unrecognized file compression" ;;
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
