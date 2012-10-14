#!/bin/sh
# Generate motion CCTV video from JPG folders
# and a jSon archive file
#
# @author http://sofasurfer.org
#
# http://brettterpstra.com/automating-html5-video-encodes/
# ---------------------------------------------------------------------

### System Setup ###
MAXSIZE="1920x1080"
SSHURL="kib@192.168.0.77"
SSHDIR="/opt/stream/drivers/"
### END CONFIG ###
INPUT=$1
DIRNAME=`dirname "$INPUT"`
FILENAME=`basename "$INPUT"`
BASENAME=${FILENAME%%.*}

echo Dir: ${DIRNAME}
echo File: ${FILENAME}
echo Base: ${BASENAME}
 
cd "$DIRNAME"
if [ ! -d "$BASENAME" ]; then
	mkdir "$BASENAME"
fi
cp "$FILENAME" "$BASENAME/"
cd "$BASENAME"

	
# Get current folder name
duration=$(avconv -i "$FILENAME" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)

minutes=${duration%:*}
hours=${minutes%:*}
minutes=${minutes##*:}
seconds=${duration##*:}
seconds=${seconds%.*}

hours=$((hours*3600))
minutes=$((minutes*60))

total=$(expr $hours + $minutes + $seconds)
number=$RANDOM
let "number %= $total"
 
avconv -pass 1 -passlogfile "$FILENAME" -threads 16  -keyint_min 0 \
-g 250 -skip_threshold 0 -qmin 1 -qmax 51 -i "$FILENAME" -vcodec libvpx -b:V 614400 \
temp.webm
#-s $MAXSIZE -aspect 16:9 -an -y temp.webm
  
avconv -pass 2 -passlogfile "$FILENAME" -threads 16  -keyint_min 0 \
-g 250 -skip_threshold 0 -qmin 1 -qmax 51 -i "$FILENAME" -vcodec libvpx -b:v 614400 \
-acodec libvorbis  "$BASENAME".webm
#-s $MAXSIZE -aspect 16:9 -acodec libvorbis -y "$BASENAME".webm
  
rm temp.webm
rm *.log
 
avconv -i "$FILENAME"  -qmin 1 -qmax 51  "$BASENAME.ogv"
#ffmpeg -i "$FILENAME" -ss 0 -vframes 1 -vcodec mjpeg -f image2 "$BASENAME.jpg"
avconv  -ss "$number" -i "$source" -f image2 -frames:v 1 "$BASENAME.jpg"
cd ..
rsync -v -r -e ssh "`pwd`/$BASENAME" $SSHURL:$SSHDIR
