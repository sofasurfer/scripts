#!/bin/sh
# Full Backup of all mysql database and www files
# ---------------------------------------------------------------------

### System Setup ###
DIRS="/var/www/ /var/log/ /etc/"
INCFILE="/root/tar-inc-backup"
SUBDIR=$(date +"%Y-%m")
NOW=$(date +"%Y-%m-%d-%T")
BACKUPDIR=/mnt/backup
DAY=$(date +"%a")
FULLBACKUP="Sun"

if [ "$DAY" = "$FULLBACKUP" ]; then
        BACKUP=$BACKUPDIR/$NOW-full
else
        BACKUP=$BACKUPDIR/$NOW-incremental
fi

### MySQL Setup ###
MUSER="root"
MPASS="sofa@sql"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

### Other stuff ###
EMAILID="webmaster@sofasurfer.ch"


### Check if Backup Directory Exist ###
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
#for i in $($FIND $DIRS/* -maxdepth 0 -type d -printf '%f\n'); do

        if [ "$DAY" = "$FULLBACKUP" ]; then

                FILE="www-full.tar.bz2"
                tar -jcf $BACKUP/$FILE $DIRS

        else

                FILE="www-incremental.tar.bz2"
                tar -g $INCFILE -jcf $BACKUP/$FILE $DIRS

        fi
#done

### delete old backup directories ###
sudo find $BACKUPDIR -type d -mtime +7  | xargs rm -rfv;

### Upload to S3 ###
sudo s3cmd sync  --config=/home/ubuntu/.s3cfg --skip-existing $BACKUPDIR/ s3://storage.sofasurfer.org/backup/sofasurfer.ch/$SUBDIR/

### Find out if ftp backup failed or not ###i
T=/tmp/backup.fail
echo "Date: $(date)">>$T
echo "Storage  \t$BACKUP" >>$T
echo "\nFiles\n$(ls -lh $BACKUP)" >>$T
echo "\n$(df -h)" >>$T


if [ "$?" = "0" ]; then
        mail  -s "sofasurfer.ch - BACKUP successful" "$EMAILID" <$T
else
        mail  -s "sofasurfer.ch - BACKUP FAILED" "$EMAILID" <$T
fi

rm -f $T
                                 
