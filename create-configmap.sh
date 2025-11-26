#!/bin/sh

. ./setenv

DP_NAMESPACE=${1-"datapower"}

find config -name '*.cfg' -exec sh -c '

    for file do
        FILE_VAR=$(basename "$file" .cfg)
        NEW_VAR=$(echo "$FILE_VAR" | tr '[:upper:]' '[:lower:]')
        echo "$NEW_VAR"
        oc delete configmap $NEW_VAR-cfg --ignore-not-found=true -n '"${DP_NAMESPACE}"'
        oc create configmap $NEW_VAR-cfg --from-file=$file -n '"${DP_NAMESPACE}"'
    done' sh {} +