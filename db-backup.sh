#!/bin/bash
# Full Backup of all mysql database and www files
# ---------------------------------------------------------------------

### System Setup ###
YEAR=$(date +"%Y")
NOW=$(date +"%Y-%m-%d-%H%M")
WEBDIR="/Users/kilianbohnenblust/Development/www/"
BACKUPDIR="/Users/kilianbohnenblust/Downloads/_backup/db/"
DAY=$(date +"%a")
FULLBACKUP="Sun"

### MySQL Setup ###
MUSER="root"
MPASS="root"
MHOST="localhost"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"




### Check if Backup Directory Exist ###
BACKUP=$BACKUPDIR$NOW-full
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
#for FOLDER in $WEBDIR*;
#do
#    PATHNAME=$(basename "$FOLDER")
#    FILE="$BACKUP/www-$PATHNAME-full.tar.bz2"
#    tar -jcf $FILE $FOLDER
#    echo "Backup $FOLDER \t->\t $FILE"
#done


echo "Sync ToServer\n"
rsync -rva --progress "$BACKUPDIR" /Volumes/data/_transfer/kilian/_backup/db/
rsync -rva --progress "$WEBDIR" /Volumes/data/_transfer/kilian/_backup/www/


echo "Backup done\n"

