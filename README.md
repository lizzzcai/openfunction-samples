# OpenFunction Samples

## Installation

### Version

* OpenFunction v0.4.0

### Setup a Cluster

```sh
minikube start -p demo --kubernetes-version=v1.22.2 --network-plugin=cni --cni=calico
```

### Install OpenFunction

```sh
# clone repo
git clone https://github.com/OpenFunction/OpenFunction.git

# enter the repo
cd openfunction

# install the prerequisties
sh hack/deploy.sh --all

# verification of dapr
dapr status -k
```

```sh
# install openfunction
kubectl create -f https://github.com/OpenFunction/OpenFunction/releases/download/v0.4.0/bundle.yaml

# verfication
kubectl get pods --namespace openfunction
```

### Uninstall OpenFunction
```sh
# delete openfunction
kubectl delete -f https://raw.githubusercontent.com/OpenFunction/OpenFunction/release-0.4/config/bundle.yaml

# delete the prerequisties
sh hack/delete.sh --all
```

## Demo

### Create a push secret
```sh
REGISTRY_SERVER=https://index.docker.io/v1/
REGISTRY_USER=<your_registry_user>
REGISTRY_PASSWORD=<your_registry_password>
kubectl create secret docker-registry push-secret \
    --docker-server=$REGISTRY_SERVER \
    --docker-username=$REGISTRY_USER \
    --docker-password=$REGISTRY_PASSWORD
```

### Deploy a function

```sh
cd hello-world-go
kubectl apply -f function-sample.yaml
```

### View the status

```sh
❯ kubectl get functions
NAME              BUILDSTATE   SERVINGSTATE   BUILDER         SERVING   AGE
function-sample   Created                     builder-6bf2s             61s

❯ kubectl get builders
NAME            PHASE   STATE      AGE
builder-6bf2s   Build   Building   70s
```

```sh
❯ kubectl get builds
NAME                        REGISTERED   REASON      BUILDSTRATEGYKIND      BUILDSTRATEGYNAME   CREATIONTIME
builder-cvkrg-build-5lz4g   True         Succeeded   ClusterBuildStrategy   openfunction        16m

❯ kubectl get ClusterBuildStrategies
NAME           AGE
openfunction   3h37m

❯ kubectl get buildruns

❯ kubectl get taskruns

```

```sh
❯ kubectl get servings
NAME            PHASE     STATE     AGE
serving-wbmxm   Serving   Running   145m

❯ kubectl get ksvc
NAME                       URL                                                   LATESTCREATED                   LATESTREADY                     READY   REASON
serving-wbmxm-ksvc-scmqq   http://serving-wbmxm-ksvc-scmqq.default.example.com   serving-wbmxm-ksvc-scmqq-v100   serving-wbmxm-ksvc-scmqq-v100   True    
```

### Port-forward the ingress gateway

```sh
kubectl port-forward --namespace kourier-system svc/kourier 8080:80
```

### Curl from ingress gateway with HOST Header

```sh
export INGRESS_HOST=localhost
export INGRESS_PORT=8080
SERVICE_NAME=serving-wbmxm-ksvc-scmqq
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT
```

### View the pod

```sh
❯ k get po
NAME                                                        READY   STATUS    RESTARTS   AGE
serving-wbmxm-ksvc-scmqq-v100-deployment-6cfc57d9fb-dtn22   2/2     Running   0          11s
```

### Delete the function

```sh
kubectl delete -f function-sample.yaml
```

## Reference
* https://github.com/OpenFunction/OpenFunction
* https://github.com/OpenFunction/samples