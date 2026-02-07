---
name: deploy-update
description: Update OpenClaw to the latest version on this EC2 instance
user-invocable: true
---

When the user asks to update or upgrade OpenClaw, follow these steps:

## Pre-Update Checks
1. Check current version: `openclaw --version`
2. Check if the gateway is running: `systemctl is-active openclaw`
3. Check available disk space: `df -h /`

## Update Process
1. Stop the OpenClaw service: `sudo systemctl stop openclaw`
2. Update OpenClaw: `npm update -g openclaw@latest`
3. Verify new version: `openclaw --version`
4. Run diagnostics: `openclaw doctor`
5. Start the service: `sudo systemctl start openclaw`
6. Verify service is running: `systemctl status openclaw`

## Rollback
If the update causes issues:
1. Stop the service: `sudo systemctl stop openclaw`
2. Install the previous version: `npm install -g openclaw@<previous-version>`
3. Restart: `sudo systemctl start openclaw`

## Channel Selection
To switch release channels:
- Stable: `openclaw update --channel stable`
- Beta: `openclaw update --channel beta`
- Dev: `openclaw update --channel dev`

Always confirm with the user before switching to non-stable channels.
