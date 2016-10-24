#!/bin/bash
# HTML5 video converter
# ---------------------------------------------------------------------

SOURCEFOLDER='/Users/kbohnenblust/Downloads/Transmission/completed'
TARGETFOLDER='/Users/kbohnenblust/Downloads/Transmission/stream'


cd "$SOURCEFOLDER"

# Loop all Folders
for dic in *;
# for dic in $(find $SOURCEFOLDER -type d);
do

    cd "$SOURCEFOLDER"

    foldername=$(basename "$dic")
    targetfolder="$TARGETFOLDER/$foldername"

    # Check if fodler exist
    if [ -d "$targetfolder" ]; then
        echo "Folder $targetfolder exist."
    fi
    mkdir "$targetfolder"

    echo "$dic"
    cd "$dic"


    # Loop all Files in Fodler
    for file in *;
    do 
        filetype=$(file -b --mime-type "$file")
        filename=$(basename "$file")

        #Check Filetype
        if [ $filetype = "application/octet-stream" ]; then 
            ffmpeg -i "$file" -vcodec copy -acodec copy "$targetfolder/${filename%.*}.mp4"
        fi

        if [ $filetype = "image/jpeg" ]; then 
            cp "$file" "$targetfolder/poster.jpg"
        fi
        echo " - $filename / $filetype"
    done
done