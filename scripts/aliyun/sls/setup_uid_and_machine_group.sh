#!/bin/sh

uname -a | grep -i Linux 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Only for linux"
	exit 1
fi

UID=$1
MACHINE_GROUP=$2

echo $UID | grep -P '[1-9][0-9]+' 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Invalid uid"
	exit 1
fi

echo $MACHINE_GROUP | grep -P '\w+' 2>&1 >> /dev/null

if [ $? -ne 0 ];then
    echo "Invalid machine group"
	exit 1
fi

uid_file="/etc/ilogtail/user"$UID
echo "creating "$uid_file
sudo touch $uid_file
user_defined_id_file="/etc/ilogtail/user_defined_id"
echo "put "$MACHINE_GROUP" into "$user_defined_id_file
grep $MACHINE_GROUP $user_defined_id_file 2 >> /dev/null || \
    echo $MACHINE_GROUP | sudo tee -a $user_defined_id_file 
sudo /etc/init.d/ilogtaild stop
sudo /etc/init.d/ilogtaild start
