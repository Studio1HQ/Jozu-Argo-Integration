#!/bin/bash
# Script to troubleshoot image pull errors in Argo workflows
# This script will help diagnose and fix common image pull issues

set -e

NAMESPACE="argo"
MODEL_IMAGE="jozu.ml/siddhesh-bangar/text-classification-model/basic:latest"
KITOPS_IMAGE="kitops/kit:latest"

echo "=== Image Pull Error Troubleshooting ==="
echo "This script will help diagnose and fix image pull errors in Argo workflows."

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

# Check if the namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Error: Namespace '$NAMESPACE' does not exist."
    echo "Creating namespace..."
    kubectl create namespace "$NAMESPACE"
fi

# Check for existing workflows with errors
echo "Checking for workflows with errors..."
FAILED_WORKFLOWS=$(kubectl get workflows -n "$NAMESPACE" --field-selector status.phase=Failed -o name 2>/dev/null || echo "")
if [ -n "$FAILED_WORKFLOWS" ]; then
    echo "Found failed workflows:"
    echo "$FAILED_WORKFLOWS"
    
    # Get details of the first failed workflow
    FIRST_WORKFLOW=$(echo "$FAILED_WORKFLOWS" | head -1)
    echo "Examining workflow: $FIRST_WORKFLOW"
    kubectl describe "$FIRST_WORKFLOW" -n "$NAMESPACE"
fi

# Check for pods with image pull errors
echo "Checking for pods with image pull errors..."
FAILED_PODS=$(kubectl get pods -n "$NAMESPACE" --field-selector status.phase=Failed -o name 2>/dev/null || echo "")
if [ -n "$FAILED_PODS" ]; then
    echo "Found failed pods:"
    echo "$FAILED_PODS"
    
    # Get details of the first failed pod
    FIRST_POD=$(echo "$FAILED_PODS" | head -1)
    echo "Examining pod: $FIRST_POD"
    kubectl describe "$FIRST_POD" -n "$NAMESPACE"
fi

# Check for pods with ImagePullBackOff
echo "Checking for pods with ImagePullBackOff..."
PULL_ERROR_PODS=$(kubectl get pods -n "$NAMESPACE" | grep "ErrImagePull\|ImagePullBackOff" | awk '{print $1}')
if [ -n "$PULL_ERROR_PODS" ]; then
    echo "Found pods with image pull errors:"
    echo "$PULL_ERROR_PODS"
    
    # Get details of the first pod with pull errors
    FIRST_ERROR_POD=$(echo "$PULL_ERROR_PODS" | head -1)
    echo "Examining pod: $FIRST_ERROR_POD"
    kubectl describe pod "$FIRST_ERROR_POD" -n "$NAMESPACE"
fi

# Test pulling the model image
echo "Testing if we can pull the model image directly..."
echo "Creating a test pod for the model image..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-model-pull
  namespace: $NAMESPACE
spec:
  containers:
  - name: test-container
    image: $MODEL_IMAGE
    command: ["sleep", "30"]
  restartPolicy: Never
EOF

# Test pulling the KitOps image
echo "Testing if we can pull the KitOps image directly..."
echo "Creating a test pod for the KitOps image..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-kitops-pull
  namespace: $NAMESPACE
spec:
  containers:
  - name: test-container
    image: $KITOPS_IMAGE
    command: ["sleep", "30"]
  restartPolicy: Never
EOF

# Wait a moment for the pods to be created
echo "Waiting for test pods to initialize..."
sleep 10

# Check the status of the test pods
echo "Checking status of test pods..."
kubectl get pods test-model-pull test-kitops-pull -n "$NAMESPACE"

# Get details of the test pods
echo "Details of model image test pod:"
kubectl describe pod test-model-pull -n "$NAMESPACE"

echo "Details of KitOps image test pod:"
kubectl describe pod test-kitops-pull -n "$NAMESPACE"

# Set up authentication if needed
echo ""
echo "Based on the results, you may need to set up authentication for the images."
read -p "Do you want to set up authentication now? (y/n): " SETUP_AUTH
if [[ "$SETUP_AUTH" == "y" || "$SETUP_AUTH" == "Y" ]]; then
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
      --namespace="$NAMESPACE" \
      --dry-run=client -o yaml | kubectl apply -f -

    # Prompt for Docker Hub credentials (for KitOps image)
    echo "=== Docker Hub Authentication (for KitOps image) ==="
    read -p "Docker Hub Username: " DOCKER_USERNAME
    read -sp "Docker Hub Password: " DOCKER_PASSWORD
    echo ""

    # Create secret for Docker Hub registry
    echo "Creating secret for Docker Hub registry..."
    kubectl create secret docker-registry dockerhub-registry-cred \
      --docker-server=docker.io \
      --docker-username="$DOCKER_USERNAME" \
      --docker-password="$DOCKER_PASSWORD" \
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
- name: dockerhub-registry-cred
EOF

    # Update the workflow template to use the service account
    echo "Updating workflow templates to use the service account..."
    kubectl get workflowtemplates -n "$NAMESPACE" -o name | while read -r template; do
        echo "Patching $template..."
        kubectl patch "$template" -n "$NAMESPACE" --type=json \
          -p='[{"op": "add", "path": "/spec/serviceAccountName", "value": "workflow-service-account"}]'
    done
fi

# Clean up test pods
echo "Cleaning up test pods..."
kubectl delete pod test-model-pull test-kitops-pull -n "$NAMESPACE" --wait=false

echo ""
echo "=== Troubleshooting Complete ==="
echo "If you set up authentication, try running your workflow again."
echo "If you're still experiencing issues, check the following:"
echo "1. Verify that the image paths in the workflow template are correct"
echo "2. Ensure your cluster has network access to the registries"
echo "3. Check if the images exist in the registries"
echo ""
echo "You can run this script again if needed to diagnose further issues."
