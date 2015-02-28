#!/bin/bash

function init {
    ARGS=$(getopt -o mv --long manager --long verbose -n "$0" -- "$@")
    eval set -- "$ARGS"
    while true ; do
        case "$1" in
            -m|--manager) : ${manager:=1}; shift;;
            -v|--verbose) : ${verbose:=1}; shift;;
            --) shift; break;;
            *) echo "Internal error."; exit 1;;
        esac
    done

    for val in $(cat 'config'); do eval $val; done
    user_name=${1:-${user_name}}
}

function ldap_read {
    ou=$1
    cn=$2
    ldapsearch -h "${server}" \
               -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
               -w "${password}" \
               -b "cn=${cn},ou=${ou},dc=${dc},dc=internal"
}

function ldap_user {
    ldap_read 'people' ${user_name}
}

#sudo route add 202.107.117.23 gw 10.1.42.1

init $@

OLD_IFS=$IFS
IFS=$(echo -en "\n")

user_universe=$(ldap_user)

if [ ${verbose} ]; then
    echo ${user_universe}
elif [ ${manager} ]; then
    echo ${user_universe} | sed -n 's/.*managedObjects.*: //ip' \
                          | awk -F',' '{print $1}' \
                          | awk -F'=' '{print $2}' \
                          | sort
else
    echo ${user_universe} | sed -n 's/memberOf: //p' \
                          | awk -F',' '{print $1}' \
                          | awk -F'=' '{print $2}' \
                          | sort
fi

IFS=${OLD_IFS}

#sudo route del 202.107.117.23 gw 10.1.10.254
