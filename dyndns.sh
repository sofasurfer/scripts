#! /bin/bash 
# this script updates the dynamic ip on http://freedns.afraid.org/ using curl 
# check http://freedns.afraid.org/api/ and as weapon ASCII for the phrase in UPDATE_URL 
LOG_FILE="/var/log/dyndns-ip.log"
OLDIP_FILE="/var/lib/misc/oldip" 
CHECK_CMD="/usr/bin/curl -s http://ip.dnsexit.com/ | sed -e 's/ //'" 
UPDATE_URL="http://freedns.afraid.org/dynamic/update.php?U2kwUFhuTnhZdk5ZUzFHUzFMY1U6NjU4NjkyOQ==" 
UPDATE_COMMAND="/usr/bin/curl -s $UPDATE_URL" 
NOW=$(date +"%Y-%m-%d-%T")

echo "Getting current IP" 
CURRENTIP=`${CHECK_CMD}` 
echo "Found ${CURRENTIP}" 

if [ ! -e "${OLDIP_FILE}" ] ; then 
	echo "Creating ${OLDIP_FILE}" 
	echo "0.0.0.0" > "${OLDIP_FILE}" 
fi 

OLDIP=`cat ${OLDIP_FILE}` 

if [ "${CURRENTIP}" != "${OLDIP}" ] ; then 
	echo "Issuing update command" 
	${UPDATE_COMMAND} 
	echo "${NOW}\t${OLDIP}\t${CURRENTIP}" >> "${LOG_FILE}"

	python /usr/local/bin/tweet.py "home.sofasurfer.org - IP Changed ${OLDIP} to ${CURRENTIP}"

else
	echo "IP still the same:${CURRENTIP}"
fi 


echo "Saving IP" 
echo "${CURRENTIP}" > "${OLDIP_FILE}"
