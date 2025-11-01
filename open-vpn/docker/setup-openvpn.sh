#!/bin/bash

# OpenVPN Docker Setup Script

echo "Setting up OpenVPN with Docker..."

# Pull the OpenVPN Access Server Docker image
echo "Pulling OpenVPN Access Server image..."
docker pull openvpn/openvpn-as

# Set variable for OpenVPN data directory
OPENVPN_DATA_DIR="$HOME/./var/open-vpn-data"
OPENVPN_DATA_ABS_PATH=$(realpath "$OPENVPN_DATA_DIR")

# Create directory for OpenVPN data persistence
echo "Creating OpenVPN data directory at: $OPENVPN_DATA_ABS_PATH"
mkdir -p "$OPENVPN_DATA_DIR"

# Stop and remove existing container if it exists
echo "Removing existing OpenVPN container (if any)..."
docker stop openvpn-as 2>/dev/null || true
docker rm openvpn-as 2>/dev/null || true

# Run OpenVPN Access Server container
echo "Starting OpenVPN Access Server container..."
echo "Notification: port in use: 943 , 4443 , 1194"
docker run -d \
  --name=openvpn-as \
  --device /dev/net/tun \
  --cap-add=MKNOD --cap-add=NET_ADMIN \
  -p 943:943 -p 4443:443 -p 1194:1194/udp \
  -v "$OPENVPN_DATA_ABS_PATH:/openvpn" \
  --restart=unless-stopped \
  openvpn/openvpn-as

echo "OpenVPN setup completed!"
echo "Data directory: $OPENVPN_DATA_ABS_PATH"
echo "Access the admin interface at: https://localhost:943/admin"
echo "Important: please use https and accept the risk to proceed , when u not bind the ssl certificate"
