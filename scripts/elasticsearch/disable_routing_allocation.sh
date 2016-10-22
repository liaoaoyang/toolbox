#!/bin/sh

if [ -z $ES_HOST ]; then
	echo "Need es host"
	exit
fi

curl -s -XPUT "http://$ES_HOST:9200/_cluster/settings" -d'{
	"transient" : {
		"cluster.routing.allocation.enable" : "none"
		}
}'
