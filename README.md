# Instructions

Guide to do airgapped/offline installation of DataPower for OpenShift. 

## Prequisite

1. Installed Artifactory as the image registry. Create a repository called `ibm`. This will be used as repository name. Get the username and generate a token.

1. Obtain IBM entitlement key following instructions [here](https://www.ibm.com/docs/en/cloud-paks/cp-integration/16.1.2?topic=fayekoi-finding-applying-your-entitlement-key-by-using-ui-online-installation)

1. Install tools on the Bastion Linux machine
    - OpenShift CLI
        ```
        wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
        ```
        ###### Example for version 4.18.27
        ```
        wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.18.27/openshift-client-linux-4.18.27.tar.gz
        ```
        Uncompress and copy the file into `/usr/local/bin`
        ```
        tar xvf openshift-client-linux.tar.gz
        chmod a+x oc
        mv oc /usr/local/bin
        oc version
        ```
    
    - Podman CLI, following instructions [here](https://podman.io/docs/installation) 


    - IBM Catalog Management Plug-in (ibm-pak) [here](https://github.com/IBM/ibm-pak)    
        ```
        wget https://github.com/IBM/ibm-pak/releases/oc-ibm_pak-linux-amd64.tar.gz
        tar xvfz oc-ibm_pak-linux-amd64.tar.gz
        chmod a+x oc-ibm_pak-linux-amd64
        mv oc-ibm_pak-linux-amd64 /usr/local/bin/oc-ibm_pak
        oc ibm-pak
        ```

## Setup environment

1. Clone the repository
    ```
    git clone https://github.com/khongks/datapower-airgapped-ocp.git
    ```

1. Setup environment. Create a file called `setenv` and make it executable `chmod a+x setenv`. Setup the following environment variables.
    ###### setenv
    ```
    ## The values are obtained this link: https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-datapower-operator
    export CASE_NAME=<operator-name>
    export CASE_VERSION=<operator-version>

    export TARGET_REGISTRY_USERNAME=<artifactory-username>
    export TARGET_REGISTRY_PASSWORD=<artifactory-password>
    export TARGET_REGISTRY_HOST=<artifactory-hostname>
    export TARGET_REGISTRY_PORT=<artifactory-port>
    export TARGET_REGISTRY_REPO=<repository-name>

    export TARGET_REGISTRY=${TARGET_REGISTRY_HOST}:${TARGET_REGISTRY_PORT}/${TARGET_REGISTRY_REPO}
    
    ## Use this line if you are using docker
    # export REGISTRY_AUTH_FILE=$HOME/.docker/config.json.
    
    ## Use this line if you are using podman, we are using podman in our guide.
    export REGISTRY_AUTH_FILE=$HOME/.config/containers/auth.json
    ```
    Example values:
    ```
    export CASE_NAME=ibm-datapower-operator
    export CASE_VERSION=1.16.0

    export TARGET_REGISTRY_HOST=artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com
    export TARGET_REGISTRY_PORT=443
    export TARGET_REGISTRY_REPO=ibm
    ```

1. Add Artifactory as insecure registry (because my instance is not TLS enabled)
    ```
    oc edit image.config.openshift.io cluster
    ```
    ###### Insert the following
    ```
    spec:
      registrySources:
        insecureRegistries:
          - artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443
    ```

1. Login to IBM Cloud Pak Registry
    ```
    podman login --authfile $HOME/.config/containers/auth.json cp.icr.io -u cp -p <password>
    ```

1. Login to Artifactory
    ```
    podman login --authfile $HOME/.config/containers/auth.json --tls-verify=false https://artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com/artifactory/ibmrepo/ -u <username> -p <password>
    ```
    ###### Check the `$HOME/.config/containers/auth.json`
    ```
    {
        "auths": {
            "artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com": {
                "auth": "<encoded binary>"
            },
            "cp.icr.io": {
                "auth": "<encoded binary>"
            }
        }
    } 
    ```

## Mirror image

1. Get by CASE NAME and CASE VERSION
    ```
    ./get.sh
    ```
    ###### Output:
    ```
    oc ibm-pak get ibm-datapower-operator --version 1.16.0
    CASE repository: IBM Cloud-Pak Github Repo (https://github.com/IBM/cloud-pak/raw/master/repo/case/)
    Downloading and extracting the CASE ...
    - Success
    Retrieving CASE version ...
    - Success
    Validating the CASE spec version ...
    - Success
    Validating the CASE signature ...
    Validating the signature for the ibm-datapower-operator CASE...
    - Success
    Creating inventory ...
    - Success
    Finding inventory items
    - Success
    Resolving inventory items ...
    Parsing inventory items
    - Success
    Validating the CASE ...
    - Success
    Download of CASE: ibm-datapower-operator, version: 1.16.0 is complete

    Generating ComponentSetConfig of CASE: ibm-datapower-operator, version: 1.16.0 to /root/.ibm-pak/data/cases/ibm-datapower-operator/1.16.0/component-set-config.yaml is complete
    ```

1. Generate mirror manifest
    ```
    ./gen-manifest.sh
    ```
    ###### Output:
    ```
    ibm-datapower-operator
    1.16.0
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443/ibm
    oc ibm-pak generate mirror-manifests ibm-datapower-operator --version 1.16.0 artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443/ibm --filter ibmdpNonprod
    ibm-datapower-operator-1.16.0  done
    Generating mirror manifests of CASE: ibm-datapower-operator, version: 1.16.0 is complete

    Next steps

    - To mirror the images:

    oc image mirror -f /root/.ibm-pak/data/mirror/ibm-datapower-operator/1.16.0/images-mapping.txt --filter-by-os '.*' -a $REGISTRY_AUTH_FILE --insecure --skip-multiple-scopes --max-per-registry=1
    ```

1. Mirror the image to Artifactory. This process will take at least 60 mins to complete.
    ```
    ./mirror.sh
    ```
    ###### Output planning:
    ```
    ...
    phase 0:
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cpopen/datapower-operator-catalog blobs=35  mounts=0 manifests=5  shared=0
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cpopen/datapower-monitor          blobs=18  mounts=0 manifests=2  shared=0
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cpopen/datapower-operator-bundle  blobs=288 mounts=0 manifests=80 shared=0
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cp/datapower/datapower-nonprod    blobs=782 mounts=0 manifests=67 shared=231
    phase 1:
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/integration/datapower/datapower-limited      blobs=237 mounts=216 manifests=21 shared=216
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cpopen/datapower-operator-conversion-webhook blobs=296 mounts=19  manifests=72 shared=52
    phase 2:
    artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443 ibm/cpopen/datapower-operator blobs=402 mounts=52 manifests=80 shared=52

    info: Planning completed in 49.63s
    ...
    ```

## Setup entitlement key

You need to obtain entitlement key in previous step.

1. Add global pull secret. This command updates the global pull secret called `pull-secret` in namespace `openshift-config`.
    ```
    ./add-global-pull-secret.sh
    ```

## Install DataPower Operator

1. Add image content source policy
    ```
    . ./setenv
    oc apply -f ~/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/image-content-source-policy.yaml
    ```

1. Add catalog source
    ```
    . ./setenv
    oc apply -f ~/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/catalog-sources.yaml
    ```

1. Create `datapower` namespace
    ```
    oc new-project datapower
    ```

1. Add secret for entitlment key to `datapower` namespace
    ```
    ./add-pull-secret.sh datapower
    ```

1. Install Operator
    ```
    oc apply -f yaml/datapower-sub.yaml
    ```
    ###### yaml/datapower-sub.yaml
    ```
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: datapower-operator
      namespace: datapower
    spec:
      channel: v1.16
      installPlanApproval: Automatic
      name: datapower-operator
      source: ibm-datapower-operator-catalog
      sourceNamespace: openshift-marketplace
    ```

## Install DataPower Service

1. Create secret for admin credential
    ```
    oc create secret generic admin-credentials -n datapower \
       --from-literal=password=Passw0rd 
    ```

1. Create config map for configuration in folder `config`. There are two domains in this example `default` and `hello-world`.
    ```
    ./create-configmap.sh
    ```
    ###### The `config` folder
    ```
    # tree config
    config
    ├── auto-startup.cfg
    └── hello-world
        └── hello-world.cfg
    ```
    ###### Two configmap(s) created
    ```
    # oc get cm -n datapower | grep cfg
    auto-startup-cfg                             1      37h
    hello-world-cfg                              1      37h
    ```

1. Install DataPower Service.
    ```
    oc apply -f yaml/datapower.yaml
    ```
    ###### Check the pod is running
    ```
    # oc get pods -n datapower -l app.kubernetes.io/name=datapower
    NAME                     READY   STATUS    RESTARTS   AGE
    my-datapower-gateway-0   1/1     Running   0          37h
    ```
    ###### yaml/datapower.yaml
    ```
    apiVersion: datapower.ibm.com/v1beta3
    kind: DataPowerService
    metadata:
      name: my-datapower-gateway
      namespace: datapower
    spec:
      license:
        accept: true
        use: nonproduction
        license: L-EYGU-PVGRBC
      replicas: 1
      resources:
        limits:
          memory: 8Gi
        requests:
          cpu: 1
          memory: 4Gi
      version: 10.6-lts
      users:
        - name: admin
          accessLevel: privileged
          passwordSecret: admin-credentials
        domains:
        - name: 'default'
          dpApp:
          config:
        - 'auto-startup-cfg'
    - name: 'hello-world'
        dpApp:
        config:
        - 'hello-world-cfg'
    ```
    Note that you have to update the following fields for your needs. See [license guide](https://www.ibm.com/docs/en/datapower-operator/1.16.0?topic=guides-licenses)
    - spec.license.use
    - spec.license.license
    - spec.version

## Post instalation

1. Create Kubernetes Service for WebGUI and Hello World service
    ```
    oc apply -f datapower-svc.yaml
    ```
    ###### yaml/datapower-svc.yaml
    ```
    apiVersion: v1
    kind: Service
    metadata:
      name: datapower-svc
      namespace: datapower
    spec:
      ports:
        - name: webgui
          protocol: TCP
          port: 9090
          targetPort: 9090
        - name: helloworld
          protocol: TCP
          port: 8000
          targetPort: 8000
      selector:
        app.kubernetes.io/name: datapower
      type: ClusterIP
    ```

1. Create route for WebGUI
    ```
    . ./get-ocp-domain.sh 
    cat yaml/datapower-route-webgui.yaml | envsubst | oc apply -f -
    ```
    ###### yaml/datapower-route-webgui.yaml
    ```
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
      name: webgui
      namespace: datapower
    spec:
      host: webgui-dp.${OCP_DOMAIN}
      port:
        targetPort: 9090
      tls:
        termination: passthrough
      to:
        kind: Service
        name: datapower-svc
        weight: 100
      wildcardPolicy: None
    ```

1. Create route for Hello World service
    ```
    . ./get-ocp-domain.sh
    cat yaml/datapower-route-hello-world.yaml | envsubst | oc apply -f - 
    ```
    ###### yaml/datapower-route-hello-world.yaml
    ```
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
      name: helloworld
      namespace: datapower
    spec:
      host: helloworld-dp.${OCP_DOMAIN}
      port:
        targetPort: 8000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
      to:
        kind: Service
        name: datapower-svc
        weight: 100
      wildcardPolicy: None
    ```

1. Test WebGUI via browser
    ```
    https://webgui-dp.${OCP_DOMAIN}
    ```

1. Test Hello World service
    ```
    curl -k https://helloworld-dp.${OCP_DOMAIN}/users | jq -r .
    ```