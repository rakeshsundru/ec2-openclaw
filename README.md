# ec2-openclaw

Deploy [OpenClaw](https://github.com/openclaw/openclaw) on an AWS EC2 instance with skills.

Based on: [How to Set Up OpenClaw AI on AWS](https://dev.to/brayanarrieta/how-to-set-up-openclaw-ai-on-aws-3a0j)

## Prerequisites

- EC2 instance (t3.medium or larger, 4 GB+ RAM)
- Ubuntu 24.04 LTS or Amazon Linux
- Security group: port 22 (SSH) + port 18789 (Gateway)
- An [Anthropic API key](https://console.anthropic.com/)

## Quick Start

```bash
# SSH into your EC2 instance
ssh -i ~/.ssh/yourkey.pem ubuntu@YOUR_INSTANCE_IP

# Install Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

# Run the onboarding wizard (configures gateway, workspace, channels, daemon)
openclaw onboard --install-daemon

# Set your API key
openclaw configure
```

That's it. The `openclaw onboard` wizard handles config, workspace, channels, skills, and the systemd daemon.

## Verify

```bash
# Check gateway status
openclaw doctor

# Start the gateway
openclaw gateway --port 18789

# Access UI
# http://YOUR_INSTANCE_IP:18789/
```

## Automated Setup

For automated/scripted deployments, use the included installer:

```bash
git clone https://github.com/rakeshsundru/ec2-openclaw.git
cd ec2-openclaw
chmod +x scripts/install.sh
./scripts/install.sh
```

Or provision a fresh EC2 instance with everything pre-installed:

```bash
chmod +x scripts/provision-ec2.sh
./scripts/provision-ec2.sh
```

## Skills

### OpenClaw Workspace Skills (`~/.openclaw/workspace/skills/`)

- **`/ec2-manage`** - Check system resources, restart services, view logs
- **`/health-check`** - Run diagnostics on the installation
- **`/deploy-update`** - Update OpenClaw to the latest version

### Claude Code Skills (`~/.claude/skills/`)

- **`/openclaw-status`** - Check gateway status and connected channels
- **`/security-audit`** - Audit deployment security

### Adding Custom Skills

```
~/.openclaw/workspace/skills/my-skill/SKILL.md
```

## Security

- Run OpenClaw as a non-root user
- Do not expose the Gateway port (18789) to the public internet without protection
- Use a reverse proxy (Nginx) with HTTPS, VPN, or SSH tunnel for remote access
- Rotate API keys periodically
- Run `openclaw doctor` to surface risky configurations

## Service Management

```bash
sudo systemctl status openclaw
sudo systemctl restart openclaw
journalctl -u openclaw -f
```

## License

MIT
