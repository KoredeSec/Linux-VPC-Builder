#!/bin/bash
# setup.sh - Quick project setup

set -e

GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

log "Setting up VPC Project..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Install packages (if not already installed)
log "Checking dependencies..."
apt-get update -qq
apt-get install -y \
    iproute2 \
    iptables \
    bridge-utils \
    python3 \
    net-tools \
    iputils-ping \
    curl \
    git \
    tree \
    &>/dev/null

# Enable IP forwarding
log "Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 &>/dev/null
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Make scripts executable
log "Setting permissions..."
chmod +x vpcctl test-vpc.sh cleanup.sh 2>/dev/null || true

log "✓ Setup complete!"
echo ""
echo "Quick Start:"
echo "  sudo ./vpcctl create-vpc myvpc 10.0.0.0/16"
echo "  sudo ./vpcctl add-subnet myvpc web 10.0.1.0/24 public"
echo "  sudo ./test-vpc.sh"
