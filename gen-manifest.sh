#!/bin/bash

. ./setenv

echo $CASE_NAME
echo $CASE_VERSION
echo $TARGET_REGISTRY

echo "oc ibm-pak generate mirror-manifests $CASE_NAME --version $CASE_VERSION $TARGET_REGISTRY --filter ibmdpNonprod"

oc ibm-pak generate mirror-manifests $CASE_NAME --version $CASE_VERSION $TARGET_REGISTRY --filter ibmdpNonprod
