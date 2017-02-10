#!/bin/bash
# HTML5 video converter
# ---------------------------------------------------------------------

SOURCEFOLDER='/media/data/stream/transmission/completed'
TARGETFOLDER='/media/data/stream/movies'



cd $SOURCEFOLDER

# Loop all Folders
for dic in $SOURCEFOLDER/*
do
    foldername=$(basename $dic)
    targetfolder="$TARGETFOLDER/$foldername"


    # Check if fodler exist
    if [ -d "$targetfolder" ]; then
        echo "Folder [$targetfolder] exist."
        break
    fi
    mkdir $targetfolder
    echo $targetfolder

    # Loop all Files in Fodler
    for file in $dic/*
    do 
        filetype=$(file -b --mime-type $file)
        filename=$(basename $file)

        # Check Filetype
        if [ $filetype = 'application/octet-stream' ]; then 
            ffmpeg -i "$file" -vcodec copy -acodec copy "$targetfolder/${filename%.*}.mp4"
        fi

        if [ $filetype = 'image/jpeg' ]; then 
            cp "$file" "$targetfolder/poster.jpg"
        fi
        echo " - $filename / $filetype"
    done
done
