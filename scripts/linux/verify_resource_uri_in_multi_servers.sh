#!/bin/sh

URI=$1

if [ -z $URI ]; then
    echo "Need uri"
    exit 1
fi

HOST=`echo $URI | egrep -o 'https?://\S+/?' | awk -F '/' '{print $3}'`

IPS=$2

if [ -z $IPS ]; then
    echo "Need comma-separated ip list like 8.8.8.8,8.8.4.4"
    exit 1
fi

IPS=`echo $IPS | tr "," "\n"`
HAS_FAILED=0

for IP in $IPS
do
    uri_with_ip=`echo $URI | sed "s/$HOST/$IP/"`
    response_code=` curl -s -w "%{http_code}" -XHEAD -H "Host:$HOST" $uri_with_ip`

    if [ $response_code"x" != "200x" ]; then
    	echo "Failed on $IP, HTTP code $response_code"
    	HAS_FAILED=1
    fi
done

if [ $HAS_FAILED -eq 0 ]; then
    echo "All found"
fi

