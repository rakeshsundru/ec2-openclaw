---
name: ec2-manage
description: Manage the EC2 instance running OpenClaw - check system resources, restart services, view logs
user-invocable: true
---

You are managing an OpenClaw instance running on an AWS EC2 server. When the user asks you to manage the EC2 instance, follow these guidelines:

## System Health
- Check disk usage: `df -h`
- Check memory: `free -h`
- Check CPU load: `uptime`
- Check running processes: `ps aux --sort=-%mem | head -20`

## OpenClaw Service Management
- View status: `systemctl status openclaw`
- View logs: `journalctl -u openclaw --no-pager -n 50`
- Restart service: `sudo systemctl restart openclaw`
- Stop service: `sudo systemctl stop openclaw`
- Start service: `sudo systemctl start openclaw`

## OpenClaw Configuration
- Config location: `~/.openclaw/openclaw.json`
- Workspace: `~/.openclaw/workspace/`
- Skills directory: `~/.openclaw/workspace/skills/`

## Safety Rules
- Always confirm before restarting or stopping the OpenClaw service
- Never modify API keys without user confirmation
- Check disk space before any large operations
