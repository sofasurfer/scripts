#!/bin/bash
# Full Backup of all mysql database and www files
# ---------------------------------------------------------------------

### System Setup ###
HOMEDIRS="/home/kib/Documents/ /home/kib/Pictures/ /home/kib/Projects/"
##DIRS="/var/www/ /var/log/ /etc/"
WEBDIR="/var/www"
INCFILE="/root/tar-inc-backup"
SUBDIR=$(date +"%Y-%m")
NOW=$(date +"%Y-%m-%d-%T")
BACKUPDIR="/opt/backup/home/www"
DAY=$(date +"%a")
FULLBACKUP="Sun"

# Amazon S3 storage info
S3CONFIG="false"; # "/home/kib/.s3cfg"
S3TARGET="s3://backup.sofasurfer.org/home"

### MySQL Setup ###
MUSER="root"
MPASS="home@sql"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

### Other stuff ###
EMAILID="webmaster@sofasurfer.ch"


### Check if Backup Directory Exist ###
if [ "$DAY" = "$FULLBACKUP" ]; then
        BACKUP=$BACKUPDIR/$NOW-full
else
        BACKUP=$BACKUPDIR/$NOW-incremental
fi
[ ! -d $BACKUP ] && mkdir -p $BACKUP || :


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
# for FOLDER in $(find . -type f -name '*_log' -print | sed 's/^\.\///')
# for FOLDER in $(find $DIRS -maxdepth 0 -type d ); 
for FOLDER in $WEBDIR/*;
do
		PATHNAME=$(basename "$FOLDER")
        if [ "$DAY" = "$FULLBACKUP" ]; 
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
sudo find $BACKUPDIR -type d -mtime +7  | xargs rm -rfv;

### Upload to S3 ###
if [ "$S3CONFIG" = "false" ]; 
then
	echo "Skip s3cmd"
else
	sudo s3cmd sync  --config=$S3CONFIG --skip-existing $BACKUPDIR/ "$S3TARGET/$SUBDIR/"

	for i in $($FIND $HOMEDIRS/* -maxdepth 0 -type d -printf '%f\n'); do
		sudo s3cmd sync  --config=$S3CONFIG --skip-existing $i "$S3TARGET/$i"
	done
fi

### Find out if ftp backup failed or not ###
LOCATION=$(basename "$BACKUP")
if [ "$?" = "0" ]; 
then
        python /usr/local/bin/tweet.py "home.sofasurfer.org - BACKUP successful - Location: $LOCATION"
else
        python /usr/local/bin/tweet.py "home.sofasurfer.org - BACKUP FAILED - Location: $LOCATION"
fi

rm -f $T
                                 
