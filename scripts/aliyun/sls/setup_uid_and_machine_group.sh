#!/bin/sh
#############
# usage:
# curl -s https://raw.githubusercontent.com/liaoaoyang/toolbox/master/scripts/aliyun/setup_uid_and_machine_group.sh | sh -s -- 1234567890 group1
# 
# read more at : https://help.aliyun.com/document_detail/49007.html

uname -a | grep -i Linux 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Only for linux"
	exit 1
fi

UID=$1
MACHINE_GROUP=$2

echo $UID | grep -P '^[1-9][0-9]+$' 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Invalid uid"
	exit 1
fi

echo $MACHINE_GROUP | grep -P '\w+' 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Invalid machine group"
	exit 1
fi

uid_file="/etc/ilogtail/users/"$UID
echo "creating "$uid_file
sudo touch $uid_file
user_defined_id_file="/etc/ilogtail/user_defined_id"
echo "put "$MACHINE_GROUP" into "$user_defined_id_file
grep $MACHINE_GROUP $user_defined_id_file 2 >> /dev/null || \
    echo $MACHINE_GROUP | sudo tee -a $user_defined_id_file 
sudo /etc/init.d/ilogtaild stop
sudo /etc/init.d/ilogtaild start
