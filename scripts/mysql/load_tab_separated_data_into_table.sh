#!/bin/sh

work_dir=$1
data_dir=$2
MYSQL_USERNAME=$3
MYSQL_PASSWORD=$4
MYSQL_HOST=$5
MYSQL_PORT=$6
MYSQL_DATABASE=$7
ibdata_file=$8
ibdata_file_max_size_gb=$9

if [ "x" == $work_dir"x" -o "x" == $data_dir"x" -o "x" == $MYSQL_USERNAME"x" -o "x" == $MYSQL_PASSWORD"x" -o "x" == $MYSQL_HOST"x" -o "x" == $MYSQL_PORT"x" -o "x" == $MYSQL_DATABASE"x" ];then
    echo "Usage: ./.load_tab_separated_data_into_table.sh work_dir data_dir MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST MYSQL_PORT MYSQL_DATABASE [ibdata_file] [ibdata_file_max_size_gb]"
fi

if [ ! -d $data_dir ];then
    echo "data_dir $data_dir not exits"
    exit
fi

ibdata_file_threshould=0
if [ "x" != $ibdata_file"x" ];then
    if [ "x" == $ibdata_file_max_size_gb"x" ];then
    	echo "need ibdata file max size gb"	
    	exit
    fi
    ibdata_file_threshould=$(($ibdata_file_max_size_gb * 1073741824))

    if [ ! -f $ibdata_file ];then
    	echo "ibdata file $ibdata_file not exists"
    	exit
    fi
fi

if [ ! -d $work_dir ];then
    mkdir -p $work_dir
fi

if [ $? -ne 0 ];then
    echo "Failed to create $work_dir"
    exit
fi

data_files=`ls $data_dir/*`
done_file=$work_dir/done
stop_file=$work_dir/stop
log_file=$work_dir/log

if [ ! -f $done_file ];then
    touch $done_file
fi

cd $work_dir

for data_file in $data_files
do
    if [ -f $stop_file ];then
        exit
    fi

    dst_fn=`basename $data_file`
    import_data_data_file=`echo $dst_fn | grep -oP ".+\.data(?=\.tgz)"`
    table_name=`echo $import_data_data_file | grep -oP ".+(?=\.data)"`

    if [ `grep -P $table_name"\." $done_file | wc -l` -ge 1 ];then
        continue
    fi

    if [ "x" != $ibdata_file"x" ];then
        ibfile_size=`ls -l $ibdata_file | cut -d ' ' -f 5`

    	if [ $ibfile_size -gt $ibdata_file_threshould ];then
            date>>$log_file
            echo $ibdata_file" reach size "$ibdata_file_threshould>>$log_file
            exit
    	fi
    fi

    echo $data_file>>$log_file
    cp $data_file ./$dst_fn
    tar -xzf ./$dst_fn
    load_sql="SET NAMES utf8;LOAD DATA LOCAL INFILE \"$work_dir/$import_data_data_file\" INTO TABLE $table_name"
	version_sql="SELECT VERSION()"
    if [ `mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "$version_sql" | grep "5.7" | grep -v grep | wc -l` -gt 0 ]; then 
        mysql  --local-infile=1 -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "$load_sql"
    else
         mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "$load_sql"
	fi

    if [ $? -gt 0 ];then
        echo "mysql return not 0">>$log_file
        exit
    fi

    rm -f ./$import_data_data_file ./$dst_fn
    echo $dst_fn>>$done_file
done
