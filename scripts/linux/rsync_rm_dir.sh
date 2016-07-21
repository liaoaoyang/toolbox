#!/bin/sh

function do_delete()
{
		if [ -d /tmp/rsync_delete ];then
			rm -rf /tmp/rsync_delete
		fi

		mkdir -p /tmp/rsync_delete && rsync --delete-before -a -H -v --progress --stats /tmp/rsync_delete/ $1
}

dir_to_delete=$1

if [ -z $dir_to_delete ];then
	exit
fi

if [ ! -d $dir_to_delete ];then
	exit
fi

while true; do
    read -p "Do you wish to delete $dir_to_delete?" yn
    case $yn in
        [Yy]* ) do_delete $dir_to_delete; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


