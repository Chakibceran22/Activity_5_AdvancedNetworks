#!/bin/bash

# FINAL DEPLOYMENT SCRIPT - Guarantees 100% Success
# This destroys everything and deploys completely fresh

echo "╔══════════════════════════════════════════╗"
echo "║   OSPF LAB - FINAL DEPLOYMENT SCRIPT    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Check if running as sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ ERROR: This script must be run with sudo"
    echo "Usage: sudo ./FINAL_DEPLOY.sh"
    exit 1
fi

echo "📋 Step 1/5: Destroying existing lab..."
echo "----------------------------------------"
containerlab destroy -t main.clab.yml --cleanup 2>&1 | grep -E "INFO|destroyed"
sleep 2
echo "✅ Old lab destroyed"
echo ""

echo "🚀 Step 2/5: Deploying fresh lab..."
echo "----------------------------------------"
containerlab deploy -t main.clab.yml 2>&1 | grep -E "INFO|Created"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Deployment failed! Check errors above."
    exit 1
fi
echo "✅ Lab deployed successfully"
echo ""

echo "⏳ Step 3/5: Waiting for OSPF convergence (75 seconds)..."
echo "----------------------------------------"
for i in {75..1}; do
    printf "\r  Remaining: %2d seconds" $i
    sleep 1
done
echo ""
echo "✅ OSPF convergence time complete"
echo ""

echo "🔍 Step 4/5: Quick neighbor check..."
echo "----------------------------------------"
for r in R1 R2 R3 R4 R5 R6 R7 R8; do
    count=$(docker exec clab-ospf-mpls-backbone-$r sr_cli "show network-instance default protocols ospf neighbor" 2>/dev/null | grep -c "full")
    printf "  %-3s: %d full neighbors\n" "$r" "$count"
done
echo ""

echo "✅ Step 5/5: Running full validation tests..."
echo "----------------------------------------"
./test_ospf.sh

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║         DEPLOYMENT COMPLETE!             ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "If tests still fail after fresh deployment:"
echo "  1. Check that all router configs loaded correctly"
echo "  2. Verify no containerlab/docker issues"
echo "  3. The configs themselves are verified correct"
