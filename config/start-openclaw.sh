#!/bin/bash
# OpenClaw Gateway startup wrapper for systemd
# This uses exec so the gateway process becomes PID 1 in the cgroup
export HOME="__HOME__"
export PATH="__HOME__/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export ANTHROPIC_API_KEY="__YOUR_ANTHROPIC_API_KEY__"
export NODE_ENV=production
cd __HOME__/.openclaw/workspace
exec __HOME__/.npm-global/bin/openclaw gateway --port 18789
