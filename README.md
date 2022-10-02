# OpenFunction Samples

## Installation

### Version

* OpenFunction v0.7.0

### Setup a Cluster

```sh
minikube start -p demo --kubernetes-version=v1.22.2 --network-plugin=cni --cni=calico
```

### Install OpenFunction by HelmChart

```sh
# add helm repo
helm repo add openfunction https://openfunction.github.io/charts/
helm repo update

# install
helm upgrade --install -f openfunction.yaml openfunction --create-namespace --namespace=openfunction openfunction/openfunction

# verfication
kubectl get pods --namespace openfunction

# verification of dapr
kubectl get po -n dapr-system

# verification of knative
kubectl get pods -n knative-serving
```

### Uninstall OpenFunction

```sh
# uninstall
helm delete openfunction -n openfunction
```

### Enable KNative features (Optional)

```sh
kubectl patch configmap/config-features \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"kubernetes.podspec-persistent-volume-claim":"enabled", "kubernetes.podspec-persistent-volume-write":"enabled", "kubernetes.podspec-init-containers":"enabled", "kubernetes.podspec-nodeselector":"enabled", "kubernetes.podspec-volumes-emptydir": "enabled"}}'
```

### Setup your Ingress Gateway

Choose either Contour, Istio or any gateways that support Kubernetes Gateway API

#### Use Contour [default]

Contour is the default gateway in OpenFunction.

```sh
# Fetch the External IP address or CNAME by running the command:
kubectl --namespace projectcontour get svc/contour-envoy
```

Steps showing below are already done via Helm Chart. Example given below are using contour dynamic provision.

##### Create a GatewayClass named contour

```sh
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: GatewayClass
metadata:
  name: contour
spec:
  # Dynamically provisioned: https://projectcontour.io/guides/gateway-api/
  controllerName: projectcontour.io/gateway-controller
  description: The default Contour GatewayClass
EOF

# Uninstall GatewayClass
kubectl delete GatewayClass contour
```

##### Create an OpenFunction Gateway

```sh
kubectl apply -f - <<EOF
apiVersion: networking.openfunction.io/v1alpha1
kind: Gateway
metadata:
  name: openfunction
  namespace: openfunction
spec:
  domain: ofn.io
  clusterDomain: cluster.local
  hostTemplate: "{{.Name}}.{{.Namespace}}.{{.Domain}}"
  pathTemplate: "{{.Namespace}}/{{.Name}}"
  gatewayDef:
    namespace: projectcontour
    gatewayClassName: contour
  gatewaySpec:
    listeners:
    - allowedRoutes:
        namespaces:
          from: All
      hostname: '*.cluster.local'
      name: ofn-http-internal
      port: 80
      protocol: HTTP
    - allowedRoutes:
        namespaces:
          from: All
      hostname: '*.ofn.io'
      name: ofn-http-external
      port: 80
      protocol: HTTP
EOF

# Uninstall Gateway
kubectl delete Gateway -n openfunction openfunction
```

#### Use Istio

Reference: https://openfunction.dev/docs/operations/networking/switch-gateway/

You can `disable` Contour when installing openfunction.
```sh
helm install openfunction --set global.Contour.enabled=false openfunction/openfunction -n openfunction
```

##### Install Istio

```sh
### Download Istio
ISTIO_VERSION=1.13.8
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} TARGET_ARCH=x86_64 sh -

cd istio-${ISTIO_VERSION}
export PATH=$PWD/bin:$PATH
cd ..

istioctl x precheck

# Install Istio
istioctl install -y
```

##### Create a GatewayClass named istio

```sh
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: GatewayClass
metadata:
  name: istio
spec:
  controllerName: istio.io/gateway-controller
  description: The default Istio GatewayClass
EOF

# Uninstall GatewayClass
kubectl delete GatewayClass istio
```

##### Create an OpenFunction Gateway

```sh
kubectl apply -f - <<EOF
apiVersion: networking.openfunction.io/v1alpha1
kind: Gateway
metadata:
  name: custom-gateway
  namespace: openfunction
spec:
  domain: ofn.io
  clusterDomain: cluster.local
  hostTemplate: "{{.Name}}.{{.Namespace}}.{{.Domain}}"
  pathTemplate: "{{.Namespace}}/{{.Name}}"
  gatewayDef:
    namespace: istio-system
    gatewayClassName: istio
  gatewaySpec:
    listeners:
    - allowedRoutes:
        namespaces:
          from: All
      hostname: '*.cluster.local'
      name: ofn-http-internal
      port: 80
      protocol: HTTP
    - allowedRoutes:
        namespaces:
          from: All
      hostname: '*.ofn.io'
      name: ofn-http-external
      port: 80
      protocol: HTTP
EOF

# Uninstall Gateway
kubectl delete Gateway -n openfunction custom-gateway
```

##### Setup Knative Integration

```sh
# Install the Knative Istio controller by running the command:
kubectl apply -f https://github.com/knative/net-istio/releases/download/knative-v1.3.0/net-istio.yaml

# Fetch the External IP address or CNAME by running the command:
kubectl --namespace istio-system get svc/istio-ingressgateway
```

## How to deploy a function

### Create a push secret

```sh
# create docker registry secret
REGISTRY_SERVER=https://index.docker.io/v1/
REGISTRY_USER=<your_registry_user>
REGISTRY_PASSWORD=<your_registry_password>
kubectl create secret docker-registry push-secret \
    --docker-server=$REGISTRY_SERVER \
    --docker-username=$REGISTRY_USER \
    --docker-password=$REGISTRY_PASSWORD

# or create secret from dockerconfigjson
kubectl create secret generic push-secret \
  --from-file=.dockerconfigjson=docker-config.json \
  --type=kubernetes.io/dockerconfigjson
```

### Deploy a Function

```sh
cd hello-world-go
kubectl create -f hello-world-go.yaml
```

### View the Function

```sh
❯ kubectl get functions
NAME             BUILDSTATE   SERVINGSTATE   BUILDER         SERVING         ADDRESS                                            AGE
hello-world-go   Succeeded    Running        builder-2q5sf   serving-94ggm   http://hello-world-go.default.svc.cluster.local/   10m
```

### Check the building process

```sh
❯ kubectl get builders
NAME            PHASE   STATE       REASON      AGE
builder-2q5sf   Build   Succeeded   Succeeded   12m

❯ kubectl get builds
NAME                        REGISTERED   REASON      BUILDSTRATEGYKIND      BUILDSTRATEGYNAME   CREATIONTIME
builder-2q5sf-build-kkqzx   True         Succeeded   ClusterBuildStrategy   openfunction        12m

❯ kubectl get ClusterBuildStrategies
NAME           AGE
buildah        21m
kaniko         21m
ko             21m
openfunction   21m

❯ kubectl get buildruns
NAME                           SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
builder-2q5sf-buildrun-v5fmw   True        Succeeded   13m         11m

❯ kubectl get taskruns
NAME                                 SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
builder-2q5sf-buildrun-v5fmw-fhksw   True        Succeeded   13m         11m
```

Once the function is built, the relative CR will be cleaned.

### View the Serving

```sh
❯ kubectl get servings
NAME            PHASE     STATE     AGE
serving-94ggm   Serving   Running   20s

❯ kubectl get ksvc
NAME                       URL                                                   LATESTCREATED                   LATESTREADY                     READY   REASON
serving-94ggm-ksvc-424rt   http://serving-94ggm-ksvc-424rt.default.example.com   serving-94ggm-ksvc-424rt-v100   serving-94ggm-ksvc-424rt-v100   True
```

### Check function addresses

```sh
❯ kubectl get function hello-world-go -o=jsonpath='{.status.addresses}'
[{"type":"External","value":"http://hello-world-go.default.ofn.io/"},{"type":"Internal","value":"http://hello-world-go.default.svc.cluster.local/"}]%
```

### Port-forward the ingress gateway

```sh
# if using contour (always using the contour-envoy if using static provisioning)
kubectl port-forward --namespace projectcontour svc/contour-envoy 8080:80
# if using istio
kubectl port-forward --namespace istio-system  svc/custom-gateway 8080:80 # gateway name same as your openfunction gateway
```

### Curl from ingress gateway with HOST Header

```sh
export INGRESS_HOST=localhost
export INGRESS_PORT=8080
FUNCTION_NAME=hello-world-go # kubectl get functions
SERVICE_HOSTNAME=$(kubectl get functions $FUNCTION_NAME -n default -o jsonpath='{.status.addresses[0].value}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT/openfunction
```

### If you have a loadBalancer

```sh
# if using contour
# from envoy-<gateway> service (if using dynamic provisioning)
export INGRESS_HOST=$(kubectl --namespace projectcontour get service envoy-openfunction  -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
# from k8s gateway
export INGRESS_HOST=$(kubectl --namespace projectcontour get gateways.gateway.networking.k8s.io openfunction -o json | jq -r ".status.addresses[0].value")

# if using istio ingress gateway
# from gateway service
export INGRESS_HOST=$(kubectl --namespace istio-system get service custom-gateway -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
# from k8s gateway
export INGRESS_HOST=$(kubectl --namespace istio-system get gateways.gateway.networking.k8s.io custom-gateway -o json | jq -r ".status.addresses[0].value")

export INGRESS_PORT=80
FUNCTION_NAME=hello-world-go # kubectl get functions
SERVICE_HOSTNAME=$(kubectl get functions $FUNCTION_NAME -n default -o jsonpath='{.status.addresses[0].value}' | cut -d "/" -f 3)
# send a request
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT/openfunction
```

### View the Pods

```sh
❯ kubectl get pods
NAME                                                        READY   STATUS    RESTARTS   AGE
serving-q9dsr-ksvc-77w9x-v100-deployment-78f557b95b-9j66b   2/2     Running   0          28s
```

### Delete the Function

```sh
kubectl delete -f hello-world-go.yaml
```

## How to debug

### Build failed

#### Check the Builder

```sh
❯ kubectl get builders
NAME            PHASE   STATE    AGE
builder-qx8w5   Build   Failed   11h

❯  kubectl get builders -o yaml
apiVersion: v1
items:
- apiVersion: core.openfunction.io/v1alpha2
  kind: Builder
  metadata:
    creationTimestamp: "2021-11-23T14:58:29Z"
    generateName: builder-
    generation: 1
    labels:
      openfunction.io/function: hello-world-python
    name: builder-qx8w5
    namespace: default
    ownerReferences:
    - apiVersion: core.openfunction.io/v1alpha2
      blockOwnerDeletion: true
      controller: true
      kind: Function
      name: hello-world-python
      uid: 9ec1a8a9-2b05-4117-a87a-c1a2e35a36f1
    resourceVersion: "4232427"
    uid: 9b689181-30b4-40f9-b2af-0973784abd17
  spec:
    builder: openfunction/builder:v1
    env:
      FUNC_NAME: hello_world
      FUNC_SRC: main.py
      FUNC_TYPE: http
    image: lizzzcai/sample-python-func:v0.4.0
    imageCredentials:
      name: push-secret
    port: 8080
    srcRepo:
      sourceSubPath: hello-world-python
      url: https://github.com/lizzzcai/openfunction-samples.git
  status:
    phase: Build
    resourceRef:
      shipwright.io/build: builder-qx8w5-build-mn97k
      shipwright.io/buildRun: builder-qx8w5-buildrun-x6q7b
    state: Failed
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

#### Check the Build

```sh
❯  kubectl get build
NAME                        REGISTERED   REASON      BUILDSTRATEGYKIND      BUILDSTRATEGYNAME   CREATIONTIME
builder-qx8w5-build-mn97k   True         Succeeded   ClusterBuildStrategy   openfunction        11h
```

#### Check the BuildRun
```sh
❯  kubectl get buildrun
NAME                           SUCCEEDED   REASON   STARTTIME   COMPLETIONTIME
builder-qx8w5-buildrun-x6q7b   False       Failed   11h         11h

❯  kubectl get buildrun -o yaml
apiVersion: v1
items:
- apiVersion: shipwright.io/v1alpha1
  kind: BuildRun
  metadata:
    creationTimestamp: "2021-11-23T14:58:29Z"
    generateName: builder-qx8w5-buildrun-
    generation: 1
    labels:
      build.shipwright.io/generation: "1"
      build.shipwright.io/name: builder-qx8w5-build-mn97k
      openfunction.io/builder: builder-qx8w5
    name: builder-qx8w5-buildrun-x6q7b
    namespace: default
    ownerReferences:
    - apiVersion: core.openfunction.io/v1alpha2
      blockOwnerDeletion: true
      controller: true
      kind: Builder
      name: builder-qx8w5
      uid: 9b689181-30b4-40f9-b2af-0973784abd17
    resourceVersion: "4232426"
    uid: b6309378-c55b-4ff3-b514-b410d6a42b29
  spec:
    buildRef:
      name: builder-qx8w5-build-mn97k
  status:
    buildSpec:
      builder:
        image: openfunction/builder:v1
      output:
        credentials:
          name: push-secret
        image: lizzzcai/sample-python-func:v0.4.0
      paramValues:
      - name: APP_IMAGE
        value: lizzzcai/sample-python-func:v0.4.0
      - name: ENV_VARS
        value: FUNC_NAME=hello_world#FUNC_SRC=main.py#FUNC_TYPE=http#PORT=8080
      source:
        contextDir: hello-world-python
        url: https://github.com/lizzzcai/openfunction-samples.git
      strategy:
        kind: ClusterBuildStrategy
        name: openfunction
    completionTime: "2021-11-23T14:58:47Z"
    conditions:
    - lastTransitionTime: "2021-11-23T14:58:48Z"
      message: 'buildrun step step-create failed in pod builder-qx8w5-buildrun-x6q7b-bnbl6-pod-l4kwf,
        for detailed information: kubectl --namespace default logs builder-qx8w5-buildrun-x6q7b-bnbl6-pod-l4kwf
        --container=step-create'
      reason: Failed
      status: "False"
      type: Succeeded
    failedAt:
      container: step-create
      pod: builder-qx8w5-buildrun-x6q7b-bnbl6-pod-l4kwf
    latestTaskRunRef: builder-qx8w5-buildrun-x6q7b-bnbl6
    startTime: "2021-11-23T14:58:30Z"
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

#### Check the logs of the BuildRun pod

```sh
❯ kubectl --namespace default logs builder-qx8w5-buildrun-x6q7b-bnbl6-pod-l4kwf --container=step-create
===> DETECTING
======== Error: google.dotnet.functions-framework@0.0.1 ========
chdir /workspace/source/hello-world-python: no such file or directory
======== Error: google.dotnet.runtime@0.9.1 ========
chdir /workspace/source/hello-world-python: no such file or directory
...
```

#### Check the TaskRun

```sh
❯ kubectl get taskruns
NAME                                 SUCCEEDED   REASON   STARTTIME   COMPLETIONTIME
builder-qx8w5-buildrun-x6q7b-bnbl6   False       Failed   11h         11h
```

#### Check the TaskRun in Tekton Dashboard

Install the latest release of Tekton Dashboard

```sh
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml
```

Port-forwarding Tekton Dashboard

```sh
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
```

Once set up, the dashboard is available in the browser under the address http://localhost:9097.


### Install Dapr locally (Optional)

This is to setup Dapr locally for local development
```sh
dapr_version=1.8.3
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash -s ${dapr_version}
dapr init --runtime-version ${dapr_version}

dapr --version

ls $HOME/.dapr

# uninstall
dapr uninstall --all
```

## Reference
* https://github.com/OpenFunction/OpenFunction
* https://github.com/OpenFunction/samples
* https://tekton.dev/docs/dashboard
* https://projectcontour.io/guides/gateway-api/