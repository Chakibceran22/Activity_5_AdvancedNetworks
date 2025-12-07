#!/bin/bash

# OSPF Network Testing Script
# Tests connectivity and OSPF neighbor relationships for all 8 routers

echo "=========================================="
echo "OSPF BACKBONE NETWORK TEST"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to test OSPF neighbors
test_ospf_neighbors() {
    local router=$1
    local expected_neighbors=$2

    echo "Testing $router OSPF Neighbors..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Get OSPF neighbor count from FRR
    neighbor_output=$(docker exec clab-ospf-mpls-backbone-$router vtysh -c "show ip ospf neighbor" 2>/dev/null)

    if [ $? -eq 0 ]; then
        neighbor_count=$(echo "$neighbor_output" | grep -c "Full" 2>/dev/null)
        # Ensure it's a valid number
        if ! [[ "$neighbor_count" =~ ^[0-9]+$ ]]; then
            neighbor_count=0
        fi

        if [ "$neighbor_count" -ge "$expected_neighbors" ]; then
            echo -e "${GREEN}✓ PASS${NC} - $router has $neighbor_count OSPF neighbors (expected: $expected_neighbors)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}✗ FAIL${NC} - $router has only $neighbor_count OSPF neighbors (expected: $expected_neighbors)"
        fi
    else
        echo -e "${RED}✗ FAIL${NC} - Could not connect to $router"
    fi
    echo ""
}

# Function to test ping between sites
test_site_ping() {
    local source=$1
    local dest_ip=$2
    local dest_name=$3

    echo "Testing connectivity: $source -> $dest_name ($dest_ip)..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    ping_result=$(docker exec clab-ospf-mpls-backbone-$source ping -c 3 -W 2 $dest_ip 2>/dev/null | grep "received" | awk '{print $4}')

    if [ "$ping_result" -ge "1" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $source can reach $dest_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - $source cannot reach $dest_name"
    fi
    echo ""
}

# Function to check OSPF routing table
test_ospf_routes() {
    local router=$1

    echo "Checking OSPF routes on $router..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    route_output=$(docker exec clab-ospf-mpls-backbone-$router vtysh -c "show ip route ospf" 2>/dev/null)

    if [ $? -eq 0 ]; then
        route_count=$(echo "$route_output" | grep -c "O " 2>/dev/null || echo "0")

        if [ "$route_count" -ge "1" ]; then
            echo -e "${GREEN}✓ PASS${NC} - $router has $route_count OSPF routes"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${YELLOW}⚠ WARNING${NC} - $router has no OSPF routes"
        fi
    else
        echo -e "${RED}✗ FAIL${NC} - Could not check routes on $router"
    fi
    echo ""
}

echo "=========================================="
echo "PHASE 1: OSPF NEIGHBOR TESTING"
echo "=========================================="
echo ""

# Test OSPF neighbors for each router
# Backbone routers (Area 0) - Full mesh
test_ospf_neighbors "R2" 5  # R2 connects to: R5, R6, R7, R3, R1
test_ospf_neighbors "R5" 4  # R5 connects to: R2, R6, R7, R4
test_ospf_neighbors "R6" 3  # R6 connects to: R2, R5, R7
test_ospf_neighbors "R7" 4  # R7 connects to: R2, R5, R6, R8

# Area 1 routers
test_ospf_neighbors "R3" 2  # R3 connects to: R2, R4
test_ospf_neighbors "R4" 2  # R4 connects to: R3, R5

# Area 2 routers
test_ospf_neighbors "R1" 2  # R1 connects to: R2, R8
test_ospf_neighbors "R8" 2  # R8 connects to: R1, R7

echo "=========================================="
echo "PHASE 2: OSPF ROUTING TABLE CHECK"
echo "=========================================="
echo ""

# Check OSPF routes on all routers
for router in R1 R2 R3 R4 R5 R6 R7 R8; do
    test_ospf_routes "$router"
done

echo "=========================================="
echo "PHASE 3: END-TO-END CONNECTIVITY TESTING"
echo "=========================================="
echo ""

# Test connectivity between client sites
echo "Testing Site-to-Site connectivity..."
echo ""

test_site_ping "Site-A" "10.2.0.10" "Site-B"
test_site_ping "Site-A" "10.3.0.10" "Site-C"
test_site_ping "Site-A" "10.4.0.10" "Site-D"
test_site_ping "Site-D" "10.1.0.10" "Site-A"
test_site_ping "Site-B" "10.3.0.10" "Site-C"

echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"
echo ""

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}✓✓✓ ALL TESTS PASSED! OSPF Network is fully operational.${NC}"
    exit 0
else
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${YELLOW}⚠ Some tests failed. Success rate: $success_rate%${NC}"
    exit 1
fi
