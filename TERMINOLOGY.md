# Network Terminology

Short reference for the main networking concepts used in the BADASS project.

---

## BGP

**Border Gateway Protocol**

BGP is the routing protocol used to exchange routing information between different networks, especially between Autonomous Systems on the Internet.

BGP mainly answers:

> Which network prefixes are reachable, and through which path?

---

## BGP EVPN

**Border Gateway Protocol - Ethernet VPN**

EVPN is a control plane that can distribute Layer 2 information such as MAC addresses using BGP.

With VXLAN, BGP EVPN allows VTEPs to learn remote MAC/IP information without relying only on flooding.

```text
VXLAN = data plane
BGP EVPN = control plane
```

---

## Bridge

A bridge is a Layer 2 device that connects multiple network interfaces.

A Linux bridge behaves approximately like a virtual Ethernet switch.

Example:

```text
       br0
      /   \
   eth1   vxlan0
```

The bridge learns which MAC addresses are reachable through each interface.

---

## Default Gateway

A default gateway is the router a device uses when the destination is outside its local network.

Example:

```text
PC:      192.168.1.20/24
Gateway: 192.168.1.1

Destination: 8.8.8.8
        ↓
not local
        ↓
send to 192.168.1.1
```

---

## Frame vs Packet

A **frame** is the Layer 2 unit of communication.

It mainly uses MAC addresses and exists on a local Layer 2 link.

A **packet** is the Layer 3 unit of communication.

It mainly uses IP addresses and can travel across multiple routed networks.

```text
Ethernet frame
┌─────────────────────────────────┐
│ Destination MAC                 │
│ Source MAC                      │
│                                 │
│   IP packet                     │
│   ┌─────────────────────────┐   │
│   │ Source IP               │   │
│   │ Destination IP          │   │
│   │                         │   │
│   │ TCP / UDP + data        │   │
│   └─────────────────────────┘   │
└─────────────────────────────────┘
```

Routers remove the incoming Layer 2 frame, route the IP packet, and create a new frame for the next link.

---

## FRR

**FRRouting**

FRR is a routing software suite implementing protocols such as:

- BGP
- OSPF
- IS-IS

FRR is mainly part of the network **control plane**.

Its routing daemons calculate and exchange routing information.

Example:

```text
bgpd
ospfd
isisd
   \
    \
    zebra
      |
      v
Linux kernel routing table
      |
      v
data plane
```

`zebra` acts as an intermediary between FRR routing daemons and the operating system.

---

## GNS3

**Graphical Network Simulator 3**

GNS3 is a tool used to build and simulate network topologies without requiring all the physical hardware.

It can connect:

- virtual machines
- Docker containers
- routers
- switches
- virtual appliances

---

## Hypervisor Ballooning

Memory ballooning allows a hypervisor to dynamically reclaim unused RAM from a virtual machine and make it available elsewhere.

It helps improve memory utilization when multiple VMs share the same host.

---

## ICMP

**Internet Control Message Protocol**

ICMP is a Layer 3 protocol used for network control, diagnostics and error reporting.

`ping` uses ICMP.

Example:

```text
ICMP Echo Request
        ↓
ICMP Echo Reply
```

---

## Interface

A network interface is a connection point between a device and a network.

Examples:

```text
eth0
eth1
wlan0
vxlan0
```

An interface can be physical or virtual.

---

## MPLS

**Multiprotocol Label Switching**

MPLS forwards traffic using labels instead of performing a normal IP routing lookup at every step.

It is sometimes described as a **Layer 2.5** technology because it operates conceptually between Layer 2 and Layer 3.

```text
IP packet
   ↓
MPLS label added
   ↓
forward using labels
```

---

## MP-BGP

**Multiprotocol BGP**

MP-BGP is an extension of BGP that allows BGP to carry different address families.

Examples include:

```text
IPv4
IPv6
VPN routes
EVPN routes
```

BGP EVPN relies on MP-BGP to transport EVPN information.

---

## NAT

**Network Address Translation**

NAT modifies IP addressing information as traffic passes through a router or firewall.

A very common use is allowing multiple devices with private IPv4 addresses to access the Internet using one public IPv4 address.

```text
192.168.1.20 ─┐
192.168.1.21 ─┼─ NAT router ── public IP ── Internet
192.168.1.22 ─┘
```

NAT is especially important with IPv4 because the IPv4 address space is limited.

A common form is **PAT/NAPT**, where ports are also translated so many devices can share one public IP.

NAT is not required by IPv6 in the same way.

---

## Network

A network is a group of connected nodes that can communicate according to a common addressing and networking scheme.

Example:

```text
Network: 192.168.1.0/24

├── 192.168.1.1   router
├── 192.168.1.20  PC
├── 192.168.1.67  laptop
├── 192.168.1.82  VM
└── ...
```

---

## NLRI

**Network Layer Reachability Information**

NLRI is the routing information advertised by BGP.

It describes destinations that a BGP router knows how to reach.

For traditional IPv4 BGP, this can be an IP prefix:

```text
10.0.0.0/24
```

With MP-BGP, NLRI can represent other kinds of reachability information, including EVPN routes.

---

## Overlay vs Underlay

### Underlay

The underlay is the network that provides the basic IP connectivity between network devices.

Example:

```text
VTEP1 10.0.0.1
      |
    switch
      |
VTEP2 10.0.0.2
```

It can use technologies and protocols such as:

```text
Ethernet
IP
OSPF
IS-IS
BGP
```

Its main job is:

> transport packets between endpoints.

### Overlay

The overlay is a logical network built on top of the underlay.

It usually relies on tunneling or encapsulation.

Example:

```text
host1
  |
VTEP1
  ║
  ║ VXLAN tunnel
  ║
VTEP2
  |
host2
```

VXLAN is an overlay technology.

The underlay only needs to provide IP connectivity between the VTEPs.

---

## RFC

**Request for Comments**

RFCs are technical documents published by organizations such as the IETF.

They describe Internet technologies, protocols, standards and technical recommendations.

Example:

```text
RFC 4271
```

defines BGP-4.

---

## Router vs Gateway

A **router** connects different Layer 3 networks and forwards packets between them.

```text
192.168.1.0/24
       |
     router
       |
10.0.0.0/24
```

A **gateway** is the device used as the exit point from a network toward another network.

So:

```text
router = device/function that routes packets

gateway = next-hop used to leave the current network
```

A router is very often used as a gateway.

---

## Routing Table

A routing table contains the routes known by a system.

It helps the Layer 3 device decide where a packet should be sent.

Example:

```text
Destination       Interface
10.0.0.0/24   →   eth0
20.0.0.0/24   →   eth1
default       →   10.0.0.254
```

On Linux:

```bash
ip route
```

---

## Static vs Dynamic VLAN

A VLAN segments a Layer 2 network into separate broadcast domains.

With a **static VLAN**, switch ports are manually assigned to VLANs.

Example:

```text
port 1 → VLAN 10
port 2 → VLAN 10
port 3 → VLAN 20
```

A **dynamic VLAN** can assign a VLAN based on information such as the connected device identity or MAC address, depending on the implementation.

Static VLANs are much more common.

---

## VLAN

**Virtual LAN**

A VLAN logically separates a Layer 2 network into different broadcast domains.

Example:

```text
Switch

VLAN 10 → developers
VLAN 20 → servers
VLAN 30 → management
```

Traditional VLAN IDs use 12 bits, giving about 4094 usable VLAN IDs.

---

## VNI

**VXLAN Network Identifier**

The VNI identifies a VXLAN logical Layer 2 network.

It is similar in purpose to a VLAN ID, but VXLAN uses a 24-bit identifier.

Example:

```text
VNI 10
```

Two VTEPs using the same VNI can participate in the same VXLAN segment.

---

## VTEP

**VXLAN Tunnel Endpoint**

A VTEP is the device or software endpoint that encapsulates and decapsulates VXLAN traffic.

```text
Ethernet frame
      ↓
    VTEP
      ↓
VXLAN encapsulation
      ↓
UDP / IP network
      ↓
    VTEP
      ↓
original Ethernet frame
```

In our P2 topology, the routers act as VTEPs.

---

## VTYSH

`vtysh` is the command-line interface used to configure and inspect FRR.

It provides one interface for interacting with multiple FRR daemons.

Example:

```bash
vtysh
```

Then:

```text
show ip route
show bgp summary
show running-config
```

---

## VXLAN

**Virtual Extensible LAN**

VXLAN extends Layer 2 networks across a Layer 3 IP network.

It encapsulates an Ethernet frame inside UDP/IP.

```text
Original Ethernet frame
          ↓
       VXLAN
          ↓
        UDP
          ↓
         IP
          ↓
      underlay
```

This allows two machines separated by an IP network to behave as if they were on the same Layer 2 network.

VXLAN also provides a much larger segmentation space than VLAN:

```text
VLAN  → 12-bit ID
VXLAN → 24-bit VNI
```

VXLAN is commonly used in data centers and cloud environments.

---

## BADASS P2 Mental Model

```text
host1
  |
eth1
  |
br0
  |
vxlan0
  |
eth0
  |
========== underlay ==========
  |
eth0
  |
vxlan0
  |
br0
  |
eth1
  |
host2
```

- `eth1` connects the local host.
- `br0` acts as a virtual Layer 2 switch.
- `vxlan0` carries Layer 2 frames through VXLAN.
- `eth0` carries the outer IP/UDP packets through the underlay.
- The router/container acts as the VTEP.
