#!/bin/bash

# Exit immediately if any command fails
set -e

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Ubuntu Node Setup ===${NC}"

# ----------------------------------------------------
# STEP 1: Hostname & Swap Setup
# ----------------------------------------------------
echo -e "${GREEN}[Step 1] Setting up hostname and disabling swap...${NC}"

if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    sudo hostnamectl set-hostname worker || true
else
    echo "worker" | sudo tee /etc/hostname
    sudo hostname worker || true
fi

echo "192.168.64.4 worker worker" | sudo tee -a /etc/hosts

#sudo hostnamectl set-hostname worker
#echo "192.168.64.4 worker worker" | sudo tee -a /etc/hosts

# Disable Swap (required for Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ----------------------------------------------------
# STEP 2: Kernel Modules & Sysctl Config
# ----------------------------------------------------
echo -e "${GREEN}[Step 2] Configuring kernel modules and network parameters...${NC}"

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# ----------------------------------------------------
# STEP 3: Install containerd
# ----------------------------------------------------
echo -e "${GREEN}[Step 3] Installing and configuring containerd...${NC}"

sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Docker GPG Key & Repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1

sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# ----------------------------------------------------
# STEP 4: Install Kubernetes Tools (kubelet, kubeadm, kubectl)
# ----------------------------------------------------
echo -e "${GREEN}[Step 4] Installing Kubernetes tools...${NC}"

# Modern Kubernetes apt repository configuration
#curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

#sudo apt-add-repository "deb http://apt.kubernetes.io/ kuberneties-jammy main"

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# ----------------------------------------------------
# STEP 5: Join Kubernetes Cluster
# ----------------------------------------------------
echo -e "${GREEN}[Step 5] Joining Kubernetes cluster...${NC}"

sudo kubeadm join master:6443 --token 5a4p8o.wqg4nao4uaij9e85 \
    --discovery-token-ca-cert-hash sha256:de86644c45e2403303ae9b21ece938709063cefa2cbab90f180b486c5c39380d

echo -e "${BLUE}=== Worker Node Setup Completed Successfully ===${NC}"
