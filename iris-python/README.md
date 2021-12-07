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


## Run a prediction

```
INGRESS_HOST=...
INGRESS_PORT=...
INPUT_PATH=@./iris-input.json
SERVICE_NAME=serving-vshnt-ksvc-7srtp
SERVICE_HOSTNAME=$(kubectl get ksvc $SERVICE_NAME -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)
curl -v -H "Host: $SERVICE_HOSTNAME" http://$INGRESS_HOST:$INGRESS_PORT -d $INPUT_PATH
```