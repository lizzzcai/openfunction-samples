import pathlib
import joblib
import numpy as np

model_path = pathlib.Path(__file__).resolve().parent / 'models/model.joblib'
print('model path: %s', model_path)
_model = joblib.load(model_path)

def predict(request):
    data = request.get_json()
    if not data or "instances" not in data:
        return "empty request or 'instances' not in request", 400
    
    instances = data["instances"]
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
