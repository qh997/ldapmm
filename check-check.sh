#!/bin/bash

for val in $(cat 'config'); do eval $val; done
o_names=$(cat group-old.txt)
n_names=$(cat group-new.txt)

function display_name {
    local user_name=$1
    dp_name=$(ldapsearch -h "${server}" \
                         -D "cn=${account}, ou=people, dc=${dc}, dc=internal" \
                         -w "${password}" \
                         -b "cn=${user_name},ou=people,dc=${dc},dc=internal" \
              | sed -n 's/displayName://p')
    if echo ${dp_name} | grep '^:' >& /dev/null; then
        dp_name=$(echo ${dp_name} | sed -n 's/^:\s*//p' | base64 -d)
    fi

    echo ${dp_name}
}

for o_name in ${o_names}
do
    found=0
    for n_name in ${n_names}
    do
        if [ ${o_name} == ${n_name} ]; then
            found=1
            break
        fi
    done

    if [ ${found} -eq 0 ]; then
        dp_name=$(display_name ${o_name})
        if [ "${dp_name}" == "${o_name}@${dc}.com" ]; then
            echo " - ${o_name}"
        else
            printf " - %-17s %s\n" "${o_name}" "${dp_name}"
        fi
    else
        echo "   ${o_name}"
    fi
done

for n_name in ${n_names}
do
    found=0
    for o_name in ${o_names}
    do
        if [ ${n_name} == ${o_name} ]; then
            found=1
            break
        fi
    done

    if [ ${found} -eq 0 ]; then
        dp_name=$(display_name ${n_name})
        if [ "${dp_name}" == "${n_name}@${dc}.com" ]; then
            echo " + ${n_name}"
        else
            printf " + %-17s %s\n" "${n_name}" "${dp_name}"
        fi
    fi
done
