# ec2-openclaw

OpenClaw installation and configuration for EC2 instances.

## Quick Setup

```bash
chmod +x setup.sh
./setup.sh
```

## Prerequisites

- Node.js >= 22
- npm or pnpm

## After Setup

1. **Set your API key:**
   ```bash
   export ANTHROPIC_API_KEY="your-key"
   openclaw config set agent.model anthropic/claude-opus-4-6
   ```

2. **Start the gateway** (foreground, since EC2 containers lack systemd):
   ```bash
   openclaw gateway --port 18789 --verbose
   ```

3. **Connect a channel** (WhatsApp, Telegram, etc.):
   ```bash
   openclaw channels login --verbose
   ```

4. **Test it:**
   ```bash
   openclaw agent --message "Hello from EC2!"
   ```

## If Your Session Resets

Run `./setup.sh` again to reinstall and reconfigure OpenClaw.

## References

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Docs](https://docs.openclaw.ai/getting-started)
- [OpenClaw Skills](https://github.com/VoltAgent/awesome-openclaw-skills)
