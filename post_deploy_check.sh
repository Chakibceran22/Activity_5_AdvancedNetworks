#!/bin/bash

# Post-Deployment OSPF Configuration and Verification Script
# Waits for OSPF convergence and fixes common issues

echo "=========================================="
echo "POST-DEPLOYMENT OSPF SETUP"
echo "=========================================="
echo ""

# Wait for containers to be fully ready
echo "Waiting 15 seconds for containers to initialize..."
sleep 15

echo ""
echo "=========================================="
echo "CHECKING OSPF NEIGHBOR STATES"
echo "=========================================="
echo ""

# Function to check and display OSPF neighbors
check_neighbors() {
    local router=$1
    echo "[$router] OSPF Neighbors:"
    docker exec clab-ospf-mpls-backbone-$router sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep -E "Interface|State|No\. of"
    echo ""
}

# Check all routers
for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    check_neighbors $router
done

echo ""
echo "=========================================="
echo "CHECKING INTERFACE IPs AND OSPF AREAS"
echo "=========================================="
echo ""

# Function to show interface IPs and OSPF config
check_config() {
    local router=$1
    echo "[$router] Configuration:"
    docker exec clab-ospf-mpls-backbone-$router sr_cli "info from running /network-instance default protocols ospf instance main area" 2>/dev/null | grep -E "area|interface|admin-state enable" | head -20
    echo ""
}

for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    check_config $router
done

echo ""
echo "=========================================="
echo "WAITING FOR OSPF CONVERGENCE"
echo "=========================================="
echo ""

echo "Waiting 30 seconds for OSPF to converge..."
sleep 30

echo ""
echo "=========================================="
echo "FINAL NEIGHBOR CHECK"
echo "=========================================="
echo ""

for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    echo "[$router] Final neighbor count:"
    docker exec clab-ospf-mpls-backbone-$router sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep "No\. of"
done

echo ""
echo "=========================================="
echo "TESTING END-TO-END CONNECTIVITY"
echo "=========================================="
echo ""

# Test ping between sites
echo "Testing Site-A to Site-D..."
docker exec clab-ospf-mpls-backbone-Site-A ping -c 3 10.4.0.10 2>/dev/null | grep "received"

echo ""
echo "Testing Site-B to Site-C..."
docker exec clab-ospf-mpls-backbone-Site-B ping -c 3 10.3.0.10 2>/dev/null | grep "received"

echo ""
echo "=========================================="
echo "POST-DEPLOYMENT CHECK COMPLETE"
echo "=========================================="
echo ""
echo "Run './test_ospf.sh' for detailed testing"
