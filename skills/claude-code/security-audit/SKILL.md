---
name: security-audit
description: Audit the OpenClaw EC2 deployment for common security issues
user-invocable: true
---

When asked to perform a security audit of the OpenClaw deployment, check the following:

## Authentication & Access
1. Verify OpenClaw is NOT running as root: `ps aux | grep openclaw | grep -v grep`
2. Check gateway auth mode in `~/.openclaw/openclaw.json` - warn if auth mode is "none"
3. Verify gateway is bound to localhost (127.0.0.1), not 0.0.0.0
4. Check SSH configuration: `sudo sshd -T 2>/dev/null | grep -E "^(permitrootlogin|passwordauthentication)"`

## Network
5. List open ports: `ss -tlnp`
6. Check if any unexpected services are exposed
7. Verify EC2 security group is not overly permissive (if AWS CLI is available): `aws ec2 describe-security-groups --query 'SecurityGroups[*].{ID:GroupId,Rules:IpPermissions}' 2>/dev/null || echo "AWS CLI not configured"`

## File Permissions
8. Check config file permissions: `ls -la ~/.openclaw/openclaw.json` - should not be world-readable
9. Check workspace permissions: `ls -la ~/.openclaw/workspace/`

## Updates
10. Check if OpenClaw is on the latest version
11. Check for OS security updates: `sudo apt list --upgradable 2>/dev/null || sudo dnf check-update 2>/dev/null`

## Report
Present findings as a security report with severity levels (Critical, Warning, Info) and remediation steps for any issues found.
