#!/usr/bin/env bash
# =============================================================================
# EC2 User Data Bootstrap Script for OpenClaw
# =============================================================================
# This script runs as root on first boot via EC2 user-data.
# It prepares the instance and then runs the main install as the ubuntu user.
# =============================================================================

set -euo pipefail
exec > >(tee /var/log/openclaw-bootstrap.log) 2>&1

echo "========================================="
echo "  OpenClaw EC2 Bootstrap - $(date)"
echo "========================================="

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install system deps
apt-get install -y git curl wget unzip jq build-essential

# Install Node.js 22 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

echo "Node.js $(node -v) installed"

# Clone the ec2-openclaw repo as ubuntu user
sudo -u ubuntu bash -c '
  cd /home/ubuntu
  if [ ! -d ec2-openclaw ]; then
    git clone https://github.com/rakeshsundru/ec2-openclaw.git
  fi
'

# Install OpenClaw as ubuntu user
sudo -u ubuntu bash -c '
  export HOME=/home/ubuntu
  export PATH="$HOME/.local/bin:$HOME/.openclaw/bin:$PATH"

  # Install OpenClaw via official installer
  curl -fsSL https://openclaw.ai/install.sh | bash

  # Set up directories
  mkdir -p "$HOME/.openclaw"
  mkdir -p "$HOME/.openclaw/workspace"
  mkdir -p "$HOME/.openclaw/workspace/skills"
  mkdir -p "$HOME/.claude/skills"

  # Copy config template
  if [ -f "$HOME/ec2-openclaw/config/openclaw.json" ] && [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    cp "$HOME/ec2-openclaw/config/openclaw.json" "$HOME/.openclaw/openclaw.json"
  fi

  # Install OpenClaw workspace skills
  if [ -d "$HOME/ec2-openclaw/skills/openclaw" ]; then
    cp -r "$HOME/ec2-openclaw/skills/openclaw/"* "$HOME/.openclaw/workspace/skills/" 2>/dev/null || true
  fi

  # Install Claude Code skills
  if [ -d "$HOME/ec2-openclaw/skills/claude-code" ]; then
    cp -r "$HOME/ec2-openclaw/skills/claude-code/"* "$HOME/.claude/skills/" 2>/dev/null || true
  fi
'

# Install systemd service
if [ -f /home/ubuntu/ec2-openclaw/config/openclaw.service ]; then
  sed 's|__USER__|ubuntu|g; s|__HOME__|/home/ubuntu|g' \
    /home/ubuntu/ec2-openclaw/config/openclaw.service \
    > /etc/systemd/system/openclaw.service
  systemctl daemon-reload
fi

echo "========================================="
echo "  OpenClaw bootstrap complete - $(date)"
echo "========================================="
echo ""
echo "SSH in and run:"
echo "  openclaw configure    # set API keys"
echo "  openclaw onboard --install-daemon"
echo ""
