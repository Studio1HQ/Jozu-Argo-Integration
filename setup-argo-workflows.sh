#!/bin/bash
# Script to set up Argo Workflows in a Kubernetes cluster
# This script installs Argo Workflows and applies the workflow templates

set -e

NAMESPACE="argo"

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

# Create the argo namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace '$NAMESPACE'..."
    kubectl create namespace "$NAMESPACE"
else
    echo "Namespace '$NAMESPACE' already exists."
fi

# Install Argo Workflows using kubectl
echo "Installing Argo Workflows..."
kubectl apply -n "$NAMESPACE" -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.8/install.yaml

# Wait for Argo controller to be ready
echo "Waiting for Argo controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/workflow-controller -n "$NAMESPACE"
kubectl wait --for=condition=available --timeout=300s deployment/argo-server -n "$NAMESPACE"

# Apply the workflow templates
echo "Applying workflow templates..."
kubectl apply -f argo/workflow-template.yaml -n "$NAMESPACE"

# Create ConfigMap for sample inputs
echo "Creating ConfigMap for sample inputs..."
kubectl create configmap inference-inputs --from-file=argo/sample-inputs.json -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Configure Argo server for easier UI access
echo "Configuring Argo server for easier UI access..."
kubectl patch deployment argo-server -n "$NAMESPACE" --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server", "--auth-mode=server"]}]'
kubectl rollout status deployment/argo-server -n "$NAMESPACE"

# Set up port forwarding for Argo UI (in background)
echo "Setting up port forwarding for Argo UI..."
kubectl -n "$NAMESPACE" port-forward --address=0.0.0.0 svc/argo-server 8080:2746 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Save the PID for later cleanup
echo $PORT_FORWARD_PID > .argo-port-forward.pid

echo "Argo Workflows has been set up successfully!"
echo "You can access the Argo UI at: http://localhost:8080"
echo "To stop port forwarding, run: kill $(cat .argo-port-forward.pid) && rm .argo-port-forward.pid"

# Instructions for using the workflow
echo ""
echo "To submit a workflow, use the submit-workflow.sh script:"
echo "  ./argo/submit-workflow.sh single text \"Your text to classify\""
echo "  ./argo/submit-workflow.sh batch file argo/sample-inputs.json"
echo ""
echo "For more information, see the README in the argo directory."
