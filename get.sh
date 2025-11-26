#!/bin/bash

. ./setenv

oc ibm-pak get ${CASE_NAME} --version ${CASE_VERSION}
