#!/usr/bin/env bash
# =============================================================================
# OpenClaw (formerly ClaudBot) EC2 Installation Script
# =============================================================================
# This script installs OpenClaw and its dependencies on an EC2 instance
# running Amazon Linux 2023, Ubuntu 22.04/24.04, or Debian 12.
#
# Usage:
#   chmod +x scripts/install.sh
#   ./scripts/install.sh
#
# Prerequisites:
#   - EC2 instance with at least 2 GB RAM (t3.small or larger recommended)
#   - Non-root user with sudo access
#   - Internet connectivity
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Safety checks
# ---------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    error "Do NOT run this script as root. Use a regular user with sudo access."
    exit 1
fi

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION="${VERSION_ID:-}"
    else
        error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
}
detect_os
log "Detected OS: $OS_ID $OS_VERSION"

# ---------------------------------------------------------------------------
# Install system dependencies
# ---------------------------------------------------------------------------
install_system_deps() {
    log "Installing system dependencies..."

    case "$OS_ID" in
        amzn|al2023)
            sudo dnf update -y
            sudo dnf install -y git curl wget unzip jq gcc-c++ make
            ;;
        ubuntu|debian)
            sudo apt-get update -y
            sudo apt-get install -y git curl wget unzip jq build-essential
            ;;
        *)
            error "Unsupported OS: $OS_ID. Supported: amzn, al2023, ubuntu, debian."
            exit 1
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Install Node.js >= 22 via nvm
# ---------------------------------------------------------------------------
install_node() {
    local REQUIRED_MAJOR=22

    if command -v node &>/dev/null; then
        local CURRENT_MAJOR
        CURRENT_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
        if [[ "$CURRENT_MAJOR" -ge "$REQUIRED_MAJOR" ]]; then
            log "Node.js $(node -v) already installed (>= v${REQUIRED_MAJOR}). Skipping."
            return 0
        else
            warn "Node.js $(node -v) found but < v${REQUIRED_MAJOR}. Installing newer version..."
        fi
    fi

    log "Installing nvm and Node.js v${REQUIRED_MAJOR}..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install "$REQUIRED_MAJOR"
    nvm use "$REQUIRED_MAJOR"
    nvm alias default "$REQUIRED_MAJOR"

    log "Node.js $(node -v) installed successfully."
}

# ---------------------------------------------------------------------------
# Install OpenClaw
# ---------------------------------------------------------------------------
install_openclaw() {
    log "Installing OpenClaw..."

    # Set up user-local npm prefix to avoid sudo
    mkdir -p "$HOME/.npm-global"
    npm config set prefix "$HOME/.npm-global"

    # Ensure PATH includes npm global bin
    if ! echo "$PATH" | grep -q "$HOME/.npm-global/bin"; then
        export PATH="$HOME/.npm-global/bin:$PATH"
        if ! grep -q '.npm-global/bin' "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.bashrc"
        fi
    fi

    npm install -g openclaw@latest

    log "OpenClaw $(openclaw --version 2>/dev/null || echo 'installed') successfully."
}

# ---------------------------------------------------------------------------
# Install Claude Code CLI
# ---------------------------------------------------------------------------
install_claude_code() {
    log "Installing Claude Code CLI..."

    if command -v claude &>/dev/null; then
        log "Claude Code CLI already installed. Skipping."
        return 0
    fi

    curl -fsSL https://code.claude.com/install.sh | bash

    # Source updated PATH
    export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"

    if command -v claude &>/dev/null; then
        log "Claude Code CLI installed successfully."
    else
        warn "Claude Code CLI installed but not on PATH. Add ~/.local/bin or ~/.claude/bin to PATH."
    fi
}

# ---------------------------------------------------------------------------
# Create directory structure
# ---------------------------------------------------------------------------
setup_directories() {
    log "Setting up directory structure..."

    mkdir -p "$HOME/.openclaw"
    mkdir -p "$HOME/.openclaw/workspace"
    mkdir -p "$HOME/.openclaw/workspace/skills"
    mkdir -p "$HOME/.claude/skills"

    log "Directories created."
}

# ---------------------------------------------------------------------------
# Copy configuration template
# ---------------------------------------------------------------------------
copy_config() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local REPO_DIR
    REPO_DIR="$(dirname "$SCRIPT_DIR")"

    if [ -f "$HOME/.openclaw/openclaw.json" ]; then
        warn "OpenClaw config already exists at ~/.openclaw/openclaw.json. Skipping."
        warn "Reference template: $REPO_DIR/config/openclaw.json"
    else
        if [ -f "$REPO_DIR/config/openclaw.json" ]; then
            cp "$REPO_DIR/config/openclaw.json" "$HOME/.openclaw/openclaw.json"
            log "Config template copied to ~/.openclaw/openclaw.json"
            warn "Edit ~/.openclaw/openclaw.json and add your API keys before starting."
        fi
    fi
}

# ---------------------------------------------------------------------------
# Install skills
# ---------------------------------------------------------------------------
install_skills() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local REPO_DIR
    REPO_DIR="$(dirname "$SCRIPT_DIR")"

    # Install OpenClaw workspace skills
    if [ -d "$REPO_DIR/skills/openclaw" ]; then
        log "Installing OpenClaw workspace skills..."
        cp -r "$REPO_DIR/skills/openclaw/"* "$HOME/.openclaw/workspace/skills/" 2>/dev/null || true
        log "OpenClaw skills installed to ~/.openclaw/workspace/skills/"
    fi

    # Install Claude Code skills
    if [ -d "$REPO_DIR/skills/claude-code" ]; then
        log "Installing Claude Code skills..."
        cp -r "$REPO_DIR/skills/claude-code/"* "$HOME/.claude/skills/" 2>/dev/null || true
        log "Claude Code skills installed to ~/.claude/skills/"
    fi
}

# ---------------------------------------------------------------------------
# Install systemd service (optional)
# ---------------------------------------------------------------------------
install_service() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local REPO_DIR
    REPO_DIR="$(dirname "$SCRIPT_DIR")"

    if [ -f "$REPO_DIR/config/openclaw.service" ]; then
        log "Installing systemd service..."
        # Substitute the current username into the service file
        sed "s|__USER__|$USER|g; s|__HOME__|$HOME|g" \
            "$REPO_DIR/config/openclaw.service" \
            > /tmp/openclaw.service
        sudo cp /tmp/openclaw.service /etc/systemd/system/openclaw.service
        rm /tmp/openclaw.service
        sudo systemctl daemon-reload
        log "Systemd service installed. Enable with: sudo systemctl enable --now openclaw"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo ""
    echo "========================================="
    echo "  OpenClaw EC2 Installer"
    echo "========================================="
    echo ""

    install_system_deps
    install_node
    setup_directories
    install_openclaw
    install_claude_code
    copy_config
    install_skills
    install_service

    echo ""
    log "============================================"
    log "  Installation complete!"
    log "============================================"
    echo ""
    echo "Next steps:"
    echo "  1. Edit ~/.openclaw/openclaw.json with your API keys"
    echo "  2. Run: openclaw onboard"
    echo "  3. Enable the daemon: sudo systemctl enable --now openclaw"
    echo "  4. Check OpenClaw skills: ls ~/.openclaw/workspace/skills/"
    echo "  5. Check Claude Code skills: ls ~/.claude/skills/"
    echo ""
    echo "  Or run the interactive setup:"
    echo "    openclaw onboard --install-daemon"
    echo ""
}

main "$@"
