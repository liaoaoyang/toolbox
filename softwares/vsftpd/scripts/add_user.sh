#!/bin/sh

#
# Thx to article: https://wsgzao.github.io/post/vsftpd/
#

if [ ! -f /etc/centos-release ]; then
    echo "Not CentOS"
    exit 1
fi

BACKUP_SUFFIX=`date +%Y%m%d%H%M%S`
SCRIPT_FILENAME=`readlink -f $0`
SCRIPT_PATH=`dirname $SCRIPT_FILENAME`
BASE_PATH=`dirname $SCRIPT_PATH`

if [ ! -f $BASE_PATH"/conf/vsftpd.conf" ]; then
    echo "No config file "$BASE_PATH"/conf/vsftpd.conf"
    exit 1
fi

CONF_PATH=$BASE_PATH"/conf"

if [ `whoami` != "root" ]; then
    echo "You must be root user"
    exit 1
fi

if [ `rpm -qa | grep -P 'vsftpd-\d' | wc -l` -lt 1 ]; then
    echo "No vsftpd, try run:"
    echo "    yum install -y vsftpd"
    echo "first"
    exit 1
fi

if [ `rpm -qa | grep -P 'db4-\d' | wc -l` -lt 1 ]; then
    echo "No vsftpd, try run:"
    echo "    yum install -y db4"
    echo "first"
    exit 1
fi

if [ `rpm -qa | grep -P 'db4-utils-\d' | wc -l` -lt 1 ]; then
    echo "No vsftpd, try run:"
    echo "    yum install -y db4-utils"
    echo "first"
    exit 1
fi

PASSWORD_FILENAME="/etc/vsftpd/vuser_passwd.txt"

if [ ! -f `wc -l $PASSWORD_FILENAME` ]; then
    touch $PASSWORD_FILENAME
fi

PASSWORD_FILE_LINE_COUNT=`wc -l $PASSWORD_FILENAME | awk '{print $1}'`

if [ $(($PASSWORD_FILE_LINE_COUNT%2)) -eq 1 ]; then
    echo "Password file "$PASSWORD_FILENAME" line count is odd number"
    exit 1
fi

cp $PASSWORD_FILENAME $PASSWORD_FILENAME.$BACKUP_SUFFIX

USERNAME=$1

if [ -z $USERNAME ]; then
    echo "Need username!"
    exit 1
fi

PASSWORD=$2

if [ -z $PASSWORD ]; then
    echo "Need password"
    exit 1
fi

LOCAL_ROOT=$3

if [ -z $LOCAL_ROOT ]; then
    echo "Need local root!"
    exit 1
fi

USENANE_LINE_NO=`grep -on "^"$USERNAME"$" $PASSWORD_FILENAME | awk -F':' '{print $1}'`

if [ $USENANE_LINE_NO"x" == "x" ]; then
    echo $USERNAME >> $PASSWORD_FILENAME
    echo $PASSWORD >> $PASSWORD_FILENAME
else
    echo "Username $USERNAME exists in line $PASSWORD_FILE_LINE_COUNT"
    exit 1
fi

# reload virtual user name password database
cp /etc/vsftpd/vuser_passwd.db /etc/vsftpd/vuser_passwd.db.$BACKUP_SUFFIX
db_load -T -t hash -f $PASSWORD_FILENAME /etc/vsftpd/vuser_passwd.db

# add virtual user and create user dir 
VUSER_CONF_PATH="/etc/vsftpd/vuser_conf"
mkdir -p $VUSER_CONF_PATH 
cp $CONF_PATH/user_template $VUSER_CONF_PATH/$USERNAME
sed -i "s/LOCAL_ROOT/$LOCAL_ROOT/" $VUSER_CONF_PATH/$USERNAME
mkdir -p $LOCAL_ROOT

# reconfigure pam config
if [ -f /etc/pam.d/vsftpd ]; then
    cp /etc/pam.d/vsftpd /etc/pam.d/vsftpd.$BACKUP_SUFFIX
fi

cp $CONF_PATH/vsftpd /etc/pam.d/

# reconfigure vsftpd config
if [ -f /etc/vsftpd/vsftpd.conf ]; then
    cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.$BACKUP_SUFFIX
fi

cp $CONF_PATH/vsftpd.conf /etc/vsftpd/

service vsftpd restart
