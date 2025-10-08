#!/bin/bash
# Script to clean up unnecessary files in the project directory

echo "=== Cleaning up project directory ==="

# Files to remove
echo "Removing unnecessary files..."

# Remove duplicate/redundant scripts
rm -f deploy-batch.sh
rm -f deploy.sh
rm -f run-argo-workflow.sh
rm -f .argo-port-forward.pid

# Remove redundant documentation files
rm -f DEPLOYMENT_SIMULATION.md
rm -f PIPELINE_STATUS.md

# Remove redundant workflow directory (since we have argo directory)
rm -rf workflow/

# Remove redundant authentication scripts (keep only the most comprehensive one)
rm -f setup-registry-auth.sh

# Organize the project structure
echo "Organizing project structure..."

# Create a docs directory and move documentation files there
mkdir -p docs
mv DEMONSTRATION_LOG.md docs/
mv DEPLOYMENT.md docs/
mv END_TO_END_GUIDE.md docs/
mv INTEGRATION.md docs/
mv MODEL_INTERACTION_GUIDE.md docs/
mv workflow-diagram.md docs/

echo "=== Cleanup completed ==="
echo "The project directory has been cleaned up and organized."
echo "Documentation files have been moved to the 'docs' directory."