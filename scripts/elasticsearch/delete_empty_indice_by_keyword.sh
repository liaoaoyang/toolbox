#!/bin/sh

BASE_PATH=`dirname $0`

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

ES_KEYWORD=$3

if [ -z $ES_KEYWORD ]; then
    echo "Need keyword"
    exit
fi

if [ -z $ES_KEYWORD ]; then
    indexes=`curl  -s "http://$ES_HOST:$ES_PORT/_cat/shards" | grep UNASSIGNED | awk '{print $1}' | sort | uniq`
else
    indexes=`curl  -s "http://$ES_HOST:$ES_PORT/_cat/shards" | grep UNASSIGNED | grep $ES_KEYWORD |awk '{print $1}' | sort | uniq`
fi

for index in $indexes
do
    echo $index
    docs=`php $BASE_PATH/get_indice_doc_count.php $index`

    if [ $? -ne 0 ]; then
        echo "Failed to get $index docs"
        continue
    fi

    if [ $docs -gt 0 ]; then
        echo "Can not delete $index while {$docs} docs exists"
        continue
    fi

    RESPONSE=`curl -s -w "HTTP_RESPONSE_CODE:%{http_code}" -XDELETE "http://$ES_HOST:$ES_PORT/$index?master_timeout=120s"`

    if [ `echo $RESPONSE | grep -oP '(?<=HTTP_RESPONSE_CODE:)[0-9]+'`"x" != '200x' ];then
        echo $RESPONSE
    else
        echo "$index DELETED"
    fi

    sleep 2
done
