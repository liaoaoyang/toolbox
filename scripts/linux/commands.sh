#!/bin/sh

function allow_port() {
    port=$1

    if [ -z $port ];then
        echo "Need port number"
        return
    fi

    line_no=`/sbin/iptables -L -n --line-number | grep -E "ACCEPT" | grep ":"$port | awk '{print $1}'`

    if [ ! -z $line_no ];then
        return
    fi

    /sbin/iptables -L -n --line-number | grep -E "DROP" | grep ":"$port | awk '{print $1}' | xargs -i /sbin/iptables -D INPUT {}

    /sbin/iptables -I INPUT 1 -p tcp -m tcp --dport $port -j ACCEPT
}

function deny_port() {
    port=$1

    if [ -z $port ];then
        echo "Need port number"
        return
    fi

    line_no=`/sbin/iptables -L -n --line-number | grep -E "DROP" | grep ":"$port | awk '{print $1}'`

    if [ ! -z $line_no ];then
            return
    fi


    /sbin/iptables -L -n --line-number | grep -E "ACCEPT" | grep ":"$port | awk '{print $1}' | xargs -i /sbin/iptables -D INPUT {}

    if [ -z $line_no ];then
        /sbin/iptables -I INPUT 1 -p tcp -m tcp --dport $port -j DROP
        return
    fi
}
