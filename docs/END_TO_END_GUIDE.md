# End-to-End Guide: KitOps + Jozu Hub + Argo Workflows

This guide demonstrates the actual end-to-end workflow from model packaging to inference using KitOps, Jozu Hub, and Argo Workflows. Each step includes real commands and expected outputs.

## Prerequisites

Ensure you have the following installed:
- Docker and Docker Compose
- Kubernetes cluster (minikube, kind, or a cloud provider)
- kubectl configured to access your cluster
- KitOps CLI (`kit`)
- Argo Workflows CLI (`argo`)

## Step 1: Direct Pod Deployment (Optional)

If you want to deploy the model directly as a Kubernetes pod without using Argo Workflows:

```bash
# Run the deployment script
./deploy-model-pod.sh
```

This script:
1. Sets up authentication for Jozu Hub if needed
2. Deploys the model pod using the provided YAML manifest
3. Waits for the pod to be ready
4. Provides instructions for interacting with the pod

Once deployed, you can interact with the model pod:

```bash
# Execute commands in the pod
kubectl exec -it text-classification-model-basic -- /bin/bash

# Check the pod logs
kubectl logs text-classification-model-basic
```

Once you're inside the pod, refer to the [Model Interaction Guide](MODEL_INTERACTION_GUIDE.md) for detailed instructions on how to:
- Start the model server
- Make inference requests
- Explore the model files
- Run Python interactive sessions with the model
- Set up port forwarding for external access

## Step 2: Package and Push the Model to Jozu Hub

First, we'll package our text classification model and push it to Jozu Hub:

```bash
# Login to Jozu Hub
kit login jozu.ml
# Enter your credentials when prompted

# Navigate to the models directory
cd models

# Package the model
kit pack . -t jozu.ml/your-username/text-classification-model:latest

# Push the model to Jozu Hub
kit push jozu.ml/your-username/text-classification-model:latest
```

Verify on the Jozu Hub website (https://jozu.ml) that your model is available and that an inference container has been automatically generated.

## Step 3: Set Up Jozu Hub Authentication

Before we can use the Jozu Hub image (`jozu.ml/siddhesh-bangar/text-classification-model/basic:latest`) in our workflows, we need to set up authentication:

```bash
# Run the Jozu Hub authentication setup script
./setup-jozu-auth.sh
```

This script:
1. Creates a Docker registry secret for Jozu Hub
2. Creates a service account that uses this secret
3. Tests pulling the image to verify authentication works
4. Configures the workflow templates to use this service account

> **Note**: This script will prompt you for your Jozu Hub credentials to create the necessary authentication secret.

## Step 4: Set Up Argo Workflows in Kubernetes

Now, we'll set up Argo Workflows in our Kubernetes cluster:

```bash
# Run the setup script
./setup-argo-workflows.sh
```

This script:
1. Creates the `argo` namespace
2. Installs Argo Workflows
3. Applies our workflow templates
4. Creates a ConfigMap for sample inputs
5. Sets up port forwarding for the Argo UI

Verify that Argo Workflows is running:

```bash
kubectl get pods -n argo
```

You should see pods for `workflow-controller` and `argo-server` running.

## Step 5: Apply the Workflow Templates

The workflow templates define how our model will be used for inference:

```bash
kubectl apply -f argo/workflow-template.yaml -n argo
```

Verify that the templates are created:

```bash
kubectl get workflowtemplates -n argo
```

You should see:
```
NAME                               AGE
text-classification-template       1m
text-classification-batch-template 1m
```

## Step 6: Run a Single Inference Workflow

Now, let's run a single inference workflow. You have two options:

### Option 1: Using the original workflow template (requires authentication)

```bash
./argo/submit-workflow.sh single text "I love this product, it's amazing!"
```

### Option 2: Using the public workflow template (works without authentication)

If you're experiencing image pull errors with the original workflow, use this option:

```bash
./argo/submit-public-workflow.sh single text "I love this product, it's amazing!"
```

This uses a workflow template that only relies on publicly available images (python:3.9-slim) and includes a simple sentiment analysis implementation that doesn't require pulling from private registries.

Both scripts will:
1. Create a workflow based on the template
2. Submit it to Argo Workflows
3. Monitor its execution
4. Display the results

You can also check the workflow status in the Argo UI at https://localhost:2746

## Step 7: Run a Batch Inference Workflow

For batch processing, we'll use the sample inputs file. Again, you have two options:

### Option 1: Using the original workflow template (requires authentication)

```bash
./argo/submit-workflow.sh batch file argo/sample-inputs.json
```

### Option 2: Using the public workflow template (works without authentication)

```bash
./argo/submit-public-workflow.sh batch file argo/sample-inputs.json
```

Both will:
1. Create a ConfigMap with the input data
2. Submit a batch workflow
3. Process all inputs in parallel
4. Collect and display the results

## Step 8: Examine the Workflow in Detail

Let's look at what's happening under the hood:

1. **Pull Model Step**: The workflow pulls the model from Jozu Hub using KitOps:
   ```bash
   argo logs -n argo <workflow-name> pull-model
   ```

   Output should show:
   ```
   Pulling model from Jozu Hub...
   kit pull jozu.ml/siddhesh-bangar/text-classification-model:latest
   Model pulled successfully
   ```

2. **Inference Step**: The workflow then runs inference using the Jozu Hub container:
   ```bash
   argo logs -n argo <workflow-name> run-inference
   ```

   Output should show:
   ```
   Running inference on input: I love this product, it's amazing!
   {"prediction": "positive", "confidence": 0.92, ...}
   ```

3. **For batch workflows**, examine the fan-out process:
   ```bash
   argo get -n argo <batch-workflow-name>
   ```

   This shows how the workflow processes multiple inputs in parallel.

## Step 9: Integration Points

Let's examine the key integration points:

1. **KitOps to Jozu Hub**: The model is packaged with KitOps and pushed to Jozu Hub, which automatically generates an inference container.

2. **Jozu Hub to Argo Workflows**: The workflow template directly references the Jozu Hub container image:
   ```yaml
   container:
     image: jozu.ml/siddhesh-bangar/text-classification-model:latest
   ```

3. **Argo Workflows Orchestration**: Argo handles the workflow execution, parallelization, and result collection.

## Step 10: Verify the Results

For single inference:
```bash
argo get -n argo <workflow-name> -o json | jq '.status.nodes | map_values(select(.type == "Pod")) | map_values(.outputs.result)'
```

For batch inference:
```bash
argo get -n argo <batch-workflow-name> -o json | jq '.status.nodes | map_values(select(.displayName | startswith("inference-"))) | map_values(.outputs.result)'
```

## Step 11: Clean Up

When you're done, clean up the resources:

```bash
# Delete workflows
kubectl delete workflows --all -n argo

# Delete workflow templates
kubectl delete workflowtemplates --all -n argo

# Delete ConfigMap
kubectl delete configmap inference-inputs -n argo

# If you deployed the model pod directly
kubectl delete pod text-classification-model-basic
```

## Troubleshooting

### Public Workflow Templates

If you're experiencing persistent image pull errors, the simplest solution is to use the public workflow templates:

```bash
# Run the public workflow submission script
./argo/submit-public-workflow.sh single text "Your text here"
```

These templates use only publicly available images (python:3.9-slim) and include a simple sentiment analysis implementation that doesn't require pulling from private registries.

### Automated Troubleshooting Script

If you want to diagnose and fix the image pull issues with the original workflow templates, you can use the automated troubleshooting script:

```bash
# Run the troubleshooting script
./troubleshoot-image-pull.sh
```

This script will:
1. Check for workflows and pods with errors
2. Test pulling the required images directly
3. Help set up authentication for the registries
4. Patch workflow templates to use the correct service account
5. Provide detailed diagnostic information

### Image Pull Errors

If you see `ErrImagePull` or `ImagePullBackOff` errors:

```
text-classification-pvcvs-pull-model-1700363389   1/2   ErrImagePull   0     5s
text-classification-pvcvs-pull-model-1700363389   1/2   ImagePullBackOff   0     21s
```

This means Kubernetes cannot pull the specified image. This could be due to:

1. The image doesn't exist in the registry
2. Your cluster doesn't have access to the registry
3. Authentication issues with the registry

**Solution**:

```bash
# Run the automated troubleshooting script
./troubleshoot-image-pull.sh

# Or run the Jozu Hub authentication setup script
./setup-jozu-auth.sh

# Check the detailed error message
kubectl describe pod -n argo <pod-name>

# Look for events related to image pulling
```

If you're still having issues, you can manually test pulling the image:

```bash
# Test pulling the Jozu Hub image
kubectl run test-jozu --image=jozu.ml/siddhesh-bangar/text-classification-model/basic:latest \
  --restart=Never --serviceaccount=workflow-service-account -n argo -- sleep 60

# Check the pod status
kubectl get pod test-jozu -n argo

# Check for detailed errors
kubectl describe pod test-jozu -n argo

# Clean up when done
kubectl delete pod test-jozu -n argo
```

### Workflow Stuck in Pending or Running State

If your workflow seems to be stuck:

1. **Check the workflow status**:
   ```bash
   kubectl get workflow -n argo <workflow-name>
   ```

2. **Check the pods created by the workflow**:
   ```bash
   kubectl get pods -n argo -l workflows.argoproj.io/workflow=<workflow-name>
   ```

3. **Check pod logs for errors**:
   ```bash
   kubectl logs -n argo -l workflows.argoproj.io/workflow=<workflow-name>
   ```

4. **Check events for resource issues**:
   ```bash
   kubectl get events -n argo --sort-by='.lastTimestamp'
   ```

### Common Issues and Solutions

1. **Image Pull Errors**: If the workflow can't pull the Jozu Hub image:
   - Verify that the image exists in Jozu Hub
   - Check if your cluster has access to Jozu Hub
   - Try manually pulling the image: `docker pull jozu.ml/your-username/text-classification-model:latest`

2. **Resource Constraints**: If pods are pending due to insufficient resources:
   - Check resource requests in the workflow template
   - Increase cluster resources or reduce requests

3. **Permission Issues**: If the workflow fails due to permissions:
   - Verify that the service account has the necessary permissions
   - Check RBAC settings in your cluster

4. **Network Issues**: If the workflow can't communicate with services:
   - Check network policies
   - Verify that DNS resolution is working correctly

5. **Timeout Issues**: If the monitoring script times out:
   - Increase the TIMEOUT value in the submit-workflow.sh script
   - Use `argo watch -n argo <workflow-name>` to monitor long-running workflows

## Conclusion

This end-to-end guide demonstrates the complete integration between KitOps, Jozu Hub, and Argo Workflows:

1. KitOps packages the model and pushes it to Jozu Hub
2. Jozu Hub automatically generates an inference container
3. Argo Workflows orchestrates the inference process
4. The workflow pulls the model using KitOps
5. The workflow runs inference using the Jozu Hub container
6. Results are collected and displayed

This integration provides a powerful, scalable, and flexible solution for ML model deployment and inference.