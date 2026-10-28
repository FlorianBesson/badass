# P2 Configuration

This document explains how the network configuration for Part 2 is applied to the GNS3 Docker nodes.

The GNS3 topology contains two hosts and two routers:

```text
host-fbesson-1
      |
router-fbesson-1
      |
    Switch1
      |
router-fbesson-2
      |
host-fbesson-2
```

The routers are connected through an underlay IP network and use VXLAN to extend a Layer 2 network between the two hosts.

---

## Interfaces

On each router:

```text
eth0 → underlay network / GNS3 switch
eth1 → local host
```

`eth0` is used to transport VXLAN packets between the VTEPs.

`eth1` is attached to a Linux bridge and represents the local Layer 2 side of the VXLAN.

---

## Underlay

The routers communicate using the following IP addresses:

```text
router-fbesson-1
eth0 → 10.0.0.1/24

router-fbesson-2
eth0 → 10.0.0.2/24
```

Before configuring VXLAN, both routers must be able to ping each other.

Example:

```bash
ping 10.0.0.2
```

from `router-fbesson-1`.

---

## Linux bridge

Each router creates a Linux bridge named:

```text
br0
```

A Linux bridge behaves like a virtual Layer 2 switch.

The local host interface and the VXLAN interface are connected to this bridge:

```text
          br0
         /   \
      eth1   vxlan0
       |       |
     host    VXLAN
```

Example commands:

```bash
ip link add br0 type bridge
ip link set br0 up

ip link set eth1 master br0
ip link set eth1 up
```

---

# Static VXLAN

The first configuration uses a statically defined remote VTEP.

VXLAN ID:

```text
10
```

UDP destination port:

```text
4789
```

Example for `router-fbesson-1`:

```bash
ip link add vxlan0 type vxlan \
    id 10 \
    local 10.0.0.1 \
    remote 10.0.0.2 \
    dev eth0 \
    dstport 4789

ip link set vxlan0 up
ip link set vxlan0 master br0
```

The second router uses the opposite addresses:

```text
local  10.0.0.2
remote 10.0.0.1
```

In this mode, each VTEP explicitly knows the IP address of the other VTEP.

---

# Multicast VXLAN

The multicast configuration removes the explicit remote VTEP.

Instead, both routers join the same multicast group:

```text
239.1.1.1
```

Example for `router-fbesson-1`:

```bash
ip link add vxlan0 type vxlan \
    id 10 \
    group 239.1.1.1 \
    local 10.0.0.1 \
    dev eth0 \
    dstport 4789

ip link set vxlan0 up
ip link set vxlan0 master br0
```

For `router-fbesson-2`:

```text
group 239.1.1.1
local 10.0.0.2
```

The important difference is therefore:

```text
Static:
remote 10.0.0.X

Multicast:
group 239.1.1.1
```

Both VTEPs participate in the same multicast group instead of explicitly referencing each other.

---

# Configuration scripts

The runtime configuration is stored in shell scripts.

Example structure:

```text
P2/
├── apply-config.sh
├── static/
│   ├── host-1.sh
│   ├── host-2.sh
│   ├── router-1.sh
│   └── router-2.sh
└── multicast/
    ├── host-1.sh
    ├── host-2.sh
    ├── router-1.sh
    └── router-2.sh
```

The scripts configure the Docker containers after the GNS3 nodes have been started.

This is necessary because the network configuration created with commands such as:

```bash
ip addr
ip link
bridge
```

is runtime configuration and can disappear when a container is stopped or recreated.

---

# Applying the configuration

The main configuration script automatically detects the running GNS3 containers and executes the corresponding configuration file.

Example:

```bash
#!/bin/bash

for id in $(docker ps -q); do
    hostname=$(docker inspect -f '{{.Config.Hostname}}' $id)
    script=multicast/$(echo $hostname | cut -d'-' -f1,3).sh

    echo "applying $script config to $hostname ($id)"

    cat $script | docker exec -i $id sh
done
```

Run it with:

```bash
chmod +x apply-config.sh
./apply-config.sh
```

---

## How the script works

The command:

```bash
docker ps -q
```

returns the IDs of all running Docker containers.

The loop:

```bash
for id in $(docker ps -q)
```

processes each container individually.

The following command retrieves its hostname:

```bash
docker inspect -f '{{.Config.Hostname}}' $id
```

For example:

```text
router-fbesson-1
```

The command:

```bash
cut -d'-' -f1,3
```

splits the hostname using `-` and keeps fields 1 and 3.

Example:

```text
router-fbesson-1
       ↓
router-1
```

This allows the script to automatically associate a GNS3 node with its configuration file:

```text
router-fbesson-1 → multicast/router-1.sh
router-fbesson-2 → multicast/router-2.sh
host-fbesson-1   → multicast/host-1.sh
host-fbesson-2   → multicast/host-2.sh
```

Finally:

```bash
cat $script | docker exec -i $id sh
```

sends the configuration script to a shell running inside the corresponding Docker container.

Conceptually:

```text
configuration file
       |
       v
docker exec
       |
       v
GNS3 Docker node
       |
       v
network configuration applied
```

---

# Verification

## Underlay

Verify router connectivity:

```bash
ping 10.0.0.2
```

or:

```bash
ping 10.0.0.1
```

---

## VXLAN configuration

Display detailed VXLAN information:

```bash
ip -d link show vxlan0
```

For multicast mode, the output should contain values similar to:

```text
vxlan id 10
group 239.1.1.1
local 10.0.0.X
dev eth0
dstport 4789
```

---

## Bridge

Display the ports attached to the Linux bridge:

```bash
bridge link
```

The bridge should contain:

```text
eth1
vxlan0
```

---

## Forwarding database

Display the MAC address table:

```bash
bridge fdb show
```

The forwarding database is the equivalent of the MAC address table of a Layer 2 switch.

For example:

```text
MAC of local host  → eth1
MAC of remote host → vxlan0
```

A remote MAC learned through VXLAN can therefore appear as:

```text
XX:XX:XX:XX:XX:XX dev vxlan0 master br0
```

This means that `br0` knows that frames destined for this MAC must be forwarded through the VXLAN interface.

---

## Host connectivity

Finally, verify communication between the two hosts.

For example:

```bash
ping <host-2-ip>
```

from `host-fbesson-1`.

If the ping works, the complete path is:

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
underlay
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

The original Layer 2 Ethernet frame is transported through the Layer 3 underlay using VXLAN encapsulation.
