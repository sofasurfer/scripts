#!/bin/sh
# Generate motion CCTV video from JPG folders
# and a jSon archive file
#
# @author http://sofasurfer.org
#
# http://brettterpstra.com/automating-html5-video-encodes/
# ---------------------------------------------------------------------

### System Setup ###
MAXSIZE="320x240"						# Video size 960x540

#IMAGEDIR="/opt/motion/images"			# Directory where motion images are stored (assusmes "%Y-%m-%d" sub folders)
#VIDEODIR="/opt/stream/cctv"			# Where to store the generated video files'

IMAGEDIR="/opt/backup/lucky/motion"		# Directory where motion images are stored (assusmes "%Y-%m-%d" sub folders)
VIDEODIR="/opt/stream/cctv/lucky"		# Where to store the generated video files


VIDEOURL="/media/cctv/"					# URL to video path

JSONFILE="$VIDEODIR/data.json"			# Path of XML archive file

TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%d-%m-%Y-%T")
UPDATE=$(date +%s)


### Loop all image folders / days ###
for i in $IMAGEDIR/*
do

	# Get current folder name
	CURDIR=$(basename $i)

	# Set the target folder 
	BASEDIR="$VIDEODIR/$CURDIR"

	# Set the filename (without mimetype)
	BASENAME="$BASEDIR/$CURDIR"
	
	# Set the relative PATH
	URLPATH="$CURDIR/"
	
	### Check if today
	if [ "$CURDIR" =  "$TODAY" ];
	then
		rm -rf $BASEDIR
	fi

	### Check if folder exist and not today
	if [ -d "$BASEDIR" ];
	then

		echo "Folder exist $BASENAME"
	else
	
		# Create folder
		mkdir $BASEDIR
		FULLDIR="$IMAGEDIR/$CURDIR/"
		TOTALFILES=$(ls -1 $FULLDIR | wc -l)
	
		## Create avi file from jpg
		mencoder "mf://$IMAGEDIR/$CURDIR/*.jpg" -mf fps=25:type=jpg -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o "$BASENAME.avi"

		### Upload to S3 ###
		# sudo s3cmd sync  --config=/home/ubuntu/.s3cfg --skip-existing $BACKUPDIR/ s3://storage.sofasurfer.org/backup/sofasurfer.ch/$SUBDIR/

		#rm -rf $IMAGEDIR/$CURDIR
		
	fi

done

# Convert files to HTML5 video format
/usr/local/bin/html5converter.sh /opt/stream/cctv/lucky/ /opt/stream/cctv/lucky/

echo "home.sofasurfer.org - MOTION Files: $TOTALFILES Directory: $FULLDIR"

python /usr/local/bin/tweet.py "home.sofasurfer.org - MOTION Files: $TOTALFILES Directory: $FULLDIR"

echo "DONE: Index created $INDEXFILE"
