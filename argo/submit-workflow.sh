#!/bin/bash
# Script to submit and monitor Argo workflows for ML model inference
# Usage: ./submit-workflow.sh [single|batch] [text|file]

set -e

# Default values
WORKFLOW_TYPE="single"
INPUT_TYPE="text"
INPUT_TEXT="I love this product, it's amazing!"
INPUT_FILE="sample-inputs.json"
NAMESPACE="argo"

# Parse command line arguments
if [ "$1" == "single" ] || [ "$1" == "batch" ]; then
  WORKFLOW_TYPE="$1"
fi

if [ "$2" == "text" ] || [ "$2" == "file" ]; then
  INPUT_TYPE="$2"
fi

if [ "$3" != "" ]; then
  if [ "$INPUT_TYPE" == "text" ]; then
    INPUT_TEXT="$3"
  else
    INPUT_FILE="$3"
  fi
fi

# Function to check if Argo is installed
check_argo_installed() {
  if ! command -v argo &> /dev/null; then
    echo "Error: Argo CLI is not installed. Please install it first."
    echo "Installation instructions: https://argoproj.github.io/argo-workflows/quick-start/"
    exit 1
  fi
}

# Function to check if the namespace exists
check_namespace() {
  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Error: Namespace '$NAMESPACE' does not exist."
    echo "Please create it first with: kubectl create namespace $NAMESPACE"
    exit 1
  fi
}

# Function to check if workflow templates are installed
check_workflow_templates() {
  if ! kubectl get workflowtemplates -n "$NAMESPACE" &> /dev/null; then
    echo "Error: WorkflowTemplates resource not found in namespace '$NAMESPACE'."
    echo "Please install Argo Workflows first."
    exit 1
  fi
  
  if [ "$WORKFLOW_TYPE" == "single" ]; then
    if ! kubectl get workflowtemplate text-classification-template -n "$NAMESPACE" &> /dev/null; then
      echo "Error: WorkflowTemplate 'text-classification-template' not found."
      echo "Please apply the workflow template first with: kubectl apply -f workflow-template.yaml"
      exit 1
    fi
  else
    if ! kubectl get workflowtemplate text-classification-batch-template -n "$NAMESPACE" &> /dev/null; then
      echo "Error: WorkflowTemplate 'text-classification-batch-template' not found."
      echo "Please apply the workflow template first with: kubectl apply -f workflow-template.yaml"
      exit 1
    fi
  fi
}

# Function to create ConfigMap for batch input file
create_input_configmap() {
  if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
  fi
  
  echo "Creating ConfigMap 'inference-inputs' from file '$INPUT_FILE'..."
  kubectl create configmap inference-inputs --from-file="$INPUT_FILE" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
}

# Function to submit a single inference workflow
submit_single_workflow() {
  WORKFLOW_NAME="text-classification-$(date +%s)"
  
  echo "Submitting single inference workflow '$WORKFLOW_NAME'..."
  echo "Input text: $INPUT_TEXT"
  
  # Create a temporary workflow file
  cat > /tmp/workflow.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: text-classification-
  namespace: $NAMESPACE
spec:
  workflowTemplateRef:
    name: text-classification-template
  arguments:
    parameters:
    - name: input-text
      value: "$INPUT_TEXT"
EOF
  
  # Submit the workflow
  WORKFLOW_NAME=$(kubectl create -f /tmp/workflow.yaml -o name)
  echo "Workflow submitted: $WORKFLOW_NAME"
  
  # Clean up the temporary file
  rm /tmp/workflow.yaml
  
  # Extract just the workflow name without the prefix
  WORKFLOW_NAME=$(echo "$WORKFLOW_NAME" | cut -d'/' -f2)
  
  return 0
}

# Function to submit a batch inference workflow
submit_batch_workflow() {
  WORKFLOW_NAME="text-classification-batch-$(date +%s)"
  
  echo "Submitting batch inference workflow '$WORKFLOW_NAME'..."
  echo "Input file: $INPUT_FILE"
  
  # Create the input ConfigMap
  create_input_configmap
  
  # Create a temporary workflow file
  cat > /tmp/workflow.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: text-classification-batch-
  namespace: $NAMESPACE
spec:
  workflowTemplateRef:
    name: text-classification-batch-template
  arguments:
    parameters:
    - name: input-file
      value: "/inputs/$INPUT_FILE"
EOF
  
  # Submit the workflow
  WORKFLOW_NAME=$(kubectl create -f /tmp/workflow.yaml -o name)
  echo "Workflow submitted: $WORKFLOW_NAME"
  
  # Clean up the temporary file
  rm /tmp/workflow.yaml
  
  # Extract just the workflow name without the prefix
  WORKFLOW_NAME=$(echo "$WORKFLOW_NAME" | cut -d'/' -f2)
  
  return 0
}

# Function to monitor workflow execution
monitor_workflow() {
  echo "Monitoring workflow execution..."
  
  # Set timeout and polling interval
  TIMEOUT=120  # 2 minutes timeout
  INTERVAL=5   # Check every 5 seconds
  ELAPSED=0
  
  # Monitor the workflow with progress updates
  while [ $ELAPSED -lt $TIMEOUT ]; do
    # Check workflow status
    WORKFLOW_STATUS=$(kubectl get workflow/"$WORKFLOW_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
    
    # If we got a status and it's not running or pending, break the loop
    if [ ! -z "$WORKFLOW_STATUS" ] && [ "$WORKFLOW_STATUS" != "Running" ] && [ "$WORKFLOW_STATUS" != "Pending" ]; then
      break
    fi
    
    # Print current status with timestamp
    echo "[$(date +%H:%M:%S)] Workflow status: ${WORKFLOW_STATUS:-Initializing}..."
    
    # Show pods status
    echo "Current pods:"
    kubectl get pods -n "$NAMESPACE" -l workflows.argoproj.io/workflow="$WORKFLOW_NAME" --no-headers 2>/dev/null | head -3
    
    # Sleep for the interval
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    
    # If we're halfway through, show some logs to indicate progress
    if [ $ELAPSED -eq 60 ]; then
      echo "Checking workflow logs for progress:"
      kubectl logs -n "$NAMESPACE" -l workflows.argoproj.io/workflow="$WORKFLOW_NAME" --tail=5 2>/dev/null || echo "No logs available yet"
    fi
  done
  
  # Final status check
  WORKFLOW_STATUS=$(kubectl get workflow/"$WORKFLOW_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
  
  if [ -z "$WORKFLOW_STATUS" ]; then
    echo "Error: Could not determine workflow status. The workflow might still be initializing."
    echo "You can check the status manually with: kubectl get workflow/$WORKFLOW_NAME -n $NAMESPACE"
    exit 1
  fi
  
  if [ "$WORKFLOW_STATUS" == "Running" ] || [ "$WORKFLOW_STATUS" == "Pending" ]; then
    echo "Workflow is still running after timeout. You can continue to monitor it with:"
    echo "kubectl get workflow/$WORKFLOW_NAME -n $NAMESPACE"
    echo "argo watch -n $NAMESPACE $WORKFLOW_NAME"
    exit 0
  fi
  
  echo "Workflow completed with status: $WORKFLOW_STATUS"
  
  # Get the workflow results
  echo "Workflow results:"
  kubectl get workflow/"$WORKFLOW_NAME" -n "$NAMESPACE" -o json | jq '.status.nodes | map_values(select(.type == "Pod")) | map_values(.outputs.result)' 2>/dev/null || echo "Could not retrieve results"
  
  # Option to view logs
  read -p "Do you want to view the workflow logs? (y/n): " VIEW_LOGS
  if [ "$VIEW_LOGS" == "y" ] || [ "$VIEW_LOGS" == "Y" ]; then
    argo logs -n "$NAMESPACE" "$WORKFLOW_NAME" || echo "Could not retrieve logs"
  fi
}

# Main execution
echo "=== Argo Workflow Submission Tool ==="
echo "Workflow Type: $WORKFLOW_TYPE"
echo "Input Type: $INPUT_TYPE"

# Check prerequisites
check_argo_installed
check_namespace
check_workflow_templates

# Submit the appropriate workflow
if [ "$WORKFLOW_TYPE" == "single" ]; then
  submit_single_workflow
else
  submit_batch_workflow
fi

# Monitor the workflow execution
monitor_workflow

echo "=== Workflow submission completed ==="