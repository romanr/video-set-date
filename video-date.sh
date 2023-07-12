#!/bin/bash

# Function to print help message
function print_help {
    echo "Usage: video-dates.sh [path to video files] [-dry-run | -apply] [-davinci-fix]"
    echo "Options:"
    echo "-dry-run: Print the changes without modifying the files."
    echo "-apply: Apply the changes to the files."
    echo "-davinci-fix: add Davinci Resolve metadata, copy MediaCreateDate to DateTimeOriginal if needed."
}

# Check if enough arguments are provided
if [ "$#" -lt 2 ]
then
    print_help
    exit 1
fi

# Path to your folder
dir="$1"

# Dry run or apply changes
mode="$2"

# Davinci fix
davinci_fix="$3"

# Array of video file extensions
video_extensions=("mp4" "mov" "avi" "mkv" "flv" "wmv")

# Counters for statistics
total_files=0
updated_files=0
fixed_files=0

# Loop through all video files in the directory
for extension in "${video_extensions[@]}"
do
    find "$dir" -iname "*.$extension" | while read -r file
    do
        total_files=$((total_files+1))

        # Extract original creation and modification dates
        original_creation_date=$(stat -f "%SB" -t "%m/%d/%Y %H:%M:%S" "$file")
        original_modification_date=$(stat -f "%Sm" -t "%m/%d/%Y %H:%M:%S" "$file")

        # Extract Media Create Date and format it for SetFile
        new_date=$(exiftool -m -api QuickTimeUTC=1 -d "%m/%d/%Y %H:%M:%S" -s3 -MediaCreateDate "$file")

        # If DateTimeOriginal is empty, and davinci_fix is set, copy MediaCreateDate to DateTimeOriginal
        if [ "$davinci_fix" = "-davinci-fix" ]
        then
            datetime_original=$(exiftool -m -s3 -DateTimeOriginal "$file")
            if [ -z "$datetime_original" ] && [ -n "$new_date" ]
            then
                if [ "$mode" = "-apply" ]
                then
                    exiftool -m '-DateTimeOriginal<CreateDate' "$file"
                    fixed_files=$((fixed_files+1))
                fi
            fi
        fi

        # Depending on the mode, either print the changes or apply them
        if [ "$mode" = "-dry-run" ]
        then
            echo "File: $file"
            echo "Original Creation Date: $original_creation_date"
            echo "Original Modification Date: $original_modification_date"
            echo "New Date: $new_date"
            echo ""
        elif [ "$mode" = "-apply" ]
        then
            if [ "$original_creation_date" != "$new_date" ] && [ "$original_modification_date" != "$new_date" ] && [ -n "$new_date" ]
            then
                SetFile -d "$new_date" -m "$new_date" "$file"
                updated_files=$((updated_files+1))
                echo "Applied new date to file: $file"
                echo "Original Creation Date: $original_creation_date -> New Date: $new_date"
                echo "Original Modification Date: $original_modification_date -> New Date: $new_date"
            fi
        else
            echo "Invalid mode. Please choose either -dry-run or -apply."
            print_help
            exit 1
        fi
    done
done

# Print statistics
echo "Total video files found: $total_files"
echo "Total files with updated date: $updated_files"
echo "Total files with applied DaVinci Resolve metadata fix: $fixed_files"
