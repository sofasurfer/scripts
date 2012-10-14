#!/bin/bash
#################################################################
### html5encode.sh by Brett Terpstra and Mike Rose
### Published 05/01/2011
### Freely distributed, modifications welcomed (with attribution)
#################################################################
### Configuration ###############################################
#################################################################
MAXSIZE="1920x1080"
DISPLAYWIDTH="960"
DISPLAYHEIGHT="540"
SSHURL="debug@home.sofasurfer.org:77"
SSHDIR=" /opt/stream/drivers/"
WEBDIR="/sdrive/drivers/" # used for blog template
LOGGING=true # send status messages and times to STDOUT and syslog
GROWLLOG=false # duplicate messages to growl, if installed
##################################################################
### END Configuration ############################################
##################################################################

# function to handle logging (if enabled) to STDOUT and STDERR 
# as well as Growl (if enabled)
function logit() {
  if $LOGGING ; then
    logger -st "HTML5 Encoder" "$1"
    if $GROWLLOG ; then
      /usr/local/bin/growlnotify -t "HTML5 Encoder" -a "Terminal" -m "$1"
    fi
  fi
}

# Count the inputs for log message
if [[ $# -gt 1 ]]; then
  logit "Starting batch conversion."
  maintimer1=`date '+%s'`
else
  logit "Starting HTML5 Encoder"
fi

# Loop through each passed file
for file in "$@"; do
  timer1=`date '+%s'`
  INPUT=$file
  # Check that input file is H.264
  isH264=`mdls -raw -name kMDItemCodecs $INPUT|grep H.264`

  if [ !$isH264 ] ; then
    logit "$INPUT is not h.264"
    continue
  fi

  DIRNAME=`dirname "$INPUT"`
  FILENAME=`basename "$INPUT"`
  BASENAME=${FILENAME%%.*}
  logit "Conversion of $FILENAME started on `date '+%D'` at `date '+%r'`"
  bytesize=`stat -f '%z' $FILENAME`
  filesize=`echo "scale = 2 ; $bytesize/1048576"|bc -lq`
  cd "$DIRNAME"
  if [ -d "$BASENAME" ]; then
    logit "Found $FILENAME, but directory $BASENAME already exists. Aborting"
    continue
  fi
  mkdir "$BASENAME"
  mv "$FILENAME" "$BASENAME/"
  cd "$BASENAME"
  if [[ ${FILENAME#*.} -eq "mov" ]]; then mv $FILENAME ${BASENAME}.mp4; fi  
  FILENAME=${BASENAME}.mp4
  /usr/local/bin/ffmpeg -i "$FILENAME" -b 614400 -s $MAXSIZE -aspect 16:9 "$BASENAME".webm
  logit "Completed webm conversion"
  /usr/local/bin/ffmpeg2theora --videoquality 5 --audioquality 1 --max_size $MAXSIZE "$FILENAME" -o "$BASENAME.ogv"
  logit "Completed ogv conversion"
  /usr/local/bin/ffmpeg -i "$FILENAME" -ss 0 -vframes 1 -vcodec mjpeg -f image2 "${BASENAME}Poster.jpg"
  logit "Created poster image"

  # Create a title from camelcased filename
  TITLE=`echo "$BASENAME"|sed 's/\([A-Z][^A-Z]*\)/& /g'|sed 's/ $//'`
  SERVER=`echo "$SSHURL"|sed 's/^.*\@//'`
  logit "Uploading to $SERVER..."
  cd ..
  rsync -v -r -e ssh "`pwd`/$BASENAME" $SSHURL:$SSHDIR
  logit "Finished Uploading"
  # remove trailing slash from $WEBDIR
  WEBDIR=`echo "$WEBDIR"|sed 's/\/$//'`
  cat > "$BASENAME/$BASENAME.blog.markdown" <<-POSTTEMPLATE
Type: Blog Post (Markdown)
Blog: BlogsmithVideo
Title: $TITLE
Keywords: 
Status: draft
Pings: On
Comments: On
Category: Tutorials

Synopsis

[video mp4="$WEBDIR/$BASENAME/$BASENAME.mp4" ogg="$WEBDIR/$BASENAME/$BASENAME.ogv" webm="$WEBDIR/$BASENAME/$BASENAME.webm" poster="$WEBDIR/$BASENAME/${BASENAME}Poster.jpg" preload="true" width="$DISPLAYWIDTH" height="$DISPLAYHEIGHT"]

<!--more-->

Transcript

POSTTEMPLATE

  open "$BASENAME/$BASENAME.blog.markdown" -a "TextMate.app"
  timer2=`date '+%s'`
  time=`echo "scale=2 ; ($timer2-$timer1)/60"|bc -lq`
  logit "Conversion of $FILENAME complete"
  logit "It took $time minutes to process a ${filesize}M MP4 to webm and ogv and upload to `echo "$SSHURL"|sed 's/^.*\@//'`."
done
if [[ $# -gt 1 ]]; then
  maintimer2=`date '+%s'`
  total=`echo "scale=2 ; ($maintimer2-$maintimer1)/60"|bc -lq`
  logit "Batch conversion complete, total time $total minutes."
fi
