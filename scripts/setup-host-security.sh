#!/bin/bash

# =============================================
# Ubuntu Host Hardening Script
# SSH Key Authentication, UFW, Fail2ban
# =============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================="
echo -e "Ubuntu Host Hardening Setup"
echo -e "===================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Get non-root user
read -p "Enter the username for SSH access: " SSH_USER
if ! id "$SSH_USER" &>/dev/null; then
    echo -e "${RED}Error: User $SSH_USER does not exist${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "1. Configure SSH key authentication"
echo "2. Disable SSH password authentication"
echo "3. Setup UFW firewall"
echo "4. Install and configure Fail2ban"
echo ""

read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# =============================================
# 1. SSH Key Authentication Setup
# =============================================
echo ""
echo -e "${GREEN}[1/4] Configuring SSH Key Authentication...${NC}"

# Create .ssh directory if not exists
SSH_DIR="/home/$SSH_USER/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chown "$SSH_USER:$SSH_USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Check if authorized_keys exists
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    touch "$AUTHORIZED_KEYS"
    chown "$SSH_USER:$SSH_USER" "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
fi

# Prompt for SSH public key
echo ""
echo -e "${YELLOW}Please enter your SSH public key (or press Enter to skip):${NC}"
echo "(You can add it later to $AUTHORIZED_KEYS)"
read -r SSH_PUBLIC_KEY

if [ -n "$SSH_PUBLIC_KEY" ]; then
    # Check if key already exists
    if grep -q "$SSH_PUBLIC_KEY" "$AUTHORIZED_KEYS"; then
        echo -e "${YELLOW}Key already exists in authorized_keys${NC}"
    else
        echo "$SSH_PUBLIC_KEY" >> "$AUTHORIZED_KEYS"
        echo -e "${GREEN}SSH public key added successfully${NC}"
    fi
fi

# Backup SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Configure SSH settings
echo -e "${GREEN}Configuring SSH daemon...${NC}"

# Update SSH configuration
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config

# Add additional security settings if not present
grep -q "^AllowUsers" /etc/ssh/sshd_config || echo "AllowUsers $SSH_USER" >> /etc/ssh/sshd_config

echo -e "${GREEN}SSH configuration updated${NC}"

# =============================================
# 2. UFW Firewall Setup
# =============================================
echo ""
echo -e "${GREEN}[2/4] Setting up UFW Firewall...${NC}"

# Install UFW if not installed
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW..."
    apt-get update
    apt-get install -y ufw
fi

# Reset UFW to default
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (before enabling firewall)
SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
SSH_PORT=${SSH_PORT:-22}
ufw allow "$SSH_PORT/tcp" comment "SSH"

# Allow HTTP and HTTPS
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"

# Ask for additional ports
echo ""
echo -e "${YELLOW}Do you want to expose database ports? (Not recommended for production)${NC}"
read -p "Allow PostgreSQL (5432)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw allow 5432/tcp comment "PostgreSQL"
fi

read -p "Allow Mailhog (8025)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ufw allow 8025/tcp comment "Mailhog"
fi

# Enable UFW
echo "y" | ufw enable

echo -e "${GREEN}UFW firewall configured and enabled${NC}"
ufw status verbose

# =============================================
# 3. Fail2ban Installation
# =============================================
echo ""
echo -e "${GREEN}[3/4] Installing and configuring Fail2ban...${NC}"

# Install fail2ban
apt-get update
apt-get install -y fail2ban

# Create local jail configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Ban settings
bantime  = 3600
findtime = 600
maxretry = 5

# Notification (optional - configure later)
destemail = root@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime  = 7200

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log

[nginx-botsearch]
enabled = true
port = http,https
filter = nginx-botsearch
logpath = /var/log/nginx/access.log
maxretry = 2
EOF

# Create nginx filter for rate limiting
cat > /etc/fail2ban/filter.d/nginx-limit-req.conf << 'EOF'
[Definition]
failregex = limiting requests, excess:.* by zone.*client: <HOST>
ignoreregex =
EOF

# Enable and start fail2ban
systemctl enable fail2ban
systemctl restart fail2ban

echo -e "${GREEN}Fail2ban installed and configured${NC}"

# =============================================
# 4. System Updates and Additional Security
# =============================================
echo ""
echo -e "${GREEN}[4/4] Applying additional security settings...${NC}"

# Update system packages
echo -e "${YELLOW}Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# Install essential security tools
apt-get install -y \
    unattended-upgrades \
    logwatch \
    aide \
    apt-listchanges

# Configure automatic security updates
dpkg-reconfigure -plow unattended-upgrades

# Disable IPv6 if not needed (optional)
read -p "Disable IPv6? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat >> /etc/sysctl.conf << 'EOF'

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p
fi

# Set proper file permissions
chmod 644 /etc/passwd
chmod 640 /etc/shadow
chmod 644 /etc/group
chmod 640 /etc/gshadow

# =============================================
# Final Steps
# =============================================
echo ""
echo -e "${GREEN}==================================="
echo -e "Security Setup Complete!"
echo -e "===================================${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. SSH password authentication is now DISABLED"
echo "2. Make sure you can login with SSH key before closing this session"
echo "3. Test SSH connection in a new terminal before closing this one"
echo "4. UFW firewall is active"
echo "5. Fail2ban is monitoring SSH and Nginx"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test SSH key authentication: ssh $SSH_USER@<server-ip>"
echo "2. Review fail2ban status: sudo fail2ban-client status"
echo "3. Check UFW status: sudo ufw status"
echo "4. Review logs: /var/log/auth.log, /var/log/fail2ban.log"
echo ""
echo -e "${RED}IMPORTANT: Test your SSH connection NOW before closing this terminal!${NC}"
echo ""

# Restart SSH service
echo -e "${YELLOW}Restarting SSH service...${NC}"
systemctl restart sshd

echo -e "${GREEN}Setup complete!${NC}"


