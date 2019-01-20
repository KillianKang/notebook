#!/bin/bash

set -e

echo ">>> 安装 VBoxLinuxAdditions 依赖..."
apt-get update
apt-get install -y linux-headers-$(uname -r) build-essential dkms

echo ">>> 安装 VBoxLinuxAdditions..."
chmod +x /opt/RD_Docker_Env/VBoxLinuxAdditions.run
/opt/RD_Docker_Env/VBoxLinuxAdditions.run
