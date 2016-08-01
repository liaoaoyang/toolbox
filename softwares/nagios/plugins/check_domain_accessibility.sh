#!/bin/sh

usage()
{
    echo "Usage: `basename $0` -d DOMAIN [-t TIMEOUT_S]"
    exit 3
}

do_curl()
{
	domain=$1
	timeout=$2

	result=`curl -I -s --connect-timeout $timeout $domain -w %{http_code} | tail -n1`

	if [ "$result""x" = "200x" ];then  
		return 0
	else
		return 1
	fi
}

do_ping()
{
	domain=$1
	timeout=$2
	package=4

	if [ ! -z $3 ];then
		if [ $3 -gt 0 ];then
			package=$3
		fi
	fi

	timeout=$(($timeout*$package))

	result=`ping -t $timeout -c $package $domain | grep '0.0% packet loss' | wc -l`

	if [ $result -eq 1 ]; then
		return 0
	else
		return 1
	fi
}


[ $# -eq 0 ] && usage

DOMAIN=''
TIMEOUT_S=1

while getopts "d:t::" OPTION
do
    case $OPTION in
        d)
            DOMAIN=$OPTARG
            ;;
        t)
			if [ ! -z $OPTARG ];then
            	TIMEOUT_S=$OPTARG
			fi
            ;;
        \?)                       
            usage
            ;;
    esac
done

if [ -z "$DOMAIN" ];then 
    echo "You must specify DOMAIN with -d option"
    exit 3
fi

$(do_curl $DOMAIN $TIMEOUT_S)
check_result=$?

if [ $check_result -ne 0 ];then
	$(do_ping $DOMAIN $TIMEOUT_S)
	check_result=$?
fi
  
if [ $check_result -eq 0 ];then  
	echo "$DOMAIN is reachable"
	exit 0
else  
	echo "$DOMAIN not reachable"
	exit 2
fi

