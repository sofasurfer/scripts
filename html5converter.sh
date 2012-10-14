#!/bin/bash
# HTML5 video converter
# ---------------------------------------------------------------------


function makefiles {
		 
	# Get current folder name
	filename_original=$(basename "$1")
	filename=${filename_original%.*}
	filename=${filename//[ ()$+&\.\'\,]/}
	# filename=${filename,,}
	extension=${filename_original##*.}

	target="$2$filename"
	
	# Create target directory
	if [ ! -d "$target" ]; then mkdir -p $target; fi

	#cp	"$1" "$target"

	source="$1"

	if [ "$extension" == "avi" -o "$extension" == "mp4" -o "$extension" == "mov" -o "$extension" == "webm"  -o "$extension" == "wmv" ]
	then

		cd "$target"
		
		duration=$(avconv -i "$source" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
		duration=${duration%.*}
		video=$(avconv -i "$source" 2>&1 | grep Video )
		
		minutes=${duration%:*}
		hours=${minutes%:*}
		minutes=${minutes##*:}
		seconds=${duration##*:}
		seconds=${seconds%.*}

		minutes=`echo $minutes|sed 's/^0*//'`

		hours=$((hours*3600))
		minutes=$((minutes*60))

		total=$(expr $hours + $minutes + $seconds)
		number=$RANDOM
		let "number %= $total"

		T="$filename.txt"
		#if [ ! -f "$T" ]
		#then
			echo -e "$(exiftool "$source")">$T
		#fi
	
		echo "***********************************"       
		echo "Source: $source ($extension)"
		echo "Target: $target"
		echo "Time: $duration"
		echo "***********************************"

	
		# Create mp4 if not same source
		mp4="$filename.mp4"
		if [ -f "$mp4" ]
		then
			echo "- Exist: $mp4"
		elif [ "$extension" == "mp4" ]
		then
			echo "- Copy: $mp4"
			cp "$source" "$mp4"
		else           
			time_start=`date +%s`	
			echo "- Convert: $mp4"
		
			#avconv -qmin 1 -qmax 51 -i "$source" -acodec libvorbis -ab 96k -vcodec libx264 -level 21 -refs 2 -b:v 345k -bt 345k -threads 0 -y "$mp4"	
			avconv  -qmin 1 -qmax 51 -i "$source" -ab 96k -vcodec libx264 "$mp4"

			time_end=`date +%s`
			time_elapsed=$((time_end - time_start))    
			echo "  Done: " $(( time_elapsed / 60 ))m $(( time_elapsed % 60 ))s
		fi 
		#source="$mp4"

		# Create WEBM 
		webm="$filename.webm"	
		if [ -f "$webm" ]
		then
			echo "- Exist: $webm"
		elif [ "$extension" == "webm" ]
		then
			echo "- Copy: $webm"
			cp "$source" "$webm"		
		else        
			time_start=`date +%s`
			echo "- Convert: $webm"
		
			#svideo="$svideo.yuv"
			#avconv -i "$source" -f yuv4mpegpipe -pix_fmt yuv420p -vcodec libx264 "$svideo"

			avconv -i "$source"  "$webm"

			#avconv -i "$source" -b:a 64k -b:v 1000k  "$webm"
			#avconv -i "$source" -c:a libvorbis -b:a 64k -c:v libvpx -b:v 1000k  -f "$webm"
		
			#avconv -i "$source" -threads 8 -pass 1 -an  -f webm "_$webm"
			#avconv -i "$source" -threads 8 -pass 2 -c:a libvorbis -c:v libvpx  -f webm "$webm"			
		
			#avconv  -qmin 1 -qmax 51 -i "$source" -threads 8 -pass 1 -an -f webm "_$webm"
			#avconv  -qmin 1 -qmax 51 -i "$source" -threads 8 -pass 2 -c:a libvorbis -c:v libvpx  -f webm "$webm"			
		
							
			time_end=`date +%s`
			time_elapsed=$((time_end - time_start))    
			echo "  Done: " $(( time_elapsed / 60 ))m $(( time_elapsed % 60 ))s
			  
		fi
	
		# Create OGV
		ogv="$filename.ogv" 
		if [ "1" == "2" ]
		then
			echo "- Skip: $ogv"
		elif [ -f "$ogv" ]
		then
			echo "- Exist: $ogv"
		else        
			time_start=`date +%s`
			echo "- Convert: $ogv"
		
			ffmpeg2theora --videoquality 5 --audioquality 1 "$source" -o "$ogv" 
			#avconv -qmin 1 -qmax 51 -i "$source"  "$ogv"

			time_end=`date +%s`
			time_elapsed=$((time_end - time_start))    
			echo "  Done: " $(( time_elapsed / 60 ))m $(( time_elapsed % 60 ))s
		
		fi        
	
		# Create jpg
		poster="$filename.jpg"
		if [ -f "$poster" ]
		then
			echo "- Exist: $poster"
		else
			avconv  -ss "$number" -i "$mp4" -f image2 -frames:v 1 "$poster"
			echo "- Convert: $poster" 
		fi

		# Create png
		poster="$filename.png"
		if [ -f "$poster" ]
		then
			echo "- Exist: $poster"
		else
			avconv  -ss "$number" -i "$mp4" -f image2 -frames:v 1 "$poster"
			echo "- Convert: $poster" 
		fi
	
		# Clean UP
		if [ -f "$svideo" ]; then rm "$svideo"; fi
		if [ -f "$saudio" ]; then rm "$saudio"; fi
		find $target -type f -name _* -delete
		find $target -type f -name *.log -delete

		#Create JSON item
		echo "All Done!"
	fi
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
		if [ -d "$i" ]
		then
    		for i2 in $i/*
			do
				makefiles "$i2" "$2"
			done
		else
			makefiles "$i" "$2"
		fi
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

