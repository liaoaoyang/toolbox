#!/bin/sh

BASE_DIR=`dirname $0`

for i in `seq 60`
do
    d=`date +%Y%m%d -d "$i days ago"`
    dd=`date +%Y-%m-%d -d "$i days ago"`
    echo $d

    for p in `ls /foo/bar/logs/prefix*`
    do
        p=`echo $p | sed 's/:$//'`

        if [ ! -d $p ];then
            continue
        fi

        for f in `ls $p/others/access_log-$dd* 2>>/dev/null`
        do
            ls $f 
        done
    done
done

