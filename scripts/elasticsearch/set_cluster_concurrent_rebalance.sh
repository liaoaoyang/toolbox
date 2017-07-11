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

REBALANCE=$3

if [ -z $REBALANCE ]; then
    echo "Need realance"
    exit
fi

curl -s -XPUT "http://$ES_HOST:$ES_PORT/_cluster/settings" -d "{
    \"transient\" : {
    	\"cluster.routing.allocation.cluster_concurrent_rebalance\": $REBALANCE
    }
}"
