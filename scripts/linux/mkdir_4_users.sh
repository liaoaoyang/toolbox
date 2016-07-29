#!/bin/sh

if [ `whoami`"x" != "rootx" ];then
	echo "You must run this script as root"
	exit
fi

BASE_DIR=`dirname $0`
USERS_FILENAME=$BASE_DIR/users

if [ -z $2 ];then
	echo "You need to specified base dir"
	exit
fi

USER_BASE_DIR=$2

if [ ! -z $3 ];then
	USERS_FILENAME=$3
fi

for user in `cat $USERS_FILENAME`
do
	if [ `grep -P '^$user:' /etc/passwd | wc -l` -eq 0 ];then
		echo "No such user $user exists"
		continue
	fi

	if [ `grep -P '^$user:' /etc/group| wc -l` -eq 0 ];then
		echo "No such group $user exists"
		continue
	fi

	mkdir -p $BASE_DIR/$user
	
	if [ -d $BASE_DIR/$user ];then
		chown $user:$user $BASE_DIR/$user
	fi

	if [ $? -ne 0 ];then
		echo "Failed to change owner of $BASE_DIR/$user"
	fi

done

