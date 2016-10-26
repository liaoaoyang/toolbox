#!/bin/sh

LOAD_FILE_NAME=$1

if [ ! -f $LOAD_FILE_NAME ];then
	echo "No such file"
	exit
fi

MYSQL_PIDS=`ps -ef | grep mysql | awk '{print $2}'`
fsize=`ls -l $LOAD_FILE_NAME | awk '{print $5}'`

for pid in $MYSQL_PIDS
do
    fd=`lsof -p $pid | grep $LOAD_FILE_NAME | grep -vE "grep|sh -c" | awk '{print $4}' | grep -oP '\d+(?=r)'`

    if [ -f  /proc/$pid/fdinfo/$fd ];then
        read_pos=`cat /proc/$pid/fdinfo/$fd  | grep pos | awk "{print \\$2/$fsize*100\"%\"}"`
        echo $LOAD_FILE_NAME" "$read_pos
    fi
done
