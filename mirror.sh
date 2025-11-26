#!/bin/bash

. ./setenv


oc image mirror -f ~/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/images-mapping.txt --filter-by-os '.*' -a $REGISTRY_AUTH_FILE --insecure --skip-multiple-scopes --max-per-registry=1
