#!/usr/bin/env bash
###############################################################################
# OpenClaw EC2 Full Setup + WhatsApp Integration
#
# Run this on your REAL EC2 instance (not in Claude Code sandbox):
#   curl -fsSL https://raw.githubusercontent.com/rakeshsundru/ec2-openclaw/claude/resume-claudbot-ec2-WrWrr/ec2-full-setup.sh | bash
#
# Or clone and run:
#   git clone https://github.com/rakeshsundru/ec2-openclaw.git
#   cd ec2-openclaw
#   chmod +x ec2-full-setup.sh
#   ./ec2-full-setup.sh
###############################################################################
set -euo pipefail

echo ""
echo "=========================================="
echo "  OpenClaw EC2 Full Setup + WhatsApp"
echo "=========================================="
echo ""

# ----------------------------
# 1. Check / Install Node.js 22
# ----------------------------
echo "--- Step 1: Checking Node.js ---"
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v\([0-9]*\).*/\1/')
    echo "Found Node.js $NODE_VERSION"
    if [ "$NODE_MAJOR" -lt 22 ]; then
        echo "Node.js 22+ required. Installing..."
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    echo "Node.js not found. Installing Node.js 22..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
echo "Node.js: $(node --version), npm: $(npm --version)"
echo ""

# ----------------------------
# 2. Install OpenClaw
# ----------------------------
echo "--- Step 2: Installing OpenClaw ---"
npm install -g openclaw@latest
echo "OpenClaw: $(openclaw --version)"
echo ""

# ----------------------------
# 3. Initialize OpenClaw
# ----------------------------
echo "--- Step 3: Initializing OpenClaw ---"
openclaw setup
echo ""

# ----------------------------
# 4. Write configuration
# ----------------------------
echo "--- Step 4: Writing configuration ---"

# Prompt for API key if not set
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    echo ""
    echo "Enter your Anthropic API key (sk-ant-...):"
    read -r ANTHROPIC_API_KEY
fi

# Prompt for WhatsApp number
echo ""
echo "Enter your WhatsApp phone number (E.164 format, e.g. +916302642731):"
read -r WHATSAPP_NUMBER

# Generate gateway auth token
GATEWAY_TOKEN=$(openssl rand -hex 32)

cat > ~/.openclaw/openclaw.json << JSONEOF
{
  "meta": {
    "lastTouchedVersion": "$(openclaw --version)"
  },
  "env": {
    "ANTHROPIC_API_KEY": "${ANTHROPIC_API_KEY}"
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-6"
      },
      "workspace": "$(echo ~/.openclaw/workspace)",
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    }
  },
  "messages": {
    "ackReactionScope": "group-mentions"
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto"
  },
  "channels": {
    "whatsapp": {
      "sendReadReceipts": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["${WHATSAPP_NUMBER}"],
      "groupPolicy": "allowlist",
      "mediaMaxMb": 50,
      "debounceMs": 0
    }
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "token": "${GATEWAY_TOKEN}"
    }
  },
  "plugins": {
    "entries": {
      "whatsapp": {
        "enabled": true
      }
    }
  }
}
JSONEOF

# Fix permissions
chmod 700 ~/.openclaw
mkdir -p ~/.openclaw/credentials

echo "Configuration written to ~/.openclaw/openclaw.json"
echo "Gateway token: ${GATEWAY_TOKEN}"
echo ""

# ----------------------------
# 5. Apply doctor fixes
# ----------------------------
echo "--- Step 5: Running doctor ---"
openclaw doctor --fix || true
echo ""

# ----------------------------
# 6. Start gateway
# ----------------------------
echo "--- Step 6: Starting gateway ---"
echo ""
echo "Starting the gateway in the background..."
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
nohup openclaw gateway --port 18789 --verbose > /tmp/openclaw-gateway.log 2>&1 &
GATEWAY_PID=$!
echo "Gateway started (PID: $GATEWAY_PID)"
echo "Logs: tail -f /tmp/openclaw-gateway.log"
echo ""

# Wait for gateway to be ready
sleep 5

# Check health
echo "--- Gateway health ---"
openclaw health || true
echo ""

# ----------------------------
# 7. Link WhatsApp
# ----------------------------
echo "=========================================="
echo "  WHATSAPP LINKING"
echo "=========================================="
echo ""
echo "A QR code will appear below."
echo "On your phone:"
echo "  1. Open WhatsApp"
echo "  2. Go to Settings > Linked Devices"
echo "  3. Tap 'Link a Device'"
echo "  4. Scan the QR code shown below"
echo ""
echo "Press ENTER when ready..."
read -r

openclaw channels login --verbose

echo ""
echo "=========================================="
echo "  SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "To send a test message to yourself:"
echo "  openclaw message send --to ${WHATSAPP_NUMBER} --message 'Hello from OpenClaw on EC2!'"
echo ""
echo "To chat with the agent:"
echo "  openclaw agent --message 'Hello!' --to ${WHATSAPP_NUMBER} --deliver"
echo ""
echo "To check status anytime:"
echo "  openclaw status"
echo "  openclaw health"
echo ""
echo "To view gateway logs:"
echo "  tail -f /tmp/openclaw-gateway.log"
echo ""
echo "To keep the gateway running after SSH disconnect:"
echo "  Use 'screen' or 'tmux' before starting, or set up a systemd service."
