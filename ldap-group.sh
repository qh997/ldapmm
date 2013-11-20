#!/bin/bash

ARGS=$(getopt -o cd --long chinese --long display-name -n "$0" -- "$@")
eval set -- "$ARGS"
while true ; do
    case "$1" in
        -c|--chinese) : ${chinese:=1}; shift;;
        -d|--display-name) : ${dispname:=1}; shift;;
        --) shift; break;;
        *) echo "Internal error."; exit 1;;
    esac
done

for val in $(cat 'config'); do eval $val; done
gp_name=${1:-${gp_name}}

for name in $(ldapsearch -h "${server}" \
                         -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                         -w "${password}" \
                         -b "cn=${gp_name},ou=groups,dc=${dc},dc=internal" \
              | sed -n 's/member: //p' \
              | awk -F',' '{print $1}' \
              | awk -F'=' '{print $2}')
do
    if [ ! -z ${chinese} ]; then
        cn_name=$(ldapsearch -h "${server}" \
                             -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                             -w "${password}" \
                             -b "cn=${name},ou=people,dc=${dc},dc=internal" \
                  | sed -n 's/sn://p')
        if echo ${cn_name} | grep '^:' >& /dev/null; then
            cn_name=$(echo ${cn_name} | sed -n 's/^:\s*//p' | base64 -d)
        fi
        printf "%-17s %s\n" "${name}" "${cn_name}"
    elif [ ! -z ${dispname} ]; then
        dp_name=$(ldapsearch -h "${server}" \
                             -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                             -w "${password}" \
                             -b "cn=${name},ou=people,dc=${dc},dc=internal" \
                  | sed -n 's/displayName://p')
        if echo ${dp_name} | grep '^:' >& /dev/null; then
            dp_name=$(echo ${dp_name} | sed -n 's/^:\s*//p' | base64 -d)
        fi
        printf "%-17s %s\n" "${name}" "${dp_name}"
    else
        echo ${name}
    fi
done
