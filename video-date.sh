#!/bin/bash

# Function to print help message
function print_help {
    echo "Usage: video-dates.sh [path to video files] [-dry-run | -apply]"
    echo "Options:"
    echo "-dry-run: Print the changes without modifying the files."
    echo "-apply: Apply the changes to the files."
}

# Check if enough arguments are provided
if [ "$#" -ne 2 ]
then
    print_help
    exit 1
fi

# Path to your folder
dir="$1"

# Dry run or apply changes
mode="$2"

# Array of video file extensions
video_extensions=("mp4" "mov" "avi" "mkv" "flv" "wmv")

# Loop through all video files in the directory
for extension in "${video_extensions[@]}"
do
    find "$dir" -iname "*.$extension" | while read -r file
    do
        # Extract Media Create Date and format it for SetFile
        date=$(exiftool -api QuickTimeUTC=1 -d "%m/%d/%Y %H:%M:%S" -s3 -MediaCreateDate "$file")

        # Depending on the mode, either print the changes or apply them
        if [ "$mode" = "-dry-run" ]
        then
            echo "File: $file"
            echo "New Creation and Modification Date: $date"
            echo ""
        elif [ "$mode" = "-apply" ]
        then
            SetFile -d "$date" -m "$date" "$file"
        else
            echo "Invalid mode. Please choose either -dry-run or -apply."
            print_help
            exit 1
        fi
    done
done
