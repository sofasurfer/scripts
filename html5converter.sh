#!/bin/bash
# HTML5 video converter
# ---------------------------------------------------------------------


function makefiles {
		 
	# Get current folder name
	filename_original=$(basename "$1")
	filename=${filename_original%.*}
	filename=${filename//[ ()$+&\.\'\,]/}
	filename=${filename//\/\//\/}

	#Template
	TEMPLATEPATH="/opt/stream/html/tpl"

	# filename=${filename,,}
	extension=${filename_original##*.}

	if [ "$extension" == "avi" -o "$extension" == "mkv" -o "$extension" == "mp4" -o "$extension" == "mpg" -o "$extension" == "mov" -o "$extension" == "webm"  -o "$extension" == "wmv" ]
	then

		target="$2/$filename"
 		target=${target//\/\//\/}

		basepath="$4"
 		basepath=${basepath//\/\//\/}

		#relativepath="$4/$filename"
		relativepath="$filename"
 		#relativepath=${$relativepath//$base/\/}
		#relativepath=`echo $relativepath|sed 's/\/opt\/stream\///'`
 		relativepath=${relativepath//\/\//\/}

		absolutepath="http://stream.sofasurfer.org/$relativepath"

		# Create target directory
		if [ ! -d "$target" ]; then mkdir -p $target; fi

		#cp	"$1" "$target"

		source="$1"

		cd "$target"

		NOW=$(date +"%Y-%m-%d-%T")
		duration=$(avconv -i "$source" 2>&1  | grep Duration | awk '{print $2}' | tr -d ,)
		duration=${duration%.*}
		video=$(avconv -i "$source" 2>&1 | grep Video  | sed 's/ *$//g' )

		minutes=${duration%:*}
		hours=${minutes%:*}
		minutes=${minutes##*:}
		seconds=${duration##*:}
		seconds=${seconds%.*}

		hours=`echo $hours|sed 's/^0*//'`
		minutes=`echo $minutes|sed 's/^0*//'`
		seconds=`echo $seconds|sed 's/^0*//'`

		#hours=$((hours*3600))
		#minutes=$((minutes*60))

		total=$(expr $hours + $minutes + $seconds)
		number=$RANDOM
		let "number %= $total"


		echo "***********************************"       
		echo "Source: $source ($extension)"
		echo "Target: $target"
		echo "Rel : $relativepath"
		echo "URL : $absolutepath"
		echo "Time: $duration"
		echo "Size: $width / $height"
		echo "Rand: $number"
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
		if [ "1" == "1" ]
		then
			echo "- Skip: $webm"
		elif [ -f "$webm" ]
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
		
			time_end=`date +%s`
			time_elapsed=$((time_end - time_start))    
			echo "  Done: " $(( time_elapsed / 60 ))m $(( time_elapsed % 60 ))s
			  
		fi
	
		# Create OGV
		ogv="$filename.ogv" 
		if [ "1" == "1" ]
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

		thumb="thumb.jpg"
		if [ -f "$thumb" ]
		then
			echo "- Exist: $thumb"
		else
			avconv  -ss "$number" -i "$mp4" -f image2 -s 360x200 -frames:v 1 "$thumb"

			if [ $? != 0 ]
			then
				rm "$thumb"
			fi		
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

		# SET Movie properties
		pagetitle=$filename
		width=$(exiftool  "$mp4" 2>&1 | grep 'Source Image Width' | awk '{print $5}' )
		height=$(exiftool  "$mp4" 2>&1 | grep 'Source Image Height' | awk '{print $5}' )

		videosources=()				
		sourcehtml=""
		if [ -f "$mp4" ]
		then
			videosources=("${videosources[@]}" "{ \"type\":\"video/mp4\", \"src\":\"$mp4\" }")				
			sourcehtml="$sourcehtml <source type=\"video/mp4\" src=\"$mp4\" />\n"
		fi

		if [ -f "$webm" ]
		then
			videosources=("${videosources[@]}" "{ \"type\":\"video/webm\", \"src\":\"$webm\" }")	
			sourcehtml="$sourcehtml <source type=\"video/webm\" src=\"$webm\" />\n"

		fi			
		if [ -f "$ogv" ]
		then
			videosources=("${videosources[@]}" "{ \"type\":\"video/ogv\", \"src\":\"$ogv\" }")		
			sourcehtml="$sourcehtml <source type=\"video/ogv\" src=\"$ogv\" />\n"
		fi


		srt="$filename.srt"
		if [ -f "$srt" ]
		then
			videosources=("${videosources[@]}" "{ \"kind\":\"subtitle\", \"srclang\":\"en-US\", \"label\":\"English\", \"src\":\"$srt\" }")		
			sourcehtml="$sourcehtml <track src=\"$srt\" kind=\"subtitle\" srclang=\"en-US\" label=\"English\" />\n"
		fi

		# Create json if not same source
		json="$filename.json"
		if [ -f "$json2" ]
		then
			echo "- Exist: $json"
		else           
			#description=$( exiftool "$source" 2>&1 )
			echo -e "{
				\"name\": \"$filename\",
				\"filename\": \"$filename\",
				\"path\": \"$target\",
				\"rel\": \"$relativepath\",
				\"url\": \"$absolutepath\",
				\"duration\": \"$duration\",
				\"width\": \"$width\",
				\"height\": \"$height\",
				\"poster\": \"$poster\",
				\"createdon\": \"$NOW\",\
				\"sources\":[ $(IFS=, ; echo "${videosources[*]}") ]" > "$json"

				## Write source info
				echo ",\"extended\": {" >> "$json"
				echo $(exiftool "$source" | sed -e 's/^/\"/' | sed -e 's/: /\":\"/' | sed -e 's/\([^,]\)$/\1\",/' ) >> "$json"
				echo "\"time\": \"$NOW\" }" >> "$json"

			echo "}" >> "$json"

			echo "- Create: $json" 
		fi


		# Create HTML EMBED
		#width="640"
		#height="350"

		caption="$filename"

		html="$filename.html"
		if [ -f "$html2" ]
		then
			echo "- Exist: $html"
		else
			pagetitle=$filename
			cat "$TEMPLATEPATH/header.tpl"  > "$html"
			echo "
				<div class=\"main\">
					<div class=\"page-header\">
						<h1>$filename</h1>
					</div>" >>   "$html"	
			eval "echo -e \"$(< "$TEMPLATEPATH/video.tpl")\"" >> "$html"
			echo "</div>" >> "$html"
			cat "$TEMPLATEPATH/footer.tpl"  >> "$html"
			echo "- Create: $html"

		fi


		# Check for index JSON file
		jsonindex="$basepath/index.json"
		jsonindexpart="$basepath/$filename.json.part"
		if [ -f "$jsonindexpart" ]
		then
			echo "- Exist: $jsonindex"
		else 		
			cat "$json" >> "$jsonindex"
			echo "," >> "$jsonindex"
			echo "- Added to: $jsonindex" 

			cat "$jsonindex" > "$jsonindexpart"
		fi


		# Check for index HTML file
		htmlindex="$basepath/index.html"
		htmlindexpart="$basepath/$filename.html.part"
		if [ -f "$htmlindexpart" ]
		then
			echo "- Exist: $htmlindex"
		else 		
			eval "echo -e \"$(< "$TEMPLATEPATH/thumb.tpl")\"" >> "$htmlindex"
			echo "- Added to: $htmlindex" 

			cat "$htmlindex" > "$htmlindexpart"
		fi


		# Clean UP
		if [ -f "$svideo" ]; then rm "$svideo"; fi
		if [ -f "$saudio" ]; then rm "$saudio"; fi
		find $target -type f -name _* -delete
		find $target -type f -name *.log -delete

		#Create JSON item
		echo "All Done!"
	#else
		#echo "Invalid file: $filename"
	fi
}


time_start_total=`date +%s`
RAWVIDEO=false


if [ -d "$1" ]
then
    # Move to target directory
    cd "$1"   

    
	rootpath=$(basename "$1")


    # Delete index file
    jsonfile="$1/index.json"
	jsonfile=${jsonfile//\/\//\/}
    echo  "{\"rows\":[" > "$jsonfile"

    htmlfile="$1/index.html"
	htmlfile=${htmlfile//\/\//\/}
    
	cat "/opt/stream/html/tpl/header.tpl" > "$htmlfile"
	echo "
		<div class=\"main\">
			<div class=\"page-header\">
				<h1>$rootpath</h1>
			</div>	
			<ul class=\"thumbnails\">" >> "$htmlfile"	

    echo "$htmlfile"


    ### Loop all image folders / days ###
    for i in $1/*
    do
		if [ -d "$i" ]
		then
    		for i2 in $i/*
			do
				makefiles "$i2" "$2" "$rootpath" "$1"
			done
		else
			makefiles "$i" "$2" "$rootpath" "$1"
		fi
	done

	sed -i '$ d' "$jsonfile"
    echo  "]}" >> "$jsonfile"
    echo "jSon file created: $jsonfile"

    echo "</ul></div>" >> "$htmlfile"	
	cat "/opt/stream/html/tpl/footer.tpl" >> "$htmlfile"
    echo "HTML file created: $htmlfile"

	find "$1" -name '*.part' -delete


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

