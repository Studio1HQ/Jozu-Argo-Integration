#!/bin/bash
# Script to set up authentication specifically for the Jozu Hub text classification model
# This script creates the necessary secrets for pulling the image from Jozu Hub

set -e

NAMESPACE="argo"
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

# Create the namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
else
    echo "Namespace '$NAMESPACE' already exists."
fi

# Prompt for Jozu Hub credentials
echo "=== Jozu Hub Authentication ==="
echo "We need your Jozu Hub credentials to pull the model image: $MODEL_IMAGE"
read -p "Jozu Hub Username: " JOZU_USERNAME
read -sp "Jozu Hub Password: " JOZU_PASSWORD
echo ""

# Create secret for Jozu Hub registry
echo "Creating secret for Jozu Hub registry..."
kubectl create secret docker-registry jozu-registry-cred \
  --docker-server=jozu.ml \
  --docker-username="$JOZU_USERNAME" \
  --docker-password="$JOZU_PASSWORD" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create a service account for the workflows
echo "Creating service account for workflows..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: workflow-service-account
  namespace: $NAMESPACE
imagePullSecrets:
- name: jozu-registry-cred
EOF

# Test pulling the image
echo ""
echo "=== Testing Image Pull ==="
echo "Creating a test pod to verify we can pull the image..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-jozu-pull
  namespace: $NAMESPACE
spec:
  serviceAccountName: workflow-service-account
  containers:
  - name: test-container
    image: $MODEL_IMAGE
    command: ["sleep", "10"]
  restartPolicy: Never
EOF

# Wait for the pod to start
echo "Waiting for test pod to start (this may take a minute)..."
kubectl wait --for=condition=initialized pod/test-jozu-pull -n "$NAMESPACE" --timeout=60s || true

# Check pod status
POD_STATUS=$(kubectl get pod test-jozu-pull -n "$NAMESPACE" -o jsonpath='{.status.phase}')
if [[ "$POD_STATUS" == "Running" || "$POD_STATUS" == "Succeeded" ]]; then
    echo "Success! The image was pulled successfully."
    echo "You can now run the Argo workflows with this image."
else
    echo "Image pull test failed. Current pod status: $POD_STATUS"
    echo "Checking for more details..."
    kubectl describe pod test-jozu-pull -n "$NAMESPACE"
fi

# Clean up the test pod
echo "Cleaning up test pod..."
kubectl delete pod test-jozu-pull -n "$NAMESPACE" --wait=false

echo ""
echo "=== Setup Complete ==="
echo "To use the Jozu Hub image in your workflows, make sure to specify:"
echo "spec:"
echo "  serviceAccountName: workflow-service-account"
echo ""
echo "This has already been configured in the workflow templates."
