---
name: health-check
description: Run diagnostics on the OpenClaw installation and verify all components are functioning
user-invocable: true
---

When asked to perform a health check, run the following diagnostics and report results:

## Checks to Perform

1. **Node.js version**: Run `node -v` and verify it is >= v22
2. **OpenClaw installed**: Run `openclaw --version`
3. **OpenClaw doctor**: Run `openclaw doctor` for built-in diagnostics
4. **Gateway connectivity**: Check if the gateway is running on port 18789: `ss -tlnp | grep 18789`
5. **Systemd service**: Run `systemctl is-active openclaw`
6. **Disk space**: Run `df -h /` and warn if usage > 80%
7. **Memory**: Run `free -h` and warn if available memory < 500MB
8. **Config validity**: Check that `~/.openclaw/openclaw.json` exists and is valid JSON: `python3 -m json.tool ~/.openclaw/openclaw.json > /dev/null 2>&1 && echo "Valid" || echo "Invalid"`
9. **Skills directory**: List installed skills: `ls ~/.openclaw/workspace/skills/`
10. **Claude Code**: Check if Claude Code CLI is installed: `claude --version 2>/dev/null || echo "Not installed"`

## Output Format

Present results as a checklist with pass/fail indicators for each check. Summarize any issues found and suggest remediation steps.
