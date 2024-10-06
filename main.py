import argparse
import io
from PIL import Image
import torch
import cv2
import numpy as np
from flask import Flask, request, jsonify
import os
from flask_cors import CORS

from ultralytics import YOLO

app = Flask(__name__)
CORS(app)


@app.route("/", methods=["POST"])
def predict_img():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400

    f = request.files['file']
    basepath = os.path.dirname(__file__)
    upload_folder = os.path.join(basepath, 'uploads')

    # Ensure upload directory exists
    if not os.path.exists(upload_folder):
        os.makedirs(upload_folder)

    filepath = os.path.join(upload_folder, f.filename)
    print("Upload folder is:", filepath)
    f.save(filepath)

    file_extension = f.filename.rsplit('.', 1)[1].lower()

    if file_extension not in ['jpg', 'jpeg', 'png']:
        return jsonify({"error": "Unsupported file format"}), 400

    # Read image using OpenCV
    img = cv2.imread(filepath)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  # Convert to RGB for PIL

    # Convert image to PIL format
    image = Image.fromarray(img_rgb)

    # Load YOLO model
    yolo = YOLO('yolov5s.pt')

    # Perform the detection
    results = yolo.predict(image)

    # Extract object names from the results
    object_names = []
    for result in results:
        for detection in result.boxes.data:
            object_name = yolo.names[int(detection[-1])]  # The last value is the class ID
            object_names.append(object_name)

    # Return result as JSON
    return jsonify({"object_names": object_names})

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Flask YOLO Application")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="Host to run the app on")
    parser.add_argument("--port", type=int, default=5000, help="Port to run the app on")
    parser.add_argument("--debug", action="store_true", help="Run the app in debug mode")
    args = parser.parse_args()

    app.run(host="0.0.0.0", port=5000, debug=True)
