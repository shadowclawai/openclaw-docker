# OpenClaw Docker Setup for macOS 🐺

This setup fixes the permission issues that occur when running OpenClaw in Docker on macOS.

## The Problem

- Docker container runs as `node` user (uid 1000)
- macOS users typically have uid 501
- Mounted files keep host permissions → container can't read them
- Config paths like `/Users/username/...` don't exist in container
- Result: "invalid credentials" errors, crashes

## The Solution

Custom Dockerfile with an init script that:
1. Creates symlink `/Users/<username> -> /home/node` for path compatibility
2. Fixes permissions on essential directories (skips .git to avoid hanging)
3. Uses `gosu` to switch to `node` user
4. Security hardening (no-new-privileges, dropped capabilities)

## Prerequisites

**Critical:** Your `~/.openclaw/openclaw.json` must have:
```json
{
  "gateway": {
    "bind": "lan"  // NOT "loopback"!
  }
}
```

Without this, the web UI won't be accessible from outside the container.

## Quick Start

```bash
~/.openclaw/docker/setup.sh
```

This will:
1. Clone OpenClaw source (if needed)
2. Build the Docker image
3. Start the gateway
4. Print the dashboard URL and token

## Manual Commands

```bash
cd ~/.openclaw/docker

# Build image
docker compose build

# Start gateway
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Run CLI commands
docker compose run --rm openclaw-cli status
```

## Dashboard Access

- URL: http://localhost:18789
- Token: Check `~/.openclaw/openclaw.json` → `gateway.auth.token`

## Security Hardening

This setup includes:
- `no-new-privileges` - prevents privilege escalation
- `cap_drop: ALL` - drops all Linux capabilities
- Selective `cap_add` for only what's needed (CHOWN, SETUID, SETGID)
- `tmpfs` for /tmp

### Recommended: Command Allowlist

Create `~/.openclaw/exec-approvals.json`:
```json
{
  "version": 1,
  "defaults": {
    "security": "allowlist",
    "ask": "on-miss"
  },
  "agents": {
    "main": {
      "allowlist": [
        { "pattern": "git *" },
        { "pattern": "npm *" },
        { "pattern": "node *" },
        { "pattern": "ls *" },
        { "pattern": "cat *" },
        { "pattern": "curl *" }
      ]
    }
  }
}
```

This prevents prompt injection attacks from executing arbitrary commands.

### Recommended: Lock Credentials

```bash
chmod 600 ~/.openclaw/credentials/*.json
```

## Files

- `docker-compose.yml` - Main compose file with security hardening
- `Dockerfile.macos` - Custom Dockerfile with permission fixes
- `setup.sh` - One-click setup script
- `.env` - Generated environment variables

## Troubleshooting

### "pairing required" error
Your device needs to be approved:
```bash
openclaw devices list
openclaw devices approve <request-id>
```

### Can't access dashboard (connection refused)?
1. Check `bind: "lan"` in your config (not "loopback")
2. Restart container after config change
3. Check logs: `docker logs openclaw`

### chown hanging on startup?
The entrypoint skips .git directories. If still hanging, the mounted volume may have permission issues:
```bash
# On host, fix permissions
chmod -R a+r ~/.openclaw/workspace
```

### Path errors like "EACCES: mkdir '/Users'"
The entrypoint creates a symlink for this. Make sure `OPENCLAW_HOST_USER` env var is set (defaults to `$USER`).

### Logo not loading (403)?
The UI source may have a CDN URL with expired signature. Rebuild after fixing:
```bash
# In openclaw-source/ui/src/ui/app-render.ts, replace CDN URL with ./favicon.svg
docker compose build --no-cache
docker compose up -d
```

## Security Reference

Based on recommendations from the OpenClaw security guide:
- ✅ Sandbox mode (Docker container)
- ✅ Command allowlist
- ✅ Credential permissions
- ✅ Device pairing
- ✅ Minimal container privileges
- ⏳ Tailscale (optional, for secure remote access)
