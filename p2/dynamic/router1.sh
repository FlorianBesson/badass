# 1. configure underlay IP on interface to the switch
ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up

# 2. create linux bridge
ip link add br0 type bridge
ip link set br0 up

# 3. Add interface on the host side to the bridge
ip link set eth1 master br0
ip link set eth1 up

# 4. create dynamic vxlan
ip link add vxlan0 type vxlan \
  id 10 \
  local 10.0.0.1 \
  group 239.1.1.1 \
  dev eth0 \
  dstport 4789

# 5. activate vxlan
ip link set vxlan0 up

# 6. add vxlan as a second port on the bridge
ip link set vxlan0 master br0
