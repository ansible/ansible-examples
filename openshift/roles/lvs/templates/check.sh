#!/bin/bash
LINES=`wget -q -O - --no-check-certificate https://$1/broker/rest/api | wc -c`
if [ $LINES -gt "0" ]; then
        echo "OK" 
else
        echo "FAILURE" 
fi
exit 0
