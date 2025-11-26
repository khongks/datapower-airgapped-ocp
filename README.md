# Prerequisites

## Image Registry

1. Create image registry using Tekton pipeline.

1. Expose
    ```
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    ```

1. Get URL
    ```
    oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}'
    ```
    ```
    default-route-openshift-image-registry.apps.itz-9cgm8h.infra01-lb.tok04.techzone.ibm.com
    ```

1. Login
    ```
    podman login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.itz-9cgm8h.infra01-lb.tok04.techzone.ibm.com
    ```

## Tools

- oc cli
- podman
- ibm-pak

- ibm entitlement key

## Mirror

1. Get
    ```
    ./get.sh
    ```

1. Generate mirror manifest
    ```
    ./gen-manifest.sh
    ```

1. Mirror
    ```
    ./mirror.sh
    ```

## Setup entitlement key

See [here](https://www.ibm.com/docs/en/cloud-paks/cp-integration/16.1.2?topic=fayekoi-finding-applying-your-entitlement-key-by-using-cli-online-installation)


1. Add global pull secret
    ```
    ./add-global-pull-secret.sh
    ```

1. Add insecure registry
    ```
    oc edit image.config.openshift.io cluster

    spec:
      registrySources:
        insecureRegistries:
          - artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com:443
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

1. Create namespace
    ```
    oc new-project datapower
    ```

1. Add entitlment key to namespace
    ```
    ./add-pull-secret.sh datapower
    ```

1. Install Operator
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
    ```
    oc apply -f datapower-sub.yaml
    ```


## Install DataPower Service

1. Create admin credential
    ```
    oc create secret generic admin-credentials -n datapower \
       --from-literal=password=Passw0rd 
    ```

1. Create config map
    ```
    ./create-configmap.sh
    ```

1. Install DataPower Service
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
    ```
    oc get pods -n datapower -l app.kubernetes.io/name=datapower
    ```


## Post instalation

1. Create Kubernetes Service for WebGUI and Hello World service
    ```
    oc apply -f datapower-svc.yaml
    ```

1. Create route for WebGUI
    ```
    oc apply -f datapower-route-webgui.yaml
    ```

1. Create route for Hello World service
    ```
    oc apply -f datapower-route-hello-world.yaml
    ```

1. Test WebGUI via browser
    ```
    https://webgui-dp.apps.apps.cpikks.cp.fyre.ibm.com
    ```

1. Test Hello World service
    ```
    curl -k https://helloworld-dp.apps.apps.cpikks.cp.fyre.ibm.com/users | jq -r .
    ```