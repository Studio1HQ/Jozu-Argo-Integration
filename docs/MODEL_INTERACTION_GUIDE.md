# Interacting with the Text Classification Model

This guide explains how to interact with the text classification model once you've deployed it as a Kubernetes pod and accessed its shell.

## Inside the Pod Shell

Once you've accessed the pod shell with:
```bash
kubectl exec -it text-classification-model-basic -- /bin/bash
```

You can interact with the model in several ways:

## 1. Check the Model Files

First, let's explore what's available in the container:

```bash
# List the main directories
ls -la /

# Check the model directory
ls -la /model

# Check the model files
ls -la /model/model
```

## 2. Start the Model Server

The model container typically includes a built-in server for inference. You can start it with:

```bash
# Start the model server in the background
python -m jozu.serve &

# Check if the server is running
ps aux | grep jozu.serve
```

## 3. Make Inference Requests

Once the server is running, you can make inference requests using curl:

```bash
# Make a prediction request
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product, it is amazing!"}'
```

Expected output:
```json
{
  "prediction": "positive",
  "confidence": 0.92,
  "probabilities": {
    "negative": 0.08,
    "positive": 0.92
  }
}
```

Try different inputs:
```bash
# Negative example
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "This product is terrible, I want a refund."}'

# Neutral example
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "The product arrived on time."}'
```

## 4. Explore the Model Metadata

You can check the model's metadata:

```bash
# View model metadata
cat /model/metadata.json
```

## 5. Check Model Logs

If the model server is running, you can check its logs:

```bash
# If you started the server in the background
tail -f /tmp/jozu_serve.log
```

## 6. Run Python Interactive Session

You can also interact with the model directly through Python:

```bash
# Start Python
python

# Inside Python
import jozu
from jozu.model import load_model

# Load the model
model = load_model("/model")

# Make a prediction
result = model.predict("I love this product!")
print(result)

# Exit Python
exit()
```

## 7. Exit the Pod Shell

When you're done, exit the shell:

```bash
exit
```

## Monitoring the Pod from Outside

You can also monitor the pod from outside:

```bash
# Check pod logs
kubectl logs text-classification-model-basic

# Check pod status
kubectl describe pod text-classification-model-basic
```

## Port Forwarding for External Access

To access the model server from outside the pod:

```bash
# Forward the port
kubectl port-forward text-classification-model-basic 8000:8000
```

Then in another terminal:
```bash
# Make a request to the forwarded port
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product, it is amazing!"}'