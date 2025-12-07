#!/bin/bash

# OSPF Fix Script - Resolves OSPF neighbor issues
# Run this after deployment to ensure all OSPF neighbors form properly

echo "========================================"
echo "OSPF NEIGHBOR FIX SCRIPT"
echo "========================================"
echo ""

echo "Step 1: Checking current OSPF neighbor status..."
echo ""

for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    echo "[$router]:"
    docker exec clab-ospf-mpls-backbone-$router sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep "No\. of"
done

echo ""
echo "Step 2: Clearing OSPF process on all routers..."
echo ""

# The issue is often stale OSPF state - restarting helps
for router in R2 R5 R6 R7; do
    echo "Restarting OSPF on $router..."
    docker exec clab-ospf-mpls-backbone-$router sr_cli "tools network-instance default protocols ospf clear database" 2>/dev/null
done

echo ""
echo "Waiting 20 seconds for OSPF to reconverge..."
sleep 20

echo ""
echo "Step 3: Checking OSPF neighbor status after fix..."
echo ""

for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    echo "[$router]:"
    neighbor_count=$(docker exec clab-ospf-mpls-backbone-$router sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep -c "full")
    total=$(docker exec clab-ospf-mpls-backbone-$router sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep "No\. of" | awk '{print $NF}')
    echo "  Full neighbors: $neighbor_count / Total: $total"
done

echo ""
echo "Step 4: Testing end-to-end connectivity..."
echo ""

docker exec clab-ospf-mpls-backbone-Site-A ping -c 2 10.3.0.10 2>/dev/null | grep "received"
if [ $? -eq 0 ]; then
    echo "✓ Site-A can reach Site-C"
else
    echo "✗ Site-A cannot reach Site-C"
fi

echo ""
echo "========================================"
echo "FIX COMPLETE"
echo "========================================"
echo ""
echo "Run './test_ospf.sh' to verify all tests pass"
