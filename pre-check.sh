#!/bin/bash

for val in $(cat 'config'); do eval $val; done
gp_name=${1:-${gp_name}}

./ldap-group.sh ${gp_name} > group-old.txt
cat group-new-ori.txt | sed -n 's/^/ /p' | sed -nr "/@${dc}\.com/s/.*\s+(\S+)@${dc}\.com.*/\1/p" > group-new.txt

./check-check.sh
