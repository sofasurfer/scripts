#!/usr/local/bin/bash
if  [ ! $3 ]; then
 echo "usage: $0 <ip list file> <authlog file> <word> [-z]"
 echo "         <ip list file> #file with trusted ip adresses on each line"
 echo "         <authlog file> #authlog location, /var/log/authlog"
 echo "         <word>         #pettern to grep from output, 'Accept' for all accepted logins"
 echo "         -z             #use zcat, for gziped log rotate log files, do not forgot the quotes"
 echo "         $0 iplist.txt \"/var/log/authlog.*\" Accept -z"
 exit 1
fi
 
declare -a input
 
exec< $1
 
input=[]
 
while read line
do
 output="$output$line|";
done
echo "cat $2 |egrep -v \"${output%\|}\" |grep \"$3\""
if  [ ! $4 ]; then
 cat $2 |egrep -v "${output%\|}" |grep "$3"
else
 zcat $2 |egrep -v "${output%\|}" |grep "$3"
fi

