#!/bin/sh

MYSQL_USERNAME=$1
MYSQL_PASSWORD=$2
MYSQL_HOST=$3
MYSQL_PORT=$4
MYSQL_DATABASE=$5
TABLE_KEYWORD=$6

if [ "x" == $MYSQL_USERNAME"x" -o "x" == $MYSQL_PASSWORD"x" -o "x" == $MYSQL_HOST"x" -o "x" == $MYSQL_PORT"x" -o "x" == $MYSQL_DATABASE"x" ];then
        echo "Usage: ./dump_data_into_tab_separated_file.sh MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST MYSQL_PORT MYSQL_DATABASE [TABLE_KEYWORD]"
        exit
fi

function show_create_table() {
    table_name=$1
    sql="SET NAMES utf8;SHOW CREATE TABLE "$table_name
    mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT $MYSQL_DATABASE -N -e "$sql\G" | grep -A 100 'CREATE' | sed 's/Create Table: //' | sed 's/AUTO_INCREMENT=[0-9]\{1,\}/AUTO_INCREMENT=1/'
    printf ";"
}

tables=`mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT $MYSQL_DATABASE -N -e "SHOW TABLES"`

for table in $tables
do
    if [ "x" == $TABLE_KEYWORD"x" ];then
        show_create_table $table
        continue
    fi

    if [ `echo $table | grep -E "$TABLE_KEYWORD" | wc -l` -ge 1 ];then
        show_create_table $table
    fi
done
