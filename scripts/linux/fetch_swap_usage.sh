#!/bin/sh

pids=`ls /proc/|grep '[0-9]\{1,\}'`

for pid in $pids
do
    if [ ! -f "/proc/"$pid"/smaps" ];then
        continue
    fi

    swap_uses=`awk '/^Swap:/ {SWAP+=$2}END{print SWAP" KB"}' "/proc/"$pid"/smaps"`
    proc=`ps -ef | grep " $pid " | grep -v grep | awk '{for(i=8;i<100;++i){printf "%s ",$i;}printf "\n"}'`
    echo $pid" "$swap_uses" "$proc
done
