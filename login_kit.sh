#!/bin/bash
set -e

echo "=== KitOps Login Helper ==="
echo ""

# Check if KitOps CLI is installed
if ! command -v kit &> /dev/null; then
    echo "KitOps CLI is not installed. Installing now..."
    curl -sSL https://get.kitops.org | sh
    echo "KitOps CLI installed successfully"
else
    echo "KitOps CLI is already installed"
fi

# Prompt for Jozu Hub credentials
echo ""
echo "Please enter your Jozu Hub credentials:"
read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo ""

# Login to Jozu Hub
echo ""
echo "Logging in to Jozu Hub..."
echo "$PASSWORD" | kit login jozu.ml --username "$USERNAME" --password-stdin

echo ""
echo "=== Login successful! ==="
echo "You can now use KitOps to push and pull models from Jozu Hub"
echo ""
echo "Example commands:"
echo "  kit pack ./models -t jozu.ml/$USERNAME/text-classification-model:latest"
echo "  kit push jozu.ml/$USERNAME/text-classification-model:latest"
echo ""