#!/bin/bash
# cleanup.sh - Emergency cleanup script

set +e  # Don't exit on errors

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[CLEANUP]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

log "Starting cleanup..."

# Kill any web servers
log "Stopping web servers..."
pkill -f "python3 -m http.server" || true
pkill -f "nginx" || true

# Delete all test VPCs via vpcctl
log "Deleting VPCs via vpcctl..."
./vpcctl delete-vpc vpc1 2>/dev/null || true
./vpcctl delete-vpc vpc2 2>/dev/null || true
./vpcctl delete-vpc test 2>/dev/null || true

# Manual cleanup of any remaining resources
log "Cleaning remaining namespaces..."
for ns in $(ip netns list 2>/dev/null | awk '{print $1}'); do
    ip netns delete $ns 2>/dev/null || true
done

log "Cleaning bridges..."
for br in $(ip link show | grep "br-" | awk -F: '{print $2}' | tr -d ' '); do
    ip link set $br down 2>/dev/null || true
    ip link delete $br 2>/dev/null || true
done

log "Cleaning veth pairs..."
for veth in $(ip link show | grep "veth" | awk -F: '{print $2}' | tr -d ' '); do
    ip link delete $veth 2>/dev/null || true
done

log "✓ Cleanup complete!"
echo ""
echo "Verification:"
echo "  Namespaces: $(ip netns list | wc -l) remaining"
echo "  Bridges: $(ip link show | grep -c 'br-' || echo 0) remaining"
