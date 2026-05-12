#!/bin/bash

# Get the folder path from the first argument
TARGET_DIR="./downloads"

# Check if a directory was provided
if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 /path/to/folder"
    exit 1
fi

# Loop through all MP4 files in the target folder
for file in "$TARGET_DIR"/*.mp4; do
    # Skip if no MP4 files are found
    [ -e "$file" ] || continue

    size=$(stat -c%s "$file")
    limit=$((50 * 1024 * 1024))

    if [ "$size" -gt "$limit" ]; then
        echo "Splitting '$file'..."
        # ffmpeg splits and keeps parts in the same folder as the source
        SIZELIMIT="49000000"
        DURATION=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of default=noprint_wrappers=1:nokey=1|cut -d. -f1)
        CUR_DURATION=0
        BASENAME="${file%.*}"
        EXTENSION="mp4"
        i=1
        NEXTFILENAME="$BASENAME-$i.$EXTENSION"
        echo "Duration of source video: $DURATION"
        while [[ $CUR_DURATION -lt $DURATION ]]; do
            echo ffmpeg -i "$file" -ss "$CUR_DURATION" -fs "$SIZELIMIT" -c copy "$NEXTFILENAME"
            ffmpeg -ss "$CUR_DURATION" -i "$file" -hide_banner -loglevel error -fs "$SIZELIMIT" -c copy "$NEXTFILENAME"
            NEW_DURATION=$(ffprobe -i "$NEXTFILENAME" -show_entries format=duration -v quiet -of default=noprint_wrappers=1:nokey=1|cut -d. -f1)
            CUR_DURATION=$((CUR_DURATION + NEW_DURATION))
            i=$((i + 1))
            echo "Duration of $NEXTFILENAME: $NEW_DURATION"
            echo "Part No. $i starts at $CUR_DURATION"
            NEXTFILENAME="$BASENAME-$i.$EXTENSION"
        done
        rm "$file" && echo "Successfully split and deleted: $(basename "$file")"
    else
        echo "Skipping '$(basename "$file")' (under 100MB)"
    fi
done
