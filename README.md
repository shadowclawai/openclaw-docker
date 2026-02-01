# OpenClaw Docker Setup for macOS 🐺

This setup fixes the permission issues that occur when running OpenClaw in Docker on macOS.

## The Problem

- Docker container runs as `node` user (uid 1000)
- macOS users typically have uid 501
- Mounted files keep host permissions → container can't read them
- Result: "invalid credentials" errors, crashes

## The Solution

Custom Dockerfile with an init script that:
1. Creates proper directory structure
2. Fixes permissions before starting
3. Uses `gosu` to switch to `node` user

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
docker compose up -d openclaw-gateway

# View logs
docker compose logs -f

# Stop
docker compose down

# Run CLI commands
docker compose run --rm openclaw-cli status
docker compose run --rm openclaw-cli providers login
```

## Dashboard Access

- URL: http://localhost:18789
- Token: (printed during setup, also in `.env` file)

## Files

- `docker-compose.yml` - Main compose file
- `Dockerfile.macos` - Custom Dockerfile with permission fixes
- `setup.sh` - One-click setup script
- `.env` - Generated environment variables (contains token)

## Troubleshooting

### Still getting permission errors?
```bash
# Reset and rebuild
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### Can't access dashboard?
- Make sure port 18789 isn't in use: `lsof -i :18789`
- Check logs: `docker compose logs openclaw-gateway`

### Credentials not working?
- Credentials are mounted from `~/.openclaw/credentials`
- Make sure your API keys are set up locally first
