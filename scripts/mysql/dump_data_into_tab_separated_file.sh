#!/bin/sh

DATA_DIR=$1
MYSQL_USERNAME=$2
MYSQL_PASSWORD=$3
MYSQL_HOST=$4
MYSQL_PORT=$5
MYSQL_DATABASE=$6
TABLE_KEYWORD=$7

if [ "x" == $DATA_DIR"x" -o "x" == $MYSQL_USERNAME"x" -o "x" == $MYSQL_PASSWORD"x" -o "x" == $MYSQL_HOST"x" -o "x" == $MYSQL_PORT"x" -o "x" == $MYSQL_DATABASE"x" -o "x" == $TABLE_KEYWORD"x" ];then
    	echo "Usage: ./dump_data_into_tab_separated_file.sh DATA_DIR MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST MYSQL_PORT MYSQL_DATABASE TABLE_KEYWORD"
    	exit
fi

if [ ! -d $DATA_DIR ];then
    	mkdir -p $DATA_DIR
fi

function dump_and_compress_table() {
    table_name=$1
    sql="SELECT * FROM "$table_name
    mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT $MYSQL_DATABASE -N -e "$sql" > $DATA_DIR"/"$table_name".data"
    cd $DATA_DIR

    if [ -f $table_name".data.tgz" ];then
        rm -f $table_name".data.tgz"
    fi

    tar -czf $table_name".data.tgz" $table_name".data" && rm -f $table_name".data"
}

tables=`mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -h$MYSQL_HOST -P$MYSQL_PORT $MYSQL_DATABASE -N -e "SHOW TABLES"`

for table in $tables
do
    if [ ! -z $TABLE_KEYWORD  -a `echo $table | grep -E "$TABLE_KEYWORD" | grep -v grep | wc -l` -ge 1 ];then
        dump_and_compress_table $table
    	continue
    fi

    dump_and_compress_table $table
done
