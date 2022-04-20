# OpenFunction Samples

## Installation

### Version

* OpenFunction v0.6.0

### Setup a Cluster

```sh
minikube start -p demo --kubernetes-version=v1.22.2 --network-plugin=cni --cni=calico
```
### Install Istio

TBD

### Setup Prerequisites

```sh
# install the prerequisites, not including nginx ingress controller
# If you want to install nginx ingress controller, please add --with-ingress
sh scripts/deploy.sh --with-cert-manager --with-shipwright --with-openFuncAsync  --with-knative

# verification of dapr
dapr status -k

# verification of knative
kubectl get pods -n knative-serving
```

### Setup your Ingress Gateway

Choose either Kourier or Istio
#### Use Kourier

```sh
# Configure Knative Serving to use Kourier by default by running the command:
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}'

# Fetch the External IP address or CNAME by running the command:
kubectl --namespace kourier-system get service kourier
```

#### Use Istio

```sh
# Install the Knative Istio controller by running the command:
kubectl apply -f https://github.com/knative/net-istio/releases/download/knative-v1.2.0/net-istio.yaml

# Fetch the External IP address or CNAME by running the command:
kubectl --namespace istio-system get service istio-ingressgateway
```

#### Configure DNS

```sh
# Configure your DNS
# Replace knative.example.com with your domain suffix
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"a41592c7b5xxxxxxxxxxxd485f-1634070567.eu-central-1.elb.amazonaws.com":""}}'
```

### Install OpenFunction

```sh
# install openfunction
kubectl create -f https://github.com/OpenFunction/OpenFunction/releases/download/v0.6.0/bundle.yaml

# install latest openfunction
kubectl create -f https://raw.githubusercontent.com/OpenFunction/OpenFunction/main/config/bundle.yaml

# verfication
kubectl get pods --namespace openfunction
```

### Uninstall OpenFunction

```sh
# delete openfunction
kubectl delete -f https://github.com/OpenFunction/OpenFunction/releases/download/v0.6.0/bundle.yaml

# uninstall latest openfunction
kubectl delete -f https://raw.githubusercontent.com/OpenFunction/OpenFunction/main/config/bundle.yaml

# delete the prerequisties
sh hack/delete.sh --all
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
NAME              BUILDSTATE   SERVINGSTATE   BUILDER         SERVING   AGE
function-sample   Created                     builder-6bf2s             61s
```

### Check the building process

```sh
❯ kubectl get builders
NAME            PHASE   STATE      AGE
builder-6bf2s   Build   Building   70s

❯ kubectl get builds
NAME                        REGISTERED   REASON      BUILDSTRATEGYKIND      BUILDSTRATEGYNAME   CREATIONTIME
builder-cvkrg-build-5lz4g   True         Succeeded   ClusterBuildStrategy   openfunction        16m

❯ kubectl get ClusterBuildStrategies
NAME           AGE
openfunction   3h37m

❯ kubectl get buildruns
NAME                           SUCCEEDED   REASON    STARTTIME   COMPLETIONTIME
builder-pzdgk-buildrun-jrkpz   Unknown     Running   103s

❯ kubectl get taskruns
NAME                                 SUCCEEDED   REASON    STARTTIME   COMPLETIONTIME
builder-pzdgk-buildrun-jrkpz-8q4cx   Unknown     Running   108s
```

Once the function is built, the relative CR will be cleaned.

### View the Serving

```sh
❯ kubectl get servings
NAME            PHASE     STATE     AGE
serving-q9dsr   Serving   Running   20s

❯ kubectl get ksvc
NAME                       URL                                                   LATESTCREATED                   LATESTREADY                     READY   REASON
serving-q9dsr-ksvc-77w9x   http://serving-q9dsr-ksvc-77w9x.default.example.com   serving-q9dsr-ksvc-77w9x-v100   serving-q9dsr-ksvc-77w9x-v100   True
```

### Port-forward the ingress gateway

```sh
# if using kourier
kubectl port-forward --namespace kourier-system svc/kourier 8080:80
# if using istio ingress gateway
kubectl port-forward --namespace istio-system  svc/istio-ingressgateway 8080:80
```

### Curl from ingress gateway with HOST Header

```sh
export INGRESS_HOST=localhost
export INGRESS_PORT=8080
SERVICE_NAME=serving-q9dsr-ksvc-77w9x
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT
```

### If you have loadBalancer
```sh
# if using kourier
export INGRESS_HOST=$(kubectl --namespace kourier-system get service kourier -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
# if using istio ingress gateway
export INGRESS_HOST=$(kubectl --namespace istio-system get service istio-ingressgateway -o json | jq -r ".status.loadBalancer.ingress[0].hostname")
export INGRESS_PORT=80
SERVICE_NAME=serving-q9dsr-ksvc-77w9x
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT
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


## Reference
* https://github.com/OpenFunction/OpenFunction
* https://github.com/OpenFunction/samples
* https://tekton.dev/docs/dashboard