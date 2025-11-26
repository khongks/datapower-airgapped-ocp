# Setup Artifactory for testing

This guide provide steps to setup Artifactory on OpenShift for airgapped installation.

1. Generate Master key and Join key

    ```
    export MASTER_KEY=$(openssl rand -hex 32)
    echo ${MASTER_KEY}
    export JOIN_KEY=$(openssl rand -hex 32)
    echo ${JOIN_KEY}
    ```

1. Create namespace for installation
    ```
    oc new-project artifactory
    ```

1. Add Security `anyuid` to service account `artifactory` in namespace
    ```
    oc adm policy add-scc-to-user anyuid -z artifactory -n artifactory
    ```

1. Patch block storage class as default
    ```
    oc patch storageclass ocs-storagecluster-ceph-rbd \
    -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}' \
    --type='merge'
    ```

1. Install using Helm chart
    ```
    helm upgrade --install artifactory \
        --set artifactory.masterKey=${MASTER_KEY} \
        --set artifactory.joinKey=${JOIN_KEY} \
        --set artifactory.persistence.storageClassName=ocs-storagecluster-cephfs \
        --set artifactory.persistence.size=300Gi \
        --set artifactory.podSecurityContext.enabled=true \
        --set artifactory.podSecurityContext.runAsUser=null \
        --set artifactory.podSecurityContext.fsGroup=null \
        --set artifactory.containerSecurityContext.enabled=true \
        --set artifactory.containerSecurityContext.runAsUser=null \
        --set artifactory.service.contextPath=/ \
        --namespace artifactory --create-namespace \
        jfrog/artifactory
    ```

1. Create route to Artifactory
    ```
    oc apply -f artifactory-route.yaml
    ```
    ###### artifactory-route.yaml
    ```
    apiVersion: route.openshift.io/v1
    kind: Route
    metadata:
    annotations:
        haproxy.router.openshift.io/timeout: 120m
        haproxy.router.openshift.io/hsts: "True"
        haproxy.router.openshift.io/timeout-http-request: "10m"
        haproxy.router.openshift.io/timeout-http-keep-alive: "5m"
        haproxy.router.openshift.io/timeout-server: "10m"
        haproxy.router.openshift.io/timeout-client: "10m"
        haproxy.router.openshift.io/timeout-connect: "10m"
        haproxy.router.openshift.io/proxy-body-size: "0"   # unlimited
    labels:
        app: artifactory
        app.kubernetes.io/managed-by: Helm
        chart: artifactory-107.125.7
        component: artifactory
        heritage: Helm
        release: artifactory
    name: artifactory
    namespace: artifactory
    spec:
    host: artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com
    port:
        targetPort: http-router
    tls:
        insecureEdgeTerminationPolicy: Allow
        termination: edge
    to:
        kind: Service
        name: artifactory
        weight: 100
    wildcardPolicy: None
    ```

1. From the browser, go the `https://artifactory-artifactory.apps.cpikks.cp.fyre.ibm.com`

1. Get trial license (14-day) from Artifactory

1. Create a repository call `ibm`

1. Create a user, and generate a token for the user.