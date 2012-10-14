#!/bin/bash
 
EXPECTED_ARGS=1
E_BADARGS=65
MYSQL=`which mysql`

PASSWORD=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8`

Q1="CREATE DATABASE IF NOT EXISTS  $1 ;"

Q2="CREATE USER '$1'@'localhost' IDENTIFIED BY  '$PASSWORD';"

Q3="GRANT USAGE ON * . * TO  '$1'@'localhost' IDENTIFIED BY  '$PASSWORD' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;"

Q4="GRANT ALL PRIVILEGES ON  $1 . * TO  '$1'@'localhost';"

SQL="${Q1}${Q2}${Q3}${Q4}"

echo "${Q1}\n${Q2}\n${Q3}\n${Q4}"

if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname dbuser dbpass"
  exit $E_BADARGS
fi
 
$MYSQL -uroot -p -e "$SQL"

echo "User and database [$1] are created password: $PASSWORD"
