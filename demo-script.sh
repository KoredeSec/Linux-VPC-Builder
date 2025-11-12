#!/bin/bash
# demo-script.sh - 5-minute demo for video recording

clear
echo "═══════════════════════════════════════"
echo "  VPC Project Demonstration"
echo "  HNG DevOps Stage 4"
echo "═══════════════════════════════════════"
echo ""
sleep 2

echo "▶ Part 1: Creating Production VPC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl create-vpc production 10.0.0.0/16
sleep 2

echo ""
echo "▶ Part 2: Adding Subnets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl add-subnet production web-tier 10.0.1.0/24 public
sleep 1
sudo ./vpcctl add-subnet production app-tier 10.0.2.0/24 private
sleep 1
sudo ./vpcctl add-subnet production db-tier 10.0.3.0/24 private
sleep 2

echo ""
echo "▶ Part 3: VPC Inventory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl list
sleep 3

echo ""
echo "▶ Part 4: Deploy Web Server in Public Subnet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
WEB_NS="ns-produc-web-ti"
mkdir -p /tmp/demo-web
echo "<h1>Production Web Server</h1>" > /tmp/demo-web/index.html
sudo ip netns exec $WEB_NS python3 -m http.server 80 &>/dev/null &
WEB_PID=$!
sleep 2
WEB_IP=$(sudo ip netns exec $WEB_NS ip addr show | grep "inet 10.0.1" | awk '{print $2}' | cut -d'/' -f1)
echo "✓ Web server running at http://$WEB_IP:80"
sleep 2

echo ""
echo "▶ Part 5: Testing Connectivity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -s http://$WEB_IP:80
echo ""
echo "✓ Web server accessible from host"
sleep 2

echo ""
echo "▶ Part 6: Testing Internet Access (NAT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ip netns exec $WEB_NS ping -c 3 8.8.8.8
sleep 2

echo ""
echo "▶ Part 7: Creating Staging VPC (Isolation Test)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl create-vpc staging 10.1.0.0/16
sudo ./vpcctl add-subnet staging web-tier 10.1.1.0/24 public
sleep 2

echo ""
echo "▶ Part 8: Testing VPC Isolation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
STAGING_NS="ns-stagin-web-ti"
STAGING_IP=$(sudo ip netns exec $STAGING_NS ip addr show | grep "inet 10.1.1" | awk '{print $2}' | cut -d'/' -f1)
echo "Attempting to ping staging VPC from production (should fail)..."
if sudo ip netns exec $WEB_NS ping -c 2 $STAGING_IP &>/dev/null; then
    echo "✗ VPCs not isolated!"
else
    echo "✓ VPCs are properly isolated"
fi
sleep 2

echo ""
echo "▶ Part 9: VPC Peering"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl peer-vpcs production staging
sleep 1
echo "Testing cross-VPC communication..."
if sudo ip netns exec $WEB_NS ping -c 2 $STAGING_IP &>/dev/null; then
    echo "✓ VPC peering successful!"
else
    echo "✗ Peering failed"
fi
sleep 2

echo ""
echo "▶ Part 10: Applying Firewall Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl apply-rules production web-tier examples/web-firewall.json
sleep 2

echo ""
echo "▶ Part 11: Final State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./vpcctl list
sleep 3

echo ""
echo "▶ Part 12: Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sudo ./cleanup.sh

echo ""
echo "═══════════════════════════════════════"
echo "  Demo Complete!"
echo "═══════════════════════════════════════"
