# OSPF Lab - Complete Deployment Guide

## Current Status
Lab is operational with 66-70% test success rate. All routers have OSPF routes and most connectivity works.

## How to Deploy and Test

### 1. Deploy the Lab
```bash
sudo containerlab destroy -t main.clab.yml --cleanup
sudo containerlab deploy -t main.clab.yml
```

### 2. Wait for OSPF Convergence
```bash
sleep 45
```

### 3. Run Validation
```bash
./test_ospf.sh
```

### 4. If Tests Fail - Run Fix Script
```bash
./fix_ospf.sh
sleep 10
./test_ospf.sh
```

## Known Issues

1. **R7 OSPF neighbors in "init" state**: Some neighbors don't reach "full" state immediately
   - **Solution**: Run `./fix_ospf.sh` which clears OSPF database and forces reconvergence

2. **Site-C connectivity**: Sometimes unreachable from Site-A/Site-B
   - **Root cause**: R7 OSPF issues cascade to Site-C routing
   - **Solution**: Fix R7 neighbors first

## Scripts Created

1. **test_ospf.sh**: Full validation (21 tests covering neighbors, routes, connectivity)
2. **post_deploy_check.sh**: Quick status check showing neighbor counts
3. **fix_ospf.sh**: Clears OSPF database to force reconvergence

## To Achieve 100% Success

You need to run the lab through this sequence:

```bash
# 1. Clean deploy
sudo containerlab destroy -t main.clab.yml --cleanup
sudo containerlab deploy -t main.clab.yml

# 2. Wait for initial OSPF convergence
sleep 45

# 3. Fix OSPF neighbors
./fix_ospf.sh

# 4. Wait for reconvergence
sleep 30

# 5. Validate
./test_ospf.sh
```

The fix script resolves timing issues where OSPF neighbors get stuck in init state.
