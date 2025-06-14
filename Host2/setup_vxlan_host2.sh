#!/bin/bash
set -e

echo "🌐 Setting up VXLAN on Host 2..."

# Host configuration - Get from environment or AWS metadata
LOCAL_IP=${HOST2_IP:-"127.0.0.1"}
REMOTE_IP=${HOST1_IP:-"127.0.0.1"}
VXLAN_ID=100
VXLAN_PORT=4789
DOCKER_SUBNET="172.20.0.0/16"
DOCKER_GATEWAY="172.20.0.1"

echo "Local IP: $LOCAL_IP"
echo "Remote IP: $REMOTE_IP"

# 1. Create Docker network
echo "📡 Creating Docker bridge network..."
docker network create \
  --driver bridge \
  --subnet=$DOCKER_SUBNET \
  --gateway=$DOCKER_GATEWAY \
  vxlan-net 2>/dev/null || echo "Network already exists"

# 2. Create VXLAN interface to Host 1
echo "🔗 Creating VXLAN tunnel to Host 1 ($REMOTE_IP)..."
sudo ip link del vxlan0 2>/dev/null || true
sudo ip link add vxlan0 type vxlan \
  id $VXLAN_ID \
  remote $REMOTE_IP \
  dstport $VXLAN_PORT \
  dev enX0

# 3. Activate VXLAN interface
echo "⚡ Activating VXLAN interface..."
sudo ip link set vxlan0 up

# 4. Get Docker bridge ID and connect VXLAN
echo "🔌 Connecting VXLAN to Docker bridge..."
BRIDGE_ID=$(docker network inspect vxlan-net -f '{{.Id}}' | cut -c1-12)
sudo ip link set vxlan0 master br-$BRIDGE_ID

# 5. Verify setup
echo "✅ VXLAN setup complete!"
echo "🔍 Network verification:"
ip link show vxlan0
bridge link show vxlan0

echo "🎯 Ready to create containers on VXLAN network!"