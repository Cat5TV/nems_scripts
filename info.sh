#!/bin/bash
# NEMS Server Info Script

export COMMAND=$1
me=`basename "$0"`
USAGE="Usage: ./$me COMMAND"
if [ $COMMAND = "ip" ]; then
  /sbin/ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+'
else if [ $COMMAND = "nemsver"]; then
  /bin/cat /var/www/html/inc/ver.txt
else if [ $COMMAND = "nemsveravail"]; then
  /bin/cat /var/www/html/inc/ver-available.txt
else
  echo $USAGE
fi