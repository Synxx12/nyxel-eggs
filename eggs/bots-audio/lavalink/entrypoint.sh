#!/bin/bash
# ============================================================
#   nyxel-eggs — Lavalink entrypoint (production-grade)
#   https://nyxel.my.id
#   Version: 1.0.0
# ============================================================

set -eo pipefail

# ── Signal trap for graceful shutdown ──────────────────────
CF_PID=""
cleanup() {
  echo ""
  echo "[SHUTDOWN] Received shutdown signal, cleaning up..."
  if [ -n "$CF_PID" ]; then
    kill "$CF_PID" 2>/dev/null || true
    wait "$CF_PID" 2>/dev/null || true
    echo "[SHUTDOWN] Cloudflare Tunnel stopped."
  fi
  exit 0
}
trap cleanup SIGTERM SIGINT

# ── Banner ─────────────────────────────────────────────────
echo ""
echo "  ██╗      █████╗ ██╗   ██╗ █████╗ ██╗     ██╗███╗   ██╗██╗  ██╗"
echo "  ██║     ██╔══██╗██║   ██║██╔══██╗██║     ██║████╗  ██║██║ ██╔╝"
echo "  ██║     ███████║██║   ██║███████║██║     ██║██╔██╗ ██║█████╔╝ "
echo "  ██║     ██╔══██║╚██╗ ██╔╝██╔══██║██║     ██║██║╚██╗██║██╔═██╗ "
echo "  ███████╗██║  ██║ ╚████╔╝ ██║  ██║███████╗██║██║ ╚████║██║  ██╗"
echo "  ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝"
echo ""
echo "  🥚 nyxel-eggs — Lavalink   |   nyxel.my.id"
echo "  ──────────────────────────────────────────"
echo ""

# ── Environment ───────────────────────────────────────────
LAVALINK_VERSION="${LAVALINK_VERSION:-LATEST}"
SERVER_PORT="${SERVER_PORT:-2333}"
SERVER_PASSWORD="${SERVER_PASSWORD:-youshallnotpass}"
SERVER_MEMORY="${SERVER_MEMORY:-512}"
LAVALINK_PLUGINS="${LAVALINK_PLUGINS:-}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

JAR_FILE="/home/container/Lavalink.jar"
GITHUB_API="https://api.github.com/repos/lavalink-devs/Lavalink/releases"

echo "[INFO] Java version: $(java -version 2>&1 | head -1)"
echo "[INFO] Lavalink version target: $LAVALINK_VERSION"
echo ""

cd /home/container

# ── Resolve download URL ─────────────────────────────────
if [[ "${LAVALINK_VERSION}" == "LATEST" ]]; then
  echo "[INFO] Resolving latest Lavalink release..."
  RELEASE_JSON=$(curl -fsSL "${GITHUB_API}/latest")
  RESOLVED_VERSION=$(echo "$RELEASE_JSON" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/')
  DOWNLOAD_URL=$(echo "$RELEASE_JSON" | grep '"browser_download_url"' | grep 'Lavalink.jar"' | head -1 | sed 's/.*"browser_download_url": "\(.*\)".*/\1/')
else
  RESOLVED_VERSION="${LAVALINK_VERSION}"
  DOWNLOAD_URL="https://github.com/lavalink-devs/Lavalink/releases/download/${LAVALINK_VERSION}/Lavalink.jar"
fi

if [[ -z "${DOWNLOAD_URL}" ]]; then
  echo "[ERROR] Failed to resolve Lavalink download URL. Check LAVALINK_VERSION."
  exit 1
fi

echo "[INFO] Resolved version: ${RESOLVED_VERSION}"

# ── Download JAR if not present ──────────────────────────
if [[ ! -f "${JAR_FILE}" ]]; then
  echo "[JAR] Downloading Lavalink ${RESOLVED_VERSION}..."
  curl -fsSL -o "${JAR_FILE}" "${DOWNLOAD_URL}"
  if [[ $? -ne 0 ]]; then
    echo "[ERROR] Download failed. Check network connectivity or version tag."
    exit 1
  fi
  echo "[JAR] Download complete."
else
  echo "[JAR] Lavalink.jar already present — skipping download."
fi

# ── Generate application.yml ─────────────────────────────
echo "[CONFIG] Writing application.yml..."

# Build plugins block
PLUGINS_BLOCK=""
if [[ -n "${LAVALINK_PLUGINS}" ]]; then
  IFS=',' read -ra PLUGIN_LIST <<< "${LAVALINK_PLUGINS}"
  for plugin_url in "${PLUGIN_LIST[@]}"; do
    trimmed="$(echo "$plugin_url" | xargs)"
    PLUGINS_BLOCK="${PLUGINS_BLOCK}    - url: \"${trimmed}\"\n"
  done
fi

cat > /home/container/application.yml <<EOF
server:
  port: ${SERVER_PORT}
  address: 0.0.0.0
  http2:
    enabled: false

plugins:
  youtube:
    enabled: true
    allowSearch: true
    allowDirectVideoIds: true
    allowDirectPlaylistIds: true
    clients:
      - MUSIC
      - ANDROID_TESTSUITE
      - WEB
      - TVHTML5EMBEDDED

lavalink:
  plugins:
$(if [[ -n "${PLUGINS_BLOCK}" ]]; then printf "%b" "${PLUGINS_BLOCK}"; else echo "    []"; fi)
  server:
    password: "${SERVER_PASSWORD}"
    sources:
      youtube: true
      bandcamp: true
      soundcloud: true
      twitch: true
      vimeo: true
      http: true
      local: false
    bufferDurationMs: 400
    frameBufferDurationMs: 5000
    opusEncodingQuality: 10
    resamplingQuality: LOW
    trackStuckThresholdMs: 10000
    useSeekGhosting: true
    youtubePlaylistLoadLimit: 6
    playerUpdateInterval: 5
    youtubeSearchEnabled: true
    soundcloudSearchEnabled: true
    gc-warnings: true

metrics:
  prometheus:
    enabled: false
    endpoint: /metrics

sentry:
  dsn: ""
  environment: ""

logging:
  file:
    path: ./logs/
  level:
    root: INFO
    lavalink: INFO
  request:
    enabled: true
    includeClientInfo: true
    includeHeaders: false
    includeQueryString: true
    includePayload: true
    maxPayloadLength: 10000
EOF

echo "[CONFIG] application.yml written."
echo ""

# ── Cloudflare Tunnel ────────────────────────────────────
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "[CF] Starting Cloudflare Tunnel..."
  CF_BIN="/home/container/.pterodactyl/cloudflared"
  mkdir -p /home/container/.pterodactyl
  if [ ! -x "$CF_BIN" ]; then
    echo "[CF] Downloading cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
      -o "$CF_BIN" && chmod +x "$CF_BIN" || {
      echo "[CF] ✗ Failed to download cloudflared — continuing without tunnel."
      CF_BIN=""
    }
  fi
  if [ -n "$CF_BIN" ]; then
    "$CF_BIN" tunnel --no-autoupdate run --token "$CLOUDFLARE_TOKEN" \
      > /home/container/.pterodactyl/cloudflared.log 2>&1 &
    CF_PID=$!
    echo "[CF] Tunnel started (PID: $CF_PID) — logs: .pterodactyl/cloudflared.log"
  fi
fi

# ── Launch ───────────────────────────────────────────────
echo "[START] Starting Lavalink on port ${SERVER_PORT} (heap: ${SERVER_MEMORY}MB)..."
echo ""

exec java -Xmx${SERVER_MEMORY}M -jar "${JAR_FILE}"
