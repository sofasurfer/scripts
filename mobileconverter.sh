#!/bin/bash
# HTML5 video converter
# ---------------------------------------------------------------------

function makefiles {
		 
	# Get current folder name
	filename_original=$(basename "$1")
	filename=${filename_original%.*}
	#filename=${filename//[ ()$+&\.\-\'\,]/}
	# filename=${filename,,}
	extension=${filename_original##*.}

	target="$2"
	cd "$target/"

	source="$1"
	# Create mp4 if not same source
	mp4="$filename.mp3"       
	echo "- Convert: $mp4"
	avconv  -i "$source" "$mp4"

}


time_start_total=`date +%s`
RAWVIDEO=false

if [ -d "$1" ]
then
    # Move to target directory
    cd "$1"   
    
    ### Loop all image folders / days ###
    for i in $1/*
    do
		makefiles "$i" "$2"
	done
elif [ -f "$1" ]
then	
	cd $(dirname $1)
	makefiles "$1" "$2"
else
    echo "Usage: [$filename]"
fi
#end of script
time_end=`date +%s`
time_elapsed=$((time_end - time_start_total))    
echo "script executed in $time_elapsed seconds" $(( time_elapsed / 60 ))m $(( time_elapsed % 60 ))s	

