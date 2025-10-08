#!/usr/bin/env python3
"""
Simple mock inference server that doesn't rely on loading a model
"""

import json
import random
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy"})

@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            return jsonify({"error": "No text provided"}), 400
        
        # Simple sentiment analysis based on keywords
        positive_words = ['good', 'great', 'excellent', 'love', 'amazing', 'happy', 'best']
        negative_words = ['bad', 'terrible', 'worst', 'hate', 'poor', 'disappointed', 'awful']
        
        text_lower = text.lower()
        
        # Count positive and negative words
        positive_count = sum(1 for word in positive_words if word in text_lower)
        negative_count = sum(1 for word in negative_words if word in text_lower)
        
        # Determine sentiment
        if positive_count > negative_count:
            prediction = 1  # positive
            confidence = min(0.5 + (positive_count - negative_count) * 0.1, 0.95)
        elif negative_count > positive_count:
            prediction = 0  # negative
            confidence = min(0.5 + (negative_count - positive_count) * 0.1, 0.95)
        else:
            # If tied or no sentiment words, slightly randomize but lean positive
            prediction = random.choice([0, 1, 1])
            confidence = random.uniform(0.51, 0.65)
        
        # Calculate probabilities
        if prediction == 1:
            pos_prob = confidence
            neg_prob = 1.0 - confidence
        else:
            neg_prob = confidence
            pos_prob = 1.0 - confidence
            
        # Map prediction to class name
        predicted_class = "positive" if prediction == 1 else "negative"
        
        return jsonify({
            "prediction": predicted_class,
            "confidence": confidence,
            "probabilities": {
                "negative": float(neg_prob),
                "positive": float(pos_prob)
            }
        })
    
    except Exception as e:
        print(f"Error in prediction: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/v1/completions', methods=['POST'])
def completions():
    """OpenAI-compatible endpoint for Jozu Hub integration"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        
        if not prompt:
            return jsonify({"error": "No prompt provided"}), 400
        
        # Simple sentiment analysis based on keywords
        positive_words = ['good', 'great', 'excellent', 'love', 'amazing', 'happy', 'best']
        negative_words = ['bad', 'terrible', 'worst', 'hate', 'poor', 'disappointed', 'awful']
        
        prompt_lower = prompt.lower()
        
        # Count positive and negative words
        positive_count = sum(1 for word in positive_words if word in prompt_lower)
        negative_count = sum(1 for word in negative_words if word in prompt_lower)
        
        # Determine sentiment
        if positive_count > negative_count:
            prediction = 1  # positive
            confidence = min(0.5 + (positive_count - negative_count) * 0.1, 0.95)
        elif negative_count > positive_count:
            prediction = 0  # negative
            confidence = min(0.5 + (negative_count - positive_count) * 0.1, 0.95)
        else:
            # If tied or no sentiment words, slightly randomize but lean positive
            prediction = random.choice([0, 1, 1])
            confidence = random.uniform(0.51, 0.65)
        
        # Map prediction to class name
        predicted_class = "positive" if prediction == 1 else "negative"
        
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
    print("Starting simple inference server on port 8000...")
    app.run(host='0.0.0.0', port=8000, debug=False)
