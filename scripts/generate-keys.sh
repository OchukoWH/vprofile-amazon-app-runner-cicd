#!/bin/bash

# Generate SSH key pair for Kubernetes cluster
# This script creates a new SSH key pair in the project directory

set -e

KEY_NAME="k8s-cluster-key"
PRIVATE_KEY_FILE="${KEY_NAME}"
PUBLIC_KEY_FILE="${KEY_NAME}.pub"

echo "Generating SSH key pair for Kubernetes cluster..."

# Check if keys already exist
if [ -f "$PRIVATE_KEY_FILE" ] || [ -f "$PUBLIC_KEY_FILE" ]; then
    echo "SSH keys already exist!"
    echo "   Private key: $PRIVATE_KEY_FILE"
    echo "   Public key: $PUBLIC_KEY_FILE"
    echo ""
    read -p "Do you want to overwrite them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Key generation cancelled."
        exit 1
    fi
    echo "Removing existing keys..."
    rm -f "$PRIVATE_KEY_FILE" "$PUBLIC_KEY_FILE"
fi

# Generate new SSH key pair
echo "Generating new SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_FILE" -N "" -C "k8s-cluster-$(date +%Y%m%d)"

# Set proper permissions
chmod 600 "$PRIVATE_KEY_FILE"
chmod 644 "$PUBLIC_KEY_FILE"