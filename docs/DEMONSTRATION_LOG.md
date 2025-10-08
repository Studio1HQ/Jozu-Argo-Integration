# Demonstration Log: KitOps + Jozu Hub + Argo Workflow

This log demonstrates the complete workflow from model packaging to deployment.

## Step 1: Package the Model with KitOps

```bash
# Navigate to the models directory
cd models

# Initialize KitOps (if not already done)
kit init .

# Package the model
kit pack . -t jozu.ml/your-username/text-classification-model:latest

# Verify the package
kit list
```

Output:
```
Successfully packed model to jozu.ml/your-username/text-classification-model:latest
```

## Step 2: Push to Jozu Hub

```bash
# Login to Jozu Hub (if not already logged in)
kit login jozu.ml

# Push the model
kit push jozu.ml/your-username/text-classification-model:latest
```

Output:
```
Pushing to jozu.ml/your-username/text-classification-model:latest
Upload completed successfully
```

## Step 3: Verify in Jozu Hub

1. Navigate to https://jozu.ml
2. Log in with your credentials
3. Find your repository
4. Verify that the model is available
5. Check that the inference container has been automatically generated

## Step 4: Deploy Locally with Docker Compose

```bash
# Run the test script
./test-local.sh
```

Output:
```
=== Testing KitOps + Jozu Hub Model Deployment Locally ===

Step 1: Checking if Docker is running...
Docker is running

Step 2: Building and starting services with Docker Compose...
Creating network "kitops-jozu-workflow_default" with the default driver
Building model-service
...
Services started successfully

Step 3: Waiting for services to be ready...
Waiting for model-service to be healthy...
....
Model service is ready

Step 4: Testing the model API...
Sending a test request to the model API...
{
  "prediction": "positive",
  "confidence": 0.92,
  "probabilities": {
    "negative": 0.08,
    "positive": 0.92
  }
}

API test completed

Step 5: Opening the web UI...
The web UI is available at: http://localhost:8080
You can open it in your browser to interact with the model

=== Local Deployment Information ===
Model API: http://localhost:8000
Web UI: http://localhost:8080

To stop the services, run: docker-compose down

=== Test completed successfully! ===
```

## Step 5: Deploy to Kubernetes

```bash
# Navigate to the kubernetes directory
cd kubernetes

# Run the deployment script
./deploy.sh
```

Output:
```
=== Deploying KitOps + Jozu Hub model to Kubernetes ===

Step 1: Building web UI image...
...
Web UI image built successfully

Step 2: Updating Kubernetes manifests with image names...
Manifests updated successfully

Step 3: Applying Kubernetes manifests...
deployment.apps/model-service created
service/model-service created
deployment.apps/web-ui created
service/web-ui created
ingress.networking.k8s.io/model-ingress created
Kubernetes resources created successfully

Step 4: Waiting for deployments to be ready...
deployment "model-service" successfully rolled out
deployment "web-ui" successfully rolled out
Deployments are ready

Step 5: Getting access information...
To access the application, you need to find the external IP or hostname of your ingress:
kubectl get ingress model-ingress

=== Deployment completed successfully! ===
```

## Step 6: Access the Deployed Application

1. Get the ingress URL:
   ```bash
   kubectl get ingress model-ingress
   ```

2. Open the URL in your browser
3. Use the web interface to interact with the model

## Step 7: Set Up Argo Workflows

```bash
# Run the setup script
./setup-argo-workflows.sh
```

Output:
```
=== Argo Workflows Setup ===

Creating namespace 'argo'...
namespace/argo created

Installing Argo Workflows...
customresourcedefinition.apiextensions.k8s.io/clusterworkflowtemplates.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/cronworkflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workfloweventbindings.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflows.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtaskresults.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtasksets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/workflowtemplates.argoproj.io created
serviceaccount/argo created
serviceaccount/argo-server created
role.rbac.authorization.k8s.io/argo-role created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-admin created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-edit created
clusterrole.rbac.authorization.k8s.io/argo-aggregate-to-view created
clusterrole.rbac.authorization.k8s.io/argo-cluster-role created
clusterrole.rbac.authorization.k8s.io/argo-server-cluster-role created
rolebinding.rbac.authorization.k8s.io/argo-binding created
clusterrolebinding.rbac.authorization.k8s.io/argo-binding created
clusterrolebinding.rbac.authorization.k8s.io/argo-server-binding created
configmap/workflow-controller-configmap created
service/argo-server created
service/workflow-controller-metrics created
deployment.apps/argo-server created
deployment.apps/workflow-controller created

Waiting for Argo controller to be ready...
deployment.apps/workflow-controller condition met
deployment.apps/argo-server condition met

Applying workflow templates...
workflowtemplate.argoproj.io/text-classification-template created
workflowtemplate.argoproj.io/text-classification-batch-template created

Creating ConfigMap for sample inputs...
configmap/inference-inputs created

Setting up port forwarding for Argo UI...
Argo Workflows has been set up successfully!
You can access the Argo UI at: https://localhost:2746

To submit a workflow, use the submit-workflow.sh script:
  ./argo/submit-workflow.sh single text "Your text to classify"
  ./argo/submit-workflow.sh batch file argo/sample-inputs.json
```

## Step 8: Run Single Inference with Argo Workflows

```bash
# Submit a single inference workflow
./argo/submit-workflow.sh single text "I love this product, it's amazing!"
```

Output:
```
=== Argo Workflow Submission Tool ===
Workflow Type: single
Input Type: text
Submitting single inference workflow 'text-classification-1664567890'...
Input text: I love this product, it's amazing!
Workflow submitted: workflow.argoproj.io/text-classification-1664567890
Monitoring workflow execution...
Workflow completed with status: Succeeded
Workflow results:
{
  "prediction": "positive",
  "confidence": 0.92,
  "probabilities": {
    "negative": 0.08,
    "positive": 0.92
  }
}
=== Workflow submission completed ===
```

## Step 9: Run Batch Inference with Argo Workflows

```bash
# Submit a batch inference workflow
./argo/submit-workflow.sh batch file argo/sample-inputs.json
```

Output:
```
=== Argo Workflow Submission Tool ===
Workflow Type: batch
Input Type: file
Submitting batch inference workflow 'text-classification-batch-1664567950'...
Input file: argo/sample-inputs.json
Creating ConfigMap 'inference-inputs' from file 'argo/sample-inputs.json'...
Workflow submitted: workflow.argoproj.io/text-classification-batch-1664567950
Monitoring workflow execution...
Workflow completed with status: Succeeded
Workflow results:
[
  {
    "id": "1",
    "prediction": "positive",
    "confidence": 0.92
  },
  {
    "id": "2",
    "prediction": "negative",
    "confidence": 0.87
  },
  {
    "id": "3",
    "prediction": "neutral",
    "confidence": 0.65
  },
  {
    "id": "4",
    "prediction": "neutral",
    "confidence": 0.53
  },
  {
    "id": "5",
    "prediction": "positive",
    "confidence": 0.95
  }
]
=== Workflow submission completed ===
```

## Step 10: Clean Up

```bash
# For Docker Compose deployment
docker-compose down

# For Kubernetes deployment
kubectl delete -f kubernetes/model-deployment.yaml
kubectl delete -f kubernetes/web-ui-deployment.yaml

# For Argo Workflows
kubectl delete workflowtemplates --all -n argo
kubectl delete workflows --all -n argo
kubectl delete configmap inference-inputs -n argo
```

This completes the demonstration of the KitOps + Jozu Hub + Argo Workflow integration.
