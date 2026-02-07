# ec2-openclaw

OpenClaw + WhatsApp integration on EC2.

## One-Command Setup (on your real EC2)

SSH into your EC2 instance and run:

```bash
git clone https://github.com/rakeshsundru/ec2-openclaw.git
cd ec2-openclaw
chmod +x ec2-full-setup.sh
./ec2-full-setup.sh
```

This script will:
1. Install Node.js 22 (if needed)
2. Install OpenClaw globally
3. Prompt for your Anthropic API key and WhatsApp number
4. Write the full config (`~/.openclaw/openclaw.json`)
5. Start the gateway
6. Show a QR code for WhatsApp linking

## Prerequisites

- EC2 instance (Ubuntu recommended) with internet access
- Node.js >= 22
- Anthropic API key ([get one here](https://console.anthropic.com/settings/keys))
- WhatsApp account with a phone number

## After Setup

Send a test message:
```bash
openclaw message send --to +916302642731 --message "Hello from OpenClaw!"
```

Chat with the agent:
```bash
openclaw agent --message "Summarize today's news" --to +916302642731 --deliver
```

Check status:
```bash
openclaw status
openclaw health
```

## Keep Gateway Running

Use `tmux` or `screen` so the gateway survives SSH disconnect:
```bash
tmux new -s openclaw
openclaw gateway --port 18789 --verbose
# Press Ctrl+B, then D to detach
# Reconnect later: tmux attach -t openclaw
```

## References

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Docs](https://docs.openclaw.ai/getting-started)
- [WhatsApp Channel Docs](https://docs.openclaw.ai/channels/whatsapp)
- [OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills)
