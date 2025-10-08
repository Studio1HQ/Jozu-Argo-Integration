# KitOps + Jozu Hub + Argo Workflow Integration

This project demonstrates how to deploy a machine learning model using KitOps, Jozu Hub, and Argo Workflows, making it accessible to third-party users through Docker or Kubernetes.

## Overview

This project showcases:

1. **Model Packaging** with KitOps
2. **Model Registry** with Jozu Hub
3. **Inference API** automatically generated from the model
4. **Web UI** for easy interaction with the model
5. **Deployment Options** for both Docker and Kubernetes

## Project Structure

For a detailed explanation of the project structure, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md).

```
kitops-jozu-workflow/
├── models/                  # Model files and KitOps packaging
│   ├── Dockerfile           # Container definition for the model
│   ├── inference_server.py  # Flask API for model inference
│   └── requirements.txt     # Python dependencies
│
├── web-ui/                  # Web interface for the model
│   ├── Dockerfile           # Container definition for the UI
│   ├── nginx.conf           # Nginx configuration
│   └── html/                # Static web files
│
├── kubernetes/              # Kubernetes deployment files
│   ├── model-deployment.yaml # Model service deployment
│   ├── web-ui-deployment.yaml # Web UI deployment
│   └── model-pod.yaml       # Direct model pod deployment
│
├── argo/                    # Argo Workflow integration
│   ├── workflow-template.yaml # Workflow templates for inference
│   ├── public-workflow-template.yaml # Templates using only public images
│   ├── submit-workflow.sh   # Script to submit and monitor workflows
│   ├── submit-public-workflow.sh # Script for workflows with public images
│   └── sample-inputs.json   # Example input file for batch processing
│
├── docs/                    # Documentation files
│   ├── DEPLOYMENT.md        # Detailed deployment instructions
│   ├── END_TO_END_GUIDE.md  # Complete walkthrough with real commands
│   └── MODEL_INTERACTION_GUIDE.md # Guide for interacting with the model pod
│
├── docker-compose.yml       # Local deployment with Docker Compose
├── pull_model.sh            # Script to pull model from Jozu Hub
├── test-local.sh            # Script to test local deployment
├── deploy-model-pod.sh      # Script to deploy model directly as a pod
├── setup-argo-workflows.sh  # Script to set up Argo Workflows
├── setup-jozu-auth.sh       # Script to set up Jozu Hub authentication
├── troubleshoot-image-pull.sh # Script to diagnose and fix image pull issues
└── cleanup.sh               # Script to clean up project directory
```

## Quick Start

### Step 1: Pull the Model from Jozu Hub

```bash
# Make sure you're logged in to Jozu Hub
./login_kit.sh

# Pull the model
./pull_model.sh
```

### Step 2: Local Deployment with Docker

```bash
# This will pull the model if needed and deploy with Docker Compose
./test-local.sh
```

### Step 3: Direct Pod Deployment (Optional)

```bash
# Deploy the model directly as a Kubernetes pod
./deploy-model-pod.sh

# Once deployed, access the pod shell
kubectl exec -it text-classification-model-basic -- /bin/bash
```

### Step 4: Kubernetes Deployment (Optional)

```bash
cd kubernetes
./deploy.sh
```

### Step 5: Run Inference with Argo Workflows (Optional)

```bash
# Apply the workflow templates
kubectl apply -f argo/workflow-template.yaml -n argo
kubectl apply -f argo/public-workflow-template.yaml -n argo

# Option 1: Run with original templates (requires authentication)
./argo/submit-workflow.sh single text "Your text to classify"
./argo/submit-workflow.sh batch file argo/sample-inputs.json

# Option 2: Run with public templates (works without authentication)
./argo/submit-public-workflow.sh single text "Your text to classify"
./argo/submit-public-workflow.sh batch file argo/sample-inputs.json
```

## Key Features

- **Pre-built Inference Container**: The model is already packaged and available in Jozu Hub
- **Automatic API Generation**: Jozu Hub automatically creates an inference API based on the model type
- **User-friendly Interface**: Web UI for easy interaction with the model
- **Multiple Deployment Options**: Support for Docker, direct Kubernetes pod, and full Kubernetes deployment
- **Argo Workflow Integration**: Run model inference as Kubernetes workflows
- **Batch Processing**: Process multiple inputs in parallel using Argo Workflows
- **Direct Pod Interaction**: Ability to deploy and interact with the model directly as a Kubernetes pod
- **Public Image Workflows**: Option to run workflows using only publicly available images

## Prerequisites

- Docker and Docker Compose for local deployment
- Kubernetes and kubectl for cloud deployment
- KitOps CLI for model packaging and pulling
- Jozu Hub account for model registry
- Argo Workflows installed in your Kubernetes cluster (for workflow execution)

## Project Maintenance

To clean up unnecessary files and organize the project structure:

```bash
# Run the cleanup script
./cleanup.sh
```

This will remove redundant files and organize documentation into a dedicated `docs` directory.
