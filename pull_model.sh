#!/bin/bash
set -e

echo "=== Pulling Model from Jozu Hub ==="
echo ""

# Check if KitOps CLI is installed
if ! command -v kit &> /dev/null; then
    echo "KitOps CLI is not installed. Installing now..."
    curl -sSL https://get.kitops.org | sh
    echo "KitOps CLI installed successfully"
else
    echo "KitOps CLI is already installed"
fi

# Pull the model from Jozu Hub
echo ""
echo "Pulling model from Jozu Hub..."
kit pull jozu.ml/siddhesh-bangar/text-classification-model:latest

echo ""
echo "=== Model pulled successfully! ==="
echo "You can now run the deployment with:"
echo "  ./test-local.sh"