from flask import Flask, render_template_string, request
import torch
from resnet_lstm_model import ResNetLSTMModel
from data_preprocessing import load_and_preprocess_video
import os

app = Flask(__name__)

model = ResNetLSTMModel()
model.load_state_dict(torch.load("path/to/your/model.pth"))
model.eval()

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deepfake Detection</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
</head>
<body>
<div class="container">
    <h1>Deepfake Detection</h1>
    <form action="/predict" method="POST" enctype="multipart/form-data">
        <div class="form-group">
            <label for="videoFile">Upload Video File:</label>
            <input type="file" class="form-control-file" id="videoFile" name="videoFile" accept="video/*" required>
        </div>
        <button type="submit" class="btn btn-primary btn-block">Check for Deepfake</button>
    </form>
    {% if result %}
        <div class="result">
            <p>Prediction: <strong>{{ result.prediction }}</strong></p>
            <p>Confidence: <strong>{{ result.confidence }}</strong></p>
        </div>
    {% endif %}
    {% if error %}
        <div class="alert alert-danger" role="alert">{{ error }}</div>
    {% endif %}
</div>
</body>
</html>
"""

@app.route('/')
def home():
    return render_template_string(HTML_TEMPLATE, result=None, error=None)

@app.route('/predict', methods=['POST'])
def predict():
    if 'videoFile' not in request.files:
        return render_template_string(HTML_TEMPLATE, result=None, error="No file part in the request.")

    video_file = request.files['videoFile']
    if video_file.filename == '':
        return render_template_string(HTML_TEMPLATE, result=None, error="No selected file.")

    try:
        filepath = os.path.join('uploads', video_file.filename)
        video_file.save(filepath)
        
        frames = load_and_preprocess_video(filepath)
        frames = frames.unsqueeze(0)  # Add batch dimension
        with torch.no_grad():
            outputs = model(frames)
            confidence_score = torch.sigmoid(outputs).item()
            prediction = "Fake" if confidence_score > 0.5 else "Real"
            result = {
                "prediction": prediction,
                "confidence": f"{confidence_score:.2%}"
            }
        
        return render_template_string(HTML_TEMPLATE, result=result, error=None)
    
    except Exception as e:
        return render_template_string(HTML_TEMPLATE, result=None, error=str(e))

if __name__ == '__main__':
    app.run(debug=True) 