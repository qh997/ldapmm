#!/bin/bash

function init {
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
}

function ldap_read {
    ou=$1
    cn=$2
    ldapsearch -h "${server}" \
               -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
               -w "${password}" \
               -b "cn=${cn},ou=${ou},dc=${dc},dc=internal"
}

function ldap_group {
    ldap_read 'groups' ${gp_name}
}

function user_attr {
    local attr=$1
    local acct=$2

    local value=$(ldap_read 'people' ${acct} | sed -n "s/${attr}://p")
    if echo ${value} | grep '^:' >& /dev/null; then
        value=$(echo ${value} | sed -n 's/^:\s*//p' | base64 -d)
    fi
    printf "%-17s %s\n" "${acct}" "${value}"
}

init $@

OLD_IFS=$IFS
IFS=$(echo -en "\n\b")

gp_universe=$(ldap_group)

i=0
for line in ${gp_universe}; do
    for user in $(echo $line | sed -n 's/member: //p' \
                             | awk -F',' '{print $1}' \
                             | awk -F'=' '{print $2}'); do
        users[i++]=$user
    done
done

if [ ${chinese} ]; then
    for user in ${users[*]}; do
        user_attr 'sn' ${user}
    done
elif [ ${dispname} ]; then
    for user in ${users[*]}; do
        user_attr 'displayName' ${user}
    done
else
    for user in ${users[*]}; do
        echo ${user}
    done
fi

IFS=${OLD_IFS}
