#!/bin/bash

# Grafana Service Stop Script
# This script stops and removes the Grafana container

set -e

# Configuration
CONTAINER_NAME="grafana-service"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop and remove container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_info "Stopping Grafana service..."
    docker stop "${CONTAINER_NAME}" > /dev/null 2>&1 || true

    print_info "Removing Grafana container..."
    docker rm "${CONTAINER_NAME}" > /dev/null 2>&1 || true

    print_success "Grafana service stopped successfully!"
else
    print_warning "Grafana service is not running."
fi

# Optionally remove Docker image
read -p "Do you want to remove the Grafana Docker image as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing Grafana Docker image..."
    docker rmi grafana-custom > /dev/null 2>&1 || true
    print_success "Grafana Docker image removed!"
fi