#!/bin/bash

. ./setenv

oc extract secret/pull-secret -n openshift-config --keys=.dockerconfigjson --to=. --confirm

oc registry login --registry="${TARGET_REGISTRY_HOST}:${TARGET_REGISTRY_PORT}" --auth-basic="${TARGET_REGISTRY_USERNAME}:${TARGET_REGISTRY_PASSWORD}" --to=.dockerconfigjson

oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson

oc get machineconfigpool -w