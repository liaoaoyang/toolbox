#!/bin/sh

pids=`ls /proc/|grep '[0-9]\{1,\}'`
tmp_fn="/tmp/swap_usage_"`date +%s`

for pid in $pids
do
    if [ ! -f "/proc/"$pid"/smaps" ];then
        continue
    fi

    swap_uses=`awk '/^Swap:/ {SWAP_ORI+=$2}END{SWAP=SWAP_ORI;if(SWAP==""){SWAP_ORI=0;SWAP=0;};if(SWAP>1024*1024){UNIT="GB";SWAP=sprintf("%.2f",SWAP/1024.0/1024);}else if (SWAP>1024){UNIT="MB";SWAP=sprintf("%.2f",SWAP/1024.0);}else{UNIT="KB"};print "TAG "SWAP_ORI" GAT "SWA
P""UNIT}' "/proc/"$pid"/smaps"`
    proc=`ps -ef | grep " $pid " | grep -v grep | awk '{for(i=8;i<100;++i){printf "%s ",$i;}printf "\n"}'`
    echo $pid" "$swap_uses" "$proc >> $tmp_fn
done

if [ -f $tmp_fn ]; then
    cat $tmp_fn | sort -nrk3 | sed -r 's/TAG\s[0-9]+\sGAT\s//'
    rm -f $tmp_fn
fi
