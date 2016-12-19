#!/bin/sh

ES_HOST=$1

if [ -z $ES_HOST ]; then
	echo "Need es host"
	exit
fi

ES_PORT=$2

if [ -z $ES_PORT ]; then
	echo "Need es port"
	exit
fi

MASTER_NODE=`curl -s "http://$ES_HOST:$ES_PORT/_cat/master?v" | tail -1 | awk '{print $4}'`

if [ -z $MASTER_NODE ]; then
	echo "Failed to get master"
	exit
fi
		

for index in `curl  -s "http://$ES_HOST:$ES_PORT/_cat/shards" | grep UNASSIGNED | awk '{print $1}' | sort | uniq`
do
    for shard in `curl  -s "http://$ES_HOST:$ES_PORT/_cat/shards" | grep UNASSIGNED | grep $index | awk '{print $2}' | sort | uniq`
	do
        echo  $index $shard
        curl -XPOST "http://$ES_HOST:$ES_PORT/_cluster/reroute" -d "{
            \"commands\" : [ {
                  \"allocate\" : {
                      \"index\" : \"$index\",
                      \"shard\" : \"$shard\",
                      \"node\" : \"$MASTER_NODE\",
                      \"allow_primary\" : true
                  }
                }
            ]
        }"

        sleep 5
    done
done

