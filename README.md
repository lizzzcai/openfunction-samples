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

## How to deploy a function

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
kubectl create -f function-sample.yaml
```

### View the status

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

### View the serving

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
kubectl port-forward --namespace kourier-system svc/kourier 8080:80
```

### Curl from ingress gateway with HOST Header

```sh
export INGRESS_HOST=localhost
export INGRESS_PORT=8080
SERVICE_NAME=serving-q9dsr-ksvc-77w9x
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT
```

### View the pod

```sh
❯ kubectl get po
NAME                                                        READY   STATUS    RESTARTS   AGE
serving-q9dsr-ksvc-77w9x-v100-deployment-78f557b95b-9j66b   2/2     Running   0          28s
```

### Delete the function

```sh
kubectl delete -f function-sample.yaml
```

## Reference
* https://github.com/OpenFunction/OpenFunction
* https://github.com/OpenFunction/samples