# OSPF Multi-Area Backbone Network - Nokia SR Linux

## Network Architecture

This lab implements a multi-area OSPF network using **8 Nokia SR Linux routers** with the following design:

### OSPF Areas
- **Backbone (Area 0)**: R2, R5, R6, R7 (Full Mesh Core)
- **Area 1**: R3, R4 + Site-A, Site-B (Client networks)
- **Area 2**: R1, R8 + Site-D, Site-C (Client networks)

### IP Addressing Scheme

#### Loopback Addresses (Router IDs)
- R1: 1.1.1.1/32
- R2: 2.2.2.2/32
- R3: 3.3.3.3/32
- R4: 4.4.4.4/32
- R5: 5.5.5.5/32
- R6: 6.6.6.6/32
- R7: 7.7.7.7/32
- R8: 8.8.8.8/32

#### Backbone Links (Area 0)
- R2-R5: 10.0.25.0/30
- R2-R6: 10.0.26.0/30
- R2-R7: 10.0.27.0/30
- R5-R6: 10.0.56.0/30
- R5-R7: 10.0.57.0/30
- R6-R7: 10.0.67.0/30

#### Area Border Links
- R1-R2 (Area 0): 10.0.12.0/30
- R3-R2 (Area 0): 10.0.23.0/30
- R4-R5 (Area 0): 10.0.45.0/30
- R8-R7 (Area 0): 10.0.78.0/30

#### Area 1 Links
- R3-R4: 10.0.34.0/30

#### Area 2 Links
- R1-R8: 10.0.18.0/30

#### Client Networks
- Site-A: 10.1.0.0/24 (via R3)
- Site-B: 10.2.0.0/24 (via R3)
- Site-C: 10.3.0.0/24 (via R8)
- Site-D: 10.4.0.0/24 (via R1)

## Deployment Instructions

### 1. Deploy the Lab
```bash
sudo containerlab deploy -t main.clab.yml
```

### 2. Verify Deployment
```bash
sudo containerlab inspect
```

### 3. Access Routers
```bash
# SSH to any router
sudo docker exec -it clab-ospf-mpls-backbone-R1 sr_cli

# Or use containerlab
sudo containerlab exec -t main.clab.yml --label clab-node-name=R1 sr_cli
```

## Verification Commands

### Check OSPF Status
```bash
# Enter SR Linux CLI on any router
show network-instance default protocols ospf instance main
show network-instance default protocols ospf neighbor
show network-instance default protocols ospf interface
show network-instance default protocols ospf database
```

### Check Routing Table
```bash
show network-instance default route-table all
show network-instance default protocols ospf instance main route-table
```

### Check Interface Status
```bash
show interface brief
show interface ethernet-1/1
```

### Ping Tests from Routers

From R1, test connectivity to all other routers:
```bash
ping 2.2.2.2 network-instance default  # R2
ping 3.3.3.3 network-instance default  # R3
ping 4.4.4.4 network-instance default  # R4
ping 5.5.5.5 network-instance default  # R5
ping 6.6.6.6 network-instance default  # R6
ping 7.7.7.7 network-instance default  # R7
ping 8.8.8.8 network-instance default  # R8
```

### Ping Tests from Client Sites

Access a client container:
```bash
sudo docker exec -it clab-ospf-mpls-backbone-Site-A sh
```

Then ping other sites:
```bash
ping 10.2.0.10  # Site-B
ping 10.3.0.10  # Site-C
ping 10.4.0.10  # Site-D
ping 1.1.1.1    # R1 loopback
ping 5.5.5.5    # R5 loopback
```

## OSPF Configuration Details

### Area Border Routers (ABRs)
- **R3**: Connects Area 1 to Area 0 (via R2)
- **R4**: Connects Area 1 to Area 0 (via R5)
- **R1**: Connects Area 2 to Area 0 (via R2)
- **R8**: Connects Area 2 to Area 0 (via R7)

### OSPF Features Configured
- OSPFv2 (for IPv4)
- Point-to-point interface types on backbone links
- Passive interfaces on loopbacks
- Multiple ABRs for redundancy
- Full mesh backbone for optimal routing

## Troubleshooting

### Check if containers are running
```bash
sudo docker ps | grep clab-ospf
```

### View router logs
```bash
sudo docker logs clab-ospf-mpls-backbone-R1
```

### Restart the lab
```bash
sudo containerlab destroy -t main.clab.yml
sudo containerlab deploy -t main.clab.yml
```

### Manual configuration (if needed)
If you need to apply configs manually:
```bash
sudo docker exec -it clab-ospf-mpls-backbone-R1 sr_cli
# Then paste the contents of configs/R1.cfg
```

## Next Steps - MPLS Migration

This OSPF backbone is designed to support MPLS. The next phase will include:

1. **MPLS Label Distribution Protocol (LDP)** configuration
2. **MPLS L3VPN** for customer sites
3. **RSVP-TE** for traffic engineering
4. **BGP** for VPNv4 route exchange

## Next Steps - SDN Migration

After MPLS, the network can be transitioned to SDN:

1. **OpenFlow** integration
2. **SDN Controller** deployment
3. **Network programmability** via APIs
4. **Automated traffic engineering**

## Network Topology Diagram

```
                    AREA 1
                  ┌─────────┐
        Site-A ───┤   R3    │
                  │  (ABR)  │
        Site-B ───┤         ├──── Area 0 ──── R2
                  └────┬────┘                  │
                       │                       │
                  ┌────┴────┐                  │
                  │   R4    │                  │
                  │  (ABR)  ├──── Area 0 ──── R5
                  └─────────┘                  │
                                               │
            AREA 0 (BACKBONE - FULL MESH)      │
              R2 ─────── R5                    │
              │ ╲      ╱ │                     │
              │  ╲    ╱  │                     │
              │   ╲  ╱   │                     │
              │    ╲╱    │                     │
              │    ╱╲    │                     │
              │   ╱  ╲   │                     │
              │  ╱    ╲  │                     │
              │ ╱      ╲ │                     │
              R7 ─────── R6                    │
              │                                │
              │                                │
         ┌────┴────┐                      ┌────┴────┐
         │   R8    │                      │   R1    │
         │  (ABR)  │                      │  (ABR)  │
         └────┬────┘                      └────┬────┘
              │                                │
        Site-C│        AREA 2                  │Site-D
              │                                │
         ┌────┴────────────────────────────────┴────┐
         │            R1 ←──→ R8                    │
         └──────────────────────────────────────────┘
```

## References

- [Nokia SR Linux Documentation](https://learn.srlinux.dev/)
- [Containerlab Documentation](https://containerlab.dev/)
- [OSPF RFC 2328](https://tools.ietf.org/html/rfc2328)
