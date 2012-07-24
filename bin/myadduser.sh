#!/bin/sh
while read LINE
do
adduser "$LINE"
chmod 750 /home/"$LINE"
setquota "$LINE" 10000000 15000000 0 0 -a
echo "ok!"
done
