# ec2-openclaw

Deploy [OpenClaw](https://github.com/openclaw/openclaw) (formerly ClaudBot) on an AWS EC2 instance with pre-configured skills.

## What's Included

```
ec2-openclaw/
├── scripts/
│   └── install.sh              # One-step EC2 installer
├── config/
│   ├── openclaw.json           # Configuration template
│   └── openclaw.service        # systemd unit file
├── skills/
│   ├── openclaw/               # OpenClaw workspace skills
│   │   ├── ec2-manage/         # /ec2-manage - manage the EC2 instance
│   │   ├── health-check/       # /health-check - run diagnostics
│   │   └── deploy-update/      # /deploy-update - update OpenClaw
│   └── claude-code/            # Claude Code skills
│       ├── openclaw-status/    # /openclaw-status - check gateway status
│       └── security-audit/     # /security-audit - audit deployment security
└── README.md
```

## Prerequisites

- EC2 instance (t3.small or larger, 2 GB+ RAM)
- Amazon Linux 2023, Ubuntu 22.04/24.04, or Debian 12
- Non-root user with sudo access
- An [Anthropic API key](https://console.anthropic.com/)

## Quick Start

```bash
# 1. Clone this repo on your EC2 instance
git clone https://github.com/rakeshsundru/ec2-openclaw.git
cd ec2-openclaw

# 2. Run the installer
chmod +x scripts/install.sh
./scripts/install.sh

# 3. Add your API key to the config
nano ~/.openclaw/openclaw.json
# Replace __YOUR_ANTHROPIC_API_KEY__ with your actual key

# 4. Run the interactive onboarding
openclaw onboard --install-daemon
```

## Configuration

The installer copies `config/openclaw.json` to `~/.openclaw/openclaw.json`. Key settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `agent.model` | `anthropic/claude-sonnet-4-20250514` | LLM model to use |
| `gateway.port` | `18789` | Gateway WebSocket port |
| `gateway.auth.mode` | `token` | Authentication mode |
| `channels.webchat.enabled` | `true` | Enable browser-based chat |

To connect messaging platforms (Telegram, Discord, Slack, etc.), add their configuration under the `channels` key. See the [OpenClaw docs](https://docs.openclaw.ai) for channel setup.

## Skills

### OpenClaw Workspace Skills

Installed to `~/.openclaw/workspace/skills/`:

- **`/ec2-manage`** - Check system resources, restart services, view logs
- **`/health-check`** - Run full diagnostics on the OpenClaw installation
- **`/deploy-update`** - Update OpenClaw to the latest version

### Claude Code Skills

Installed to `~/.claude/skills/`:

- **`/openclaw-status`** - Check gateway status and connected channels
- **`/security-audit`** - Audit the deployment for common security issues

### Adding Custom Skills

Create a new directory under `skills/openclaw/` or `skills/claude-code/` with a `SKILL.md` file:

```markdown
---
name: my-skill
description: What this skill does
user-invocable: true
---

Instructions for the agent when this skill is invoked...
```

Re-run the install script or manually copy to the appropriate skills directory.

## Service Management

The installer sets up a systemd service:

```bash
# Enable and start
sudo systemctl enable --now openclaw

# Check status
sudo systemctl status openclaw

# View logs
journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw
```

## Security Notes

- Never run OpenClaw as root
- The gateway binds to `127.0.0.1` by default (localhost only)
- Use Tailscale Serve/Funnel or SSH tunnels for remote access
- Run `/security-audit` to check your deployment
- Run `openclaw doctor` to surface risky configurations
- Keep API keys out of version control

## License

MIT
