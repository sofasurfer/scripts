#!/bin/bash
# Full Backup of all mysql database and www files
# ---------------------------------------------------------------------

### System Setup ###
DATADIRS="/var/log/ /etc/"
WEBDIR="/var/www"
INCFILE="/root/tar-inc-backup"
YEAR=$(date +"%Y")
NOW=$(date +"%Y-%m-%d-%T")
BACKUPDIR="/media/data/backup"
DAY=$(date +"%a")
FULLBACKUP="Sun"

# Amazon S3 storage info
S3CONFIG="/home/ec2-user/.s3cfg"
S3TARGET="s3://backup.sofasurfer.org/sofaweb/$YEAR"

### MySQL Setup ###
MUSER="root"
MPASS="???"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

### Other stuff ###
EMAILID="webmaster@sofasurfer.ch"


### Check if Backup Directory Exist ###
if [ "$DAY" = "$FULLBACKUP" -o "$1" == "full" ]; then
        BACKUP=$BACKUPDIR/$NOW-full
else
        BACKUP=$BACKUPDIR/$NOW-incremental
fi
[ ! -d $BACKUP ] && mkdir -p $BACKUP || :


### Start general Backup ###
if [ "$DAY" = "$FULLBACKUP" -o "$1" == "full" ]; then
	for FOLDER in $DATADIRS
	do
    	FILE="$BACKUP/data-$(basename $FOLDER).tar.bz2"
    	tar -jcf $FILE $FOLDER
    	echo $FILE
	done
else
	echo "Ignore datadir"
fi


### Start MySQL Backup ###
echo "Start Backup:$BACKUP"

# Get all databases name
DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
    FILE=$BACKUP/mysql-$db.sql
	$MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS $db -r $FILE

	tar -jcvf $FILE.tar.bz2 $FILE
	rm $FILE
done


### Start WWW Backup ###
### See if we want to make a full backup ###
for FOLDER in $WEBDIR/*;
do
	PATHNAME=$(basename "$FOLDER")
    if [ "$DAY" = "$FULLBACKUP" -o "$1" == "full" ]; 
    then

        FILE="$BACKUP/www-$PATHNAME-full.tar.bz2"
        tar -jcf $FILE $FOLDER

    else

        FILE="$BACKUP/www-$PATHNAME-incremental.tar.bz2"
        tar -g "$INCFILE-$PATHNAME" -jcf $FILE $FOLDER

    fi
    echo "Backup $FOLDER \t->\t $FILE"
done



### delete old backup directories ###
find "$BACKUPDIR/" -ctime +1 -delete


### Upload to S3 ###
if [ "$S3CONFIG" = "false" ]; 
then
	echo "Skip s3cmd"
else
	
    s3cmd sync  --config=$S3CONFIG --skip-existing "$BACKUPDIR/" "$S3TARGET/"

    ### Delete incremental files
    if [ "$DAY" = "$FULLBACKUP" -o "$1" == "full" ]; then
        s3cmd --config=$S3CONFIG  --recursive --exclude "*full/*" --exclude="*webmin*" del "$S3TARGET/"       
    fi
fi

### Find out if ftp backup failed or not ###
LOCATION=$(basename "$BACKUP")
TOTALFILES=$(ls -1 $BACKUP | wc -l)

if [ "$?" = "0" ]; 
then
        MESSAGE="home.sofasurfer.org - #backup #success - Location: $LOCATION Files: $TOTALFILES"
else
        MESSAGE="home.sofasurfer.org - #backup #FAILED - Location: $LOCATION Files: $TOTALFILES"
fi

python /usr/local/bin/tweet.py "$MESSAGE"
#mailx -s "$MESSAGE" < /dev/null "$EMAILID"

rm -f $T
