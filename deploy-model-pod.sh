#!/bin/bash
# Script to deploy the text classification model pod to Kubernetes
# This script applies the model-pod.yaml manifest and sets up authentication if needed

set -e

NAMESPACE="default"
MODEL_IMAGE="jozu.ml/siddhesh-bangar/text-classification-model/basic:latest"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install it first."
    exit 1
fi

# Check if the cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Ask if authentication is needed
read -p "Do you need to set up authentication for Jozu Hub? (y/n): " NEED_AUTH
if [[ "$NEED_AUTH" == "y" || "$NEED_AUTH" == "Y" ]]; then
    # Prompt for Jozu Hub credentials
    echo "=== Jozu Hub Authentication ==="
    read -p "Jozu Hub Username: " JOZU_USERNAME
    read -sp "Jozu Hub Password: " JOZU_PASSWORD
    echo ""

    # Create secret for Jozu Hub registry
    echo "Creating secret for Jozu Hub registry..."
    kubectl create secret docker-registry jozu-registry-cred \
      --docker-server=jozu.ml \
      --docker-username="$JOZU_USERNAME" \
      --docker-password="$JOZU_PASSWORD" \
      --dry-run=client -o yaml | kubectl apply -f -

    # Patch the default service account to use the secret
    echo "Patching default service account to use the secret..."
    kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "jozu-registry-cred"}]}'
fi

# Apply the model pod manifest
echo "Deploying the model pod..."
kubectl apply -f kubernetes/model-pod.yaml

# Wait for the pod to be ready
echo "Waiting for the pod to be ready..."
kubectl wait --for=condition=Ready pod/text-classification-model-basic --timeout=120s || true

# Check pod status
POD_STATUS=$(kubectl get pod text-classification-model-basic -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" == "Running" ]]; then
    echo "Success! The model pod is running."
    echo "You can interact with it using:"
    echo "kubectl exec -it text-classification-model-basic -- /bin/bash"
else
    echo "Pod deployment failed. Current status: $POD_STATUS"
    echo "Checking for more details..."
    kubectl describe pod text-classification-model-basic
fi

echo ""
echo "=== Deployment Complete ==="
