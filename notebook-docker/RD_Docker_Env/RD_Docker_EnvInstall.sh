#!/bin/bash

set -e

echo ">>> 设置 Linux 时区..."
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
date

echo ">>> 将用户 kingboya 添加到 vboxsf 用户组..."
usermod -aG vboxsf kingboya

echo ">>> 设置定时备份..."
chmod +x /opt/RD_Docker_Env/rd_backup_del.sh
echo "30 1 * * * kingboya /opt/RD_Docker_Env/rd_backup_del.sh" >> /etc/crontab

echo ">>> 安装 Docker-CE 依赖..."
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common
  
echo ">>> 安装 Docker-CE..."
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
  "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get update
apt-get install -y docker-ce

echo ">>> 设置 Docker 镜像加速..."
cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "http://hub-mirror.c.163.com"
  ]
}
EOF
service docker restart

echo ">>> 安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo ">>> RD_Docker_Env Install Complete <<<"
