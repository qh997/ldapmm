#!/bin/bash

ARGS=$(getopt -o m --long manager -n "$0" -- "$@")
eval set -- "$ARGS"
while true ; do
    case "$1" in
        -m|--manager) : ${manager:=1}; shift;;
        --) shift; break;;
        *) echo "Internal error."; exit 1;;
    esac
done

for val in $(cat 'config'); do eval $val; done
gp_name=${1:-${user_name}}

if [ -z $manager ]; then
    for name in $(ldapsearch -h "${server}" \
                             -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                             -w "${password}" \
                             -b "cn=${user_name},ou=people,dc=${dc},dc=internal" \
                  | sed -n 's/memberOf: //p' \
                  | awk -F',' '{print $1}' \
                  | awk -F'=' '{print $2}')
    do
        printf "%-15s\n" ${name}
    done
else
    for name in $(ldapsearch -h "${server}" \
                             -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                             -w "${password}" \
                             -b "cn=${user_name},ou=people,dc=${dc},dc=internal" \
                  | sed -n 's/managedObjects: //p' \
                  | awk -F',' '{print $1}' \
                  | awk -F'=' '{print $2}')
    do
        printf "%-15s\n" ${name}
    done
fi
