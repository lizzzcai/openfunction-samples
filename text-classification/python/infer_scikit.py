from os.path import exists
from joblib import load

text_pipeline, target_classes = None, None

def init():
    """
    Load the model if it is available locally
    """
    global text_pipeline, target_classes
    path = "/mnt/models"
    model_name = "classifier_pipeline.pkl"

    if exists(f"{path}/{model_name}"):
        print(f"Loading classifier pipeline from {path}")
        with open(f"{path}/{model_name}", "rb") as handle:
            [text_pipeline, target_classes] = load(handle)
            print("Model loaded successfully")
    else:
        raise FileNotFoundError(f"{path}/{model_name}")

    return None

init()

def predict(request):
    """
    Perform an inference on the model created in initialize

    Returns:
        String prediction of the label for the given test data
    """
    global text_pipeline, target_classes
    input_data = dict(request.json)
    prediction = text_pipeline.predict([input_data["text"]])
    predicted_label = target_classes[prediction[0]]
    output = {"predictions": predicted_label}

    return output