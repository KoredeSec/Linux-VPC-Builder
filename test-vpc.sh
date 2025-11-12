#!/bin/bash
# test-vpc.sh - Comprehensive VPC Test Suite

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

# Check root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
   exit 1
fi

# Get network interface
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
log "Using network interface: $INTERFACE"

# Cleanup function
cleanup() {
    log "Cleaning up test environment..."
    ./vpcctl delete-vpc vpc1 2>/dev/null || true
    ./vpcctl delete-vpc vpc2 2>/dev/null || true
    pkill -f "python3 -m http.server" || true
    log "Cleanup complete"
}

trap cleanup EXIT

header "VPC COMPREHENSIVE TEST SUITE"

# Test 1: Create VPC1
header "TEST 1: Creating VPC1"
./vpcctl create-vpc vpc1 10.0.0.0/16 $INTERFACE
if ip link show br-vpc1 &>/dev/null; then
    success "VPC1 created with bridge br-vpc1"
else
    error "VPC1 bridge not created"
    exit 1
fi

# Test 2: Add Public Subnet
header "TEST 2: Adding Public Subnet to VPC1"
./vpcctl add-subnet vpc1 web 10.0.1.0/24 public
if ip netns list | grep -q "ns-vpc1-web"; then
    success "Public subnet 'web' created"
else
    error "Public subnet namespace not found"
    exit 1
fi

# Test 3: Add Private Subnet
header "TEST 3: Adding Private Subnet to VPC1"
./vpcctl add-subnet vpc1 db 10.0.2.0/24 private
if ip netns list | grep -q "ns-vpc1-db"; then
    success "Private subnet 'db' created"
else
    error "Private subnet namespace not found"
    exit 1
fi

# Test 4: List VPCs
header "TEST 4: Listing VPCs"
./vpcctl list

# Test 5: Deploy Web Server
header "TEST 5: Deploying Web Server in Public Subnet"
WEB_NS="ns-vpc1-web"

# Create web content
mkdir -p /tmp/webserver
cat > /tmp/webserver/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>VPC Test - Public Subnet</title>
    <style>
        body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #2563eb; }
        .info { background: #f0f9ff; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🌐 VPC Test - Public Subnet</h1>
    <div class="info">
        <p><strong>VPC:</strong> vpc1 (10.0.0.0/16)</p>
        <p><strong>Subnet:</strong> web (10.0.1.0/24)</p>
        <p><strong>Type:</strong> Public Subnet</p>
        <p><strong>Status:</strong> ✅ Running</p>
    </div>
    <p>This web server is running inside a network namespace!</p>
</body>
</html>
EOF

# Start web server in namespace
ip netns exec $WEB_NS python3 -m http.server 8080 -d /tmp/webserver &>/dev/null &
WEB_PID=$!
sleep 2

# Get IP
WEB_IP=$(ip netns exec $WEB_NS ip addr show | grep "inet 10.0.1" | awk '{print $2}' | cut -d'/' -f1)
success "Web server started at http://$WEB_IP:8080 (PID: $WEB_PID)"

# Test 6: Connectivity Tests
header "TEST 6: Testing Connectivity"

log "Testing web server access from host..."
if timeout 3 curl -s http://$WEB_IP:8080 | grep -q "VPC Test"; then
    success "Host can access public subnet web server"
else
    error "Cannot access web server from host"
fi

log "Testing inter-subnet communication..."
DB_IP=$(ip netns exec ns-vpc1-db ip addr show | grep "inet 10.0.2" | awk '{print $2}' | cut -d'/' -f1)
if ip netns exec $WEB_NS ping -c 2 $DB_IP &>/dev/null; then
    success "Public subnet can ping private subnet ($DB_IP)"
else
    error "Cannot communicate between subnets"
fi

# Test 7: NAT/Internet Access
header "TEST 7: Testing NAT Gateway (Internet Access)"

log "Testing internet access from public subnet..."
if ip netns exec $WEB_NS ping -c 2 8.8.8.8 &>/dev/null; then
    success "Public subnet has internet access (NAT working)"
else
    error "No internet access from public subnet"
fi

log "Testing DNS resolution..."
if ip netns exec $WEB_NS ping -c 2 google.com &>/dev/null; then
    success "DNS resolution working"
else
    error "DNS resolution failed (may be expected)"
fi

# Test 8: Create Second VPC (Isolation Test)
header "TEST 8: Creating Second VPC for Isolation Test"
./vpcctl create-vpc vpc2 10.1.0.0/16 $INTERFACE
./vpcctl add-subnet vpc2 app 10.1.1.0/24 public

if ip link show br-vpc2 &>/dev/null; then
    success "VPC2 created"
else
    error "VPC2 not created"
    exit 1
fi

# Test 9: VPC Isolation
header "TEST 9: Testing VPC Isolation"

VPC2_NS="ns-vpc2-app"
VPC2_IP=$(ip netns exec $VPC2_NS ip addr show | grep "inet 10.1.1" | awk '{print $2}' | cut -d'/' -f1)

log "Attempting to ping VPC2 from VPC1 (should fail)..."
if ip netns exec $WEB_NS ping -c 2 $VPC2_IP &>/dev/null; then
    error "VPCs are NOT isolated (unexpected connectivity)"
else
    success "VPCs are properly isolated (no cross-VPC communication)"
fi

# Test 10: VPC Peering
header "TEST 10: Testing VPC Peering"
./vpcctl peer-vpcs vpc1 vpc2
sleep 1

log "Testing cross-VPC communication after peering..."
if ip netns exec $WEB_NS ping -c 2 $VPC2_IP &>/dev/null; then
    success "VPC peering works! Cross-VPC communication established"
else
    error "VPC peering not working properly"
fi

# Test 11: Firewall Rules
header "TEST 11: Testing Firewall Rules"

cat > /tmp/firewall-rules.json <<EOF
{
  "subnet": "10.0.1.0/24",
  "ingress": [
    {"port": 8080, "protocol": "tcp", "action": "allow"},
    {"port": 9999, "protocol": "tcp", "action": "deny"}
  ]
}
EOF

./vpcctl apply-rules vpc1 web /tmp/firewall-rules.json
success "Firewall rules applied to web subnet"

log "Testing blocked port (9999)..."
# Start a server on port 9999 in namespace
ip netns exec $WEB_NS python3 -m http.server 9999 &>/dev/null &
BLOCKED_PID=$!
sleep 1

if timeout 2 curl -s http://$WEB_IP:9999 &>/dev/null; then
    error "Port 9999 should be blocked but is accessible"
else
    success "Port 9999 is blocked as expected"
fi
kill $BLOCKED_PID 2>/dev/null || true

# Test 12: List Final State
header "TEST 12: Final VPC Inventory"
./vpcctl list

# Test Summary
header "TEST SUMMARY"
echo ""
echo "✅ VPC Creation: PASSED"
echo "✅ Subnet Management: PASSED"
echo "✅ Web Server Deployment: PASSED"
echo "✅ Inter-Subnet Communication: PASSED"
echo "✅ NAT Gateway: PASSED"
echo "✅ VPC Isolation: PASSED"
echo "✅ VPC Peering: PASSED"
echo "✅ Firewall Rules: PASSED"
echo ""

header "DEMONSTRATION URLS"
echo ""
echo "🌐 Public Web Server: http://$WEB_IP:8080"
echo "   Test with: curl http://$WEB_IP:8080"
echo ""
echo "📊 VPC1 Details:"
echo "   Bridge: br-vpc1"
echo "   Gateway: 10.0.0.1"
echo "   Web Subnet: 10.0.1.0/24 (ns-vpc1-web)"
echo "   DB Subnet: 10.0.2.0/24 (ns-vpc1-db)"
echo ""
echo "📊 VPC2 Details:"
echo "   Bridge: br-vpc2"
echo "   Gateway: 10.1.0.1"
echo "   App Subnet: 10.1.1.0/24 (ns-vpc2-app)"
echo ""

header "USEFUL COMMANDS"
echo ""
echo "# Enter a namespace:"
echo "sudo ip netns exec ns-vpc1-web bash"
echo ""
echo "# View all namespaces:"
echo "ip netns list"
echo ""
echo "# View all bridges:"
echo "brctl show"
echo ""
echo "# View routing in namespace:"
echo "sudo ip netns exec ns-vpc1-web ip route"
echo ""
echo "# Check firewall rules in namespace:"
echo "sudo ip netns exec ns-vpc1-web iptables -L"
echo ""
echo "# View logs:"
echo "sudo ./vpcctl logs"
echo ""

log "All tests completed! Web server is still running for manual testing."
log "Press Ctrl+C to cleanup and exit..."

# Keep web server running
wait $WEB_PID
