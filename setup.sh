#!/usr/bin/env bash
# OpenClaw EC2 Setup Script
# Re-run this script if the environment resets to reinstall and configure OpenClaw.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#   # Then set your API key in ~/.openclaw/openclaw.json under "env"

set -euo pipefail

echo "=== OpenClaw EC2 Setup ==="
echo ""

# Check Node.js version
NODE_VERSION=$(node --version 2>/dev/null || echo "none")
echo "Node.js version: $NODE_VERSION"

REQUIRED_NODE_MAJOR=22
CURRENT_NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')

if [ "$NODE_VERSION" = "none" ] || [ "$CURRENT_NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ]; then
    echo "ERROR: Node.js >= 22 is required. Current: $NODE_VERSION"
    echo "Install Node.js 22+ first, then re-run this script."
    exit 1
fi

# Install OpenClaw globally
echo ""
echo "--- Installing OpenClaw ---"
if command -v openclaw &>/dev/null; then
    CURRENT_VERSION=$(openclaw --version 2>/dev/null)
    echo "OpenClaw already installed: $CURRENT_VERSION"
    echo "Updating to latest..."
fi
npm install -g openclaw@latest
echo "Installed: $(openclaw --version)"

# Initialize state directory and config
echo ""
echo "--- Setting up OpenClaw ---"
openclaw setup

# Configure gateway for local mode
echo ""
echo "--- Configuring gateway ---"
openclaw config set gateway.mode local

# Fix permissions and create credentials dir
chmod 700 ~/.openclaw
mkdir -p ~/.openclaw/credentials

# Apply doctor fixes
echo ""
echo "--- Running health check and applying fixes ---"
openclaw doctor --fix

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Add your Anthropic API key to ~/.openclaw/openclaw.json:"
echo '     Add "env": { "ANTHROPIC_API_KEY": "sk-ant-..." } to the config'
echo ""
echo "  2. Add your phone number to the WhatsApp allowlist:"
echo '     Edit channels.whatsapp.allowFrom in ~/.openclaw/openclaw.json'
echo ""
echo "  3. Start the gateway in the foreground (no systemd in containers):"
echo "     openclaw gateway --port 18789 --verbose"
echo ""
echo "  4. Link WhatsApp (scan QR code):"
echo "     openclaw channels login --verbose"
echo ""
echo "  5. Send a test message:"
echo '     openclaw agent --message "Hello, OpenClaw!"'
