#!/bin/sh

usage()
{
    echo "Usage: `basename $0` -d DOMAIN [-t TIMEOUT_S -p y|n]"
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

    result=`ping -t $timeout -c $package $domain | egrep '\s0*\.?0%\spacket\sloss' | wc -l`

    if [ $result -eq 1 ];then
    	return 0
    else
    	return 1
    fi
}


[ $# -eq 0 ] && usage

DOMAIN=""
TIMEOUT_S=1
PING_FIRST=""

while getopts ":d:t::p::" OPTION
do
    case $OPTION in
        d)
            DOMAIN=$OPTARG
            ;;
        t)
            TIMEOUT_S=$OPTARG
            ;;
        p)
            PING_FIRST=$OPTARG
            ;;
        \?)                       
            usage
            ;;
    esac
done

if [ -z $TIMEOUT_S ];then
    TIMEOUT_S=1
fi

if [ $PING_FIRST"x" = "nx" ];then
    PING_FIRST="n"
else
    PING_FIRST="y"
fi

if [ -z "$DOMAIN" ];then 
    echo "You must specify DOMAIN with -d option"
    exit 3
fi

if [ $PING_FIRST = "y" ];then
    $(do_ping $DOMAIN $TIMEOUT_S)
else
    $(do_curl $DOMAIN $TIMEOUT_S)
fi

check_result=$?

if [ $check_result -ne 0 ];then
    if [ $PING_FIRST = "n" ];then
    	$(do_ping $DOMAIN $TIMEOUT_S)
    else
    	$(do_curl $DOMAIN $TIMEOUT_S)
    fi
    check_result=$?
fi
  
if [ $check_result -eq 0 ];then  
    echo "$DOMAIN is reachable"
    exit 0
else  
    echo "$DOMAIN not reachable"
    exit 2
fi

