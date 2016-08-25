#!/bin/bash

################################################
# config sample                                #
# find|/home/www/logs/|7|2|keep,save           #
#                                              #
# separator is |                               #
# [find] remove type, keep it                  #
# [/home/www/logs/] log path                   #
# [7] rm files before 7 days                   #
# [2] tar files before 2 days                  #
# [keep,save] keep file name with keep or save #
################################################

BASEDIR=$(dirname $0)
config_path=$BASEDIR/log_tar_remove.conf

if [ ! -f $config_path ];then
    exit
fi

echo "*********************************************************************"
date

while read -r line
    do
        log_type=`echo $line | awk -F '|' '{print $1}'`

        if [ "$log_type"x = "find"x ];then
            log_path=`echo $line | awk -F '|' '{print $2}'`
            if [ ! -d $log_path ];then
                continue
            fi
            log_ctime=`echo $line | awk -F '|' '{print $3}'`
            log_tar_time=`echo $line | awk -F '|' '{print $4}'`
            log_exclude=`echo $line | awk -F '|' '{print "fake_file_name,"$5}'|tr "," "|"|sed 's/|$//'`
            if [ ! -z $log_tar_time ];then
                file_list=`find ${log_path} -mtime +${log_tar_time} -type f | grep -vE "${log_exclude}" | grep -v tgz`
                for f in $file_list
                do
                     if [ -f $f".tgz" ];then
                         continue
                     fi

                     echo "taring "$f
                     cd `dirname $f`
                     tar -czf `basename $f`".tgz" `basename $f`
                     if [ $?"x" = "0x" ];then
                         echo "remove "$f
                         ls $f | xargs rm -f
                     fi
                done
            fi

            find ${log_path} -mtime +${log_ctime} -type f | grep -vE "${log_exclude}" | xargs rm -f
        fi

    done < $config_path
