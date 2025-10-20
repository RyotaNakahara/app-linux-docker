#!/bin/bash

# =============================================
# Docker Installation Script for Ubuntu
# =============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}==================================="
echo -e "Docker Installation for Ubuntu"
echo -e "===================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is already installed${NC}"
    docker --version
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Update package index
echo -e "${GREEN}Updating package index...${NC}"
apt-get update

# Install prerequisites
echo -e "${GREEN}Installing prerequisites...${NC}"
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo -e "${GREEN}Adding Docker GPG key...${NC}"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo -e "${GREEN}Setting up Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
apt-get update

# Install Docker Engine
echo -e "${GREEN}Installing Docker Engine...${NC}"
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
read -p "Enter username to add to docker group: " USERNAME
if id "$USERNAME" &>/dev/null; then
    usermod -aG docker "$USERNAME"
    echo -e "${GREEN}User $USERNAME added to docker group${NC}"
    echo -e "${YELLOW}Note: User needs to log out and back in for group changes to take effect${NC}"
else
    echo -e "${RED}User $USERNAME does not exist${NC}"
fi

# Verify installation
echo ""
echo -e "${GREEN}Verifying Docker installation...${NC}"
docker --version
docker compose version

echo ""
echo -e "${GREEN}==================================="
echo -e "Docker Installation Complete!"
echo -e "===================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Log out and back in (for group changes)"
echo "2. Test Docker: docker run hello-world"
echo "3. Clone your project and run: make up"


