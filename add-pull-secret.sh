#!/bin/bash

. ./setenv

TARGET_NAMESPACE=${1-"openshift-operators"}

oc create secret docker-registry ibm-entitlement-key \
    --docker-username=${TARGET_REGISTRY_USERNAME} \
    --docker-password=${TARGET_REGISTRY_PASSWORD} \
    --docker-server=${TARGET_REGISTRY_HOST}:${TARGET_REGISTRY_PORT} \
    --namespace=${TARGET_NAMESPACE}