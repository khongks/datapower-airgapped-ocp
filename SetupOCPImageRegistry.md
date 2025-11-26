## Setup OCP Image Registry

1. Create image registry using Tekton pipeline from the Console
    ```

    ```

1. Expose
    ```
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
    ```

1. Get URL
    ```
    oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}'
    ```
    ```
    default-route-openshift-image-registry.apps.<<ocp-domain-name>>
    ```

1. Login to OpenShift image registry
    ```
    podman login -u $(oc whoami) -p $(oc whoami -t) default-route-openshift-image-registry.apps.<ocp-domain-name>
    ```