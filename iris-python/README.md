# SKLearn Iris Classfication

## Create your own model

```python
## train.py
import os
from sklearn import svm
from sklearn import datasets
from joblib import dump
os.makedirs('models', exist_ok=True)

clf = svm.SVC(gamma='scale')
iris = datasets.load_iris()
X, y = iris.data, iris.target
clf.fit(X, y)
dump(clf, 'models/model.joblib')
```

## Deploy the function

Create a secret
```sh
# create docker-registry secret
REGISTRY_SERVER=https://index.docker.io/v1/
REGISTRY_USER=<your_registry_user>
REGISTRY_PASSWORD=<your_registry_password>
kubectl create secret docker-registry push-secret \
    --docker-server=$REGISTRY_SERVER \
    --docker-username=$REGISTRY_USER \
    --docker-password=$REGISTRY_PASSWORD
```

Deploy the function
```
kubectl apply -f iris-python.yaml
```

## Run a prediction

```
INGRESS_HOST=...
INGRESS_PORT=...
INPUT_PATH=@./iris-input.json
SERVICE_NAME=serving-8pxmd-ksvc-zbvr2
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Content-Type: application/json" -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT -d $INPUT_PATH
```

## Debug a function

```
❯ functions-framework --target predict --debug
model path: /Users/i543026/dev/demo/openfunction-demo/iris-python/models/model.joblib
 * Serving Flask app "predict" (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: on
 * Running on http://0.0.0.0:8080/ (Press CTRL+C to quit)
```

Send a request
```
INPUT_PATH=@./iris-input.json
curl -v -X POST -H "Content-Type: application/json"  http://localhost:8080 -d $INPUT_PATH
```

## Open points

* Is possible to load model from storage like `s3` by [AWS s3 binding](https://docs.dapr.io/reference/components-reference/supported-bindings/s3/). (define it in the function.yaml, load the model from the logic)

