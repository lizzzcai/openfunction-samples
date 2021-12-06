import os
import joblib
import numpy as np
import pathlib
from typing import Dict

# dir_path = os.path.dirname(os.path.realpath(__file__))
model_path = pathlib.Path(__file__).resolve().parent / 'model/model.joblib'
print("model path:", model_path)
_model = joblib.load(model_path)

def predict(request: Dict) -> Dict:
    instances = request["instances"]
    try:
        inputs = np.array(instances)
    except Exception as e:
        raise Exception(
            "Failed to initialize NumPy array from inputs: %s, %s" % (e, instances))
    try:
        result = _model.predict(inputs).tolist()
        return {"predictions": result}
    except Exception as e:
        raise Exception("Failed to predict %s" % e)
