#!/usr/bin/env bash
# OpenClaw EC2 Setup Script
# Re-run this script if the environment resets to reinstall and configure OpenClaw.
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#   # Then configure your API key:
#   openclaw config set agent.model anthropic/claude-opus-4-6
#   export ANTHROPIC_API_KEY="your-key-here"
#   # Or for OpenAI:
#   openclaw config set agent.model openai/gpt-4o
#   export OPENAI_API_KEY="your-key-here"

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

# Run doctor to verify
echo ""
echo "--- Running health check ---"
openclaw doctor

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Set your AI provider API key:"
echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
echo "     openclaw config set agent.model anthropic/claude-opus-4-6"
echo ""
echo "  2. Run the onboarding wizard (optional):"
echo "     openclaw onboard"
echo ""
echo "  3. Start the gateway in the foreground (no systemd in containers):"
echo "     openclaw gateway --port 18789 --verbose"
echo ""
echo "  4. Connect a channel (e.g., WhatsApp):"
echo "     openclaw channels login --verbose"
echo ""
echo "  5. Send a test message:"
echo "     openclaw agent --message \"Hello, OpenClaw!\""
