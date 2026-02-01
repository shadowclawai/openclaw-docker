#!/bin/bash
# OpenClaw Docker Setup for macOS
# Builds and runs OpenClaw in Docker with proper permissions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

echo "🐺 OpenClaw Docker Setup for macOS"
echo ""

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop for Mac."
    exit 1
fi

if ! docker compose version &>/dev/null; then
    echo "❌ Docker Compose not available."
    exit 1
fi

# Check for openclaw source
OPENCLAW_SOURCE="$OPENCLAW_DIR/workspace/openclaw-source"
if [[ ! -d "$OPENCLAW_SOURCE" ]]; then
    echo "📥 Cloning OpenClaw source..."
    git clone https://github.com/openclaw/openclaw.git "$OPENCLAW_SOURCE"
fi
export OPENCLAW_SOURCE_DIR="$OPENCLAW_SOURCE"

# Generate token if not set
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
    export OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
    echo "🔑 Generated gateway token"
fi

# Ensure directories exist
mkdir -p "$OPENCLAW_DIR"/{credentials,sessions,logs,workspace,media}

# Create .env file
ENV_FILE="$SCRIPT_DIR/.env"
cat > "$ENV_FILE" << EOF
OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
OPENCLAW_SOURCE_DIR=${OPENCLAW_SOURCE_DIR}
HOME=${HOME}
EOF

# Copy API keys from existing credentials if available
if [[ -f "$OPENCLAW_DIR/credentials/anthropic.json" ]]; then
    ANTHROPIC_KEY=$(cat "$OPENCLAW_DIR/credentials/anthropic.json" 2>/dev/null | grep -o '"api_key":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$ANTHROPIC_KEY" ]]; then
        echo "ANTHROPIC_API_KEY=${ANTHROPIC_KEY}" >> "$ENV_FILE"
        echo "✅ Found Anthropic API key"
    fi
fi

echo ""
echo "🔨 Building Docker image (this may take a few minutes)..."
docker compose -f "$COMPOSE_FILE" build

echo ""
echo "🚀 Starting OpenClaw Gateway..."
docker compose -f "$COMPOSE_FILE" up -d openclaw-gateway

echo ""
echo "✅ OpenClaw is running!"
echo ""
echo "📊 Dashboard: http://localhost:18789"
echo "🔑 Token: ${OPENCLAW_GATEWAY_TOKEN}"
echo ""
echo "Commands:"
echo "  View logs:  docker compose -f $COMPOSE_FILE logs -f"
echo "  Stop:       docker compose -f $COMPOSE_FILE down"
echo "  CLI:        docker compose -f $COMPOSE_FILE run --rm openclaw-cli <command>"
echo ""
echo "Save this token to connect from the dashboard!"
