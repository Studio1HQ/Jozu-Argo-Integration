#!/usr/bin/env python3
"""
Simple inference script for the text classification model
"""

import pickle
import json
import sys
import os
import time
from flask import Flask, request, jsonify

app = Flask(__name__)

# Wait for a moment to ensure all services are ready
time.sleep(2)

# Load the model
model = None

def load_model():
    global model
    MAX_RETRIES = 5
    retry_count = 0

    while retry_count < MAX_RETRIES:
        try:
            model_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'model.pkl')
            with open(model_path, 'rb') as f:
                model = pickle.load(f)
            print(f"Model loaded successfully from {model_path}")
            return True
        except Exception as e:
            retry_count += 1
            print(f"Error loading model (attempt {retry_count}/{MAX_RETRIES}): {e}")
            if retry_count >= MAX_RETRIES:
                print("Failed to load model after multiple attempts. Exiting.")
                return False
            time.sleep(2)  # Wait before retrying

# Load the model at startup
if not load_model():
    sys.exit(1)

@app.route('/health', methods=['GET'])
def health():
    if model is None:
        return jsonify({"status": "unhealthy", "reason": "Model not loaded"}), 500
    return jsonify({"status": "healthy"})

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if model is None:
            if not load_model():
                return jsonify({"error": "Model not loaded"}), 500
                
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            return jsonify({"error": "No text provided"}), 400
        
        # Make prediction
        prediction = model.predict([text])[0]
        probability = model.predict_proba([text])[0]
        
        # Map prediction to class name
        classes = ["negative", "positive"]
        predicted_class = classes[prediction]
        confidence = float(max(probability))
        
        return jsonify({
            "prediction": predicted_class,
            "confidence": confidence,
            "probabilities": {
                "negative": float(probability[0]),
                "positive": float(probability[1])
            }
        })
    
    except Exception as e:
        print(f"Error in prediction: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/v1/completions', methods=['POST'])
def completions():
    """OpenAI-compatible endpoint for Jozu Hub integration"""
    try:
        if model is None:
            if not load_model():
                return jsonify({"error": "Model not loaded"}), 500
                
        data = request.get_json()
        prompt = data.get('prompt', '')
        
        if not prompt:
            return jsonify({"error": "No prompt provided"}), 400
        
        # Make prediction
        prediction = model.predict([prompt])[0]
        probability = model.predict_proba([prompt])[0]
        
        # Map prediction to class name
        classes = ["negative", "positive"]
        predicted_class = classes[prediction]
        confidence = float(max(probability))
        
        # Format response in OpenAI-compatible format
        response = {
            "choices": [{
                "text": f"Sentiment: {predicted_class} (confidence: {confidence:.2f})",
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(prompt.split()),
                "completion_tokens": 1,
                "total_tokens": len(prompt.split()) + 1
            }
        }
        
        return jsonify(response)
    
    except Exception as e:
        print(f"Error in completions: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("Starting inference server on port 8000...")
    app.run(host='0.0.0.0', port=8000, debug=False)