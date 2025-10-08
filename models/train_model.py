#!/usr/bin/env python3
"""
Script to train a simple sentiment analysis model and save it as model.pkl
"""

import pickle
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline

# Sample training data
positive_texts = [
    "I love this product, it's amazing!",
    "Great quality, would recommend to everyone",
    "Excellent value for money, exceeded expectations",
    "Very happy with my purchase",
    "Works perfectly, exactly what I needed"
]

negative_texts = [
    "This is terrible, worst purchase ever",
    "Poor customer service, very disappointed",
    "Product broke after one use",
    "Not worth the money, avoid this",
    "Doesn't work as advertised, waste of time"
]

# Prepare training data
X_train = positive_texts + negative_texts
y_train = [1] * len(positive_texts) + [0] * len(negative_texts)

# Create a simple pipeline with CountVectorizer and MultinomialNB
model = Pipeline([
    ('vectorizer', CountVectorizer()),
    ('classifier', MultinomialNB())
])

# Train the model
model.fit(X_train, y_train)

# Save the model
with open('model.pkl', 'wb') as f:
    pickle.dump(model, f)

print("Model trained and saved as model.pkl")

# Test the model
test_texts = [
    "I love this product",
    "This is terrible"
]

predictions = model.predict(test_texts)
probabilities = model.predict_proba(test_texts)

for i, text in enumerate(test_texts):
    sentiment = "positive" if predictions[i] == 1 else "negative"
    confidence = max(probabilities[i])
    print(f"Text: '{text}'")
    print(f"Prediction: {sentiment}")
    print(f"Confidence: {confidence:.2f}")
    print()