#!/bin/bash

# Wait 30 seconds to prevent issues at boot with a missing version file during transit
sleep 30

# Tell the web cache to serve up the file from midnight
timestamp=$( /bin/date --date="today 00:00:01 UTC -5 hours" +%s )
/usr/bin/wget -q -O /var/www/html/inc/ver-available.txt http://cdn.zecheriah.com/baldnerd/nems/ver-current.txt#$timestamp

# Update nems-migrator
cd /root/nems/nems-migrator && git pull

# Copy the version data to the public inc folder (in case it accidentally gets deleted)
test -d "/var/www/html/inc" || mkdir -p "/var/www/html/inc" && cp /root/nems/ver.txt "/var/www/html/inc"