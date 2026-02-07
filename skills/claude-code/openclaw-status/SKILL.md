---
name: openclaw-status
description: Check the status of the local OpenClaw gateway and connected channels
user-invocable: true
---

When invoked, check the OpenClaw gateway status on this machine:

1. Check if the OpenClaw gateway process is running:
   - `systemctl is-active openclaw` (if installed as systemd service)
   - `ss -tlnp | grep 18789` (check if gateway port is listening)

2. Show the current configuration summary:
   - Read `~/.openclaw/openclaw.json` and display the configured model, enabled channels, and gateway settings
   - Do NOT display API keys or secrets

3. Show recent gateway logs:
   - `journalctl -u openclaw --no-pager -n 20`

4. List installed workspace skills:
   - `ls ~/.openclaw/workspace/skills/`

Present a concise summary of the gateway health and connected services.
