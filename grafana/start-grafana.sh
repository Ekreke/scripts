#!/bin/bash

# Grafana Service Startup Script
# This script builds and runs a Grafana container with persistent data

set -e

# Configuration
CONTAINER_NAME="grafana-service"
IMAGE_NAME="grafana-custom"
PORT="3000"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_warning "Container '${CONTAINER_NAME}' already exists. Stopping and removing it..."
    docker stop "${CONTAINER_NAME}" > /dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" > /dev/null 2>&1 || true
fi

# Create necessary directories for persistent storage
print_info "Creating directories for persistent storage..."
mkdir -p grafana-data/{data,provisioning,logs}

# Set proper permissions for Grafana (Grafana runs as user ID 472)
print_info "Setting proper permissions for Grafana..."
sudo chown -R 472:472 grafana-data/ 2>/dev/null || {
    print_warning "Could not set permissions with sudo. You may experience permission issues."
    print_warning "To fix this manually, run: sudo chown -R 472:472 grafana-data/"
}

# Build the Docker image
print_info "Building Grafana Docker image..."
docker build -t "${IMAGE_NAME}" .

# Run the container
print_info "Starting Grafana container..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${PORT}:3000" \
    -v "$(pwd)/grafana-data/data:/var/lib/grafana" \
    -v "$(pwd)/grafana-data/provisioning:/etc/grafana/provisioning" \
    -v "$(pwd)/grafana-data/logs:/var/log/grafana" \
    -e "GF_SECURITY_ADMIN_USER=${ADMIN_USER}" \
    -e "GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}" \
    -e "GF_SERVER_DOMAIN=localhost" \
    -e "GF_SERVER_ROOT_URL=http://localhost:${PORT}" \
    --restart unless-stopped \
    "${IMAGE_NAME}"

# Wait for Grafana to start
print_info "Waiting for Grafana to start..."
sleep 10

# Check if container is running
if docker ps --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_success "Grafana service started successfully!"
    echo ""
    echo "🚀 Grafana is running at: http://localhost:${PORT}"
    echo "👤 Login with:"
    echo "   Username: ${ADMIN_USER}"
    echo "   Password: ${ADMIN_PASSWORD}"
    echo ""
    echo "📁 Persistent data is stored in: $(pwd)/grafana-data/"
    echo ""
    echo "🛠️  Useful commands:"
    echo "   View logs: docker logs ${CONTAINER_NAME}"
    echo "   Stop service: ./stop-grafana.sh"
    echo "   Remove service: docker rm ${CONTAINER_NAME}"
else
    print_error "Failed to start Grafana service. Check the logs with 'docker logs ${CONTAINER_NAME}'"
    exit 1
fi