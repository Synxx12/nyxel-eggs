#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         Bun.js Pterodactyl Entrypoint — nyxel               ║
# ║         https://nyxel.my.id                                  ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${CYAN}[EGG]${RESET} $*"; }
ok()   { echo -e "${GREEN}[EGG] ✓${RESET} $*"; }
warn() { echo -e "${YELLOW}[EGG] ⚠${RESET} $*"; }
fail() { echo -e "${RED}[EGG] ✗${RESET} $*"; exit 1; }

echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ██╗   ██╗███╗   ██╗   ██╗███████╗"
echo "  ██╔══██╗██║   ██║████╗  ██║   ██║██╔════╝"
echo "  ██████╔╝██║   ██║██╔██╗ ██║   ██║███████╗"
echo "  ██╔══██╗██║   ██║██║╚██╗██║   ██║╚════██║"
echo "  ██████╔╝╚██████╔╝██║ ╚████║██╗██║███████║"
echo "  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝╚══════╝"
echo -e "${RESET}${CYAN}  Pterodactyl Egg by nyxel — https://nyxel.my.id${RESET}"
echo ""

cd /home/container || fail "Cannot cd into /home/container"

# ── Ensure Bun is available ───────────────────────────────────────────────────
export PATH="$HOME/.bun/bin:/usr/local/bin:$PATH"

if ! command -v bun &>/dev/null; then
  log "Bun not found — installing..."
  curl -fsSL https://bun.sh/install | bash || fail "Failed to install Bun"
  export PATH="$HOME/.bun/bin:$PATH"
fi

BUN_VERSION=$(bun --version 2>/dev/null || echo "unknown")
ok "Bun version: ${BUN_VERSION}"

# ── Git ───────────────────────────────────────────────────────────────────────
GIT_URL="${GIT_URL:-}"; GIT_BRANCH="${GIT_BRANCH:-}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"; USERNAME="${USERNAME:-}"; ACCESS_TOKEN="${ACCESS_TOKEN:-}"

if [ -n "${GIT_URL}" ]; then
  AUTHENTICATED_URL="${GIT_URL}"
  if [ -n "${USERNAME}" ] && [ -n "${ACCESS_TOKEN}" ]; then
    AUTHENTICATED_URL="https://${USERNAME}:${ACCESS_TOKEN}@$(echo "${GIT_URL}" | sed 's|https://||')"
  fi

  if [ -d /home/container/.git ]; then
    if [ "${AUTO_UPDATE}" = "1" ]; then
      log "Auto-update — pulling latest..."
      git -C /home/container remote set-url origin "${AUTHENTICATED_URL}" 2>/dev/null || true
      git -C /home/container reset --hard
      git -C /home/container pull origin "${GIT_BRANCH:-$(git -C /home/container symbolic-ref --short HEAD 2>/dev/null || echo main)}" || warn "git pull failed"
      ok "Repository updated."
    fi
  else
    log "Cloning repository..."
    if [ -n "${GIT_BRANCH}" ]; then
      git clone --single-branch --branch "${GIT_BRANCH}" "${AUTHENTICATED_URL}" /tmp/bun_clone || fail "git clone failed"
    else
      git clone "${AUTHENTICATED_URL}" /tmp/bun_clone || fail "git clone failed"
    fi
    find /home/container -mindepth 1 -not -path '/home/container/.pterodactyl*' -delete 2>/dev/null || true
    cp -a /tmp/bun_clone/. /home/container/
    rm -rf /tmp/bun_clone
    ok "Repository cloned."
  fi
fi

# ── .env Injection ────────────────────────────────────────────────────────────
if [ -f /home/container/.env.pterodactyl ]; then
  cp -f /home/container/.env.pterodactyl /home/container/.env
  ok ".env.pterodactyl → .env"
fi

# ── Install Dependencies ──────────────────────────────────────────────────────
if [ -f /home/container/package.json ]; then
  log "Installing dependencies with bun..."
  cd /home/container
  bun install || fail "bun install failed"
  ok "Dependencies installed."
elif [ -f /home/container/bun.lockb ] || [ -f /home/container/bun.lock ]; then
  log "Installing from lockfile..."
  cd /home/container
  bun install || fail "bun install failed"
  ok "Dependencies installed."
fi

# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"
if [ -n "${CLOUDFLARE_TOKEN}" ]; then
  if ! command -v cloudflared &>/dev/null; then
    ARCH=$(uname -m); case "${ARCH}" in x86_64) CF_ARCH="amd64";; aarch64) CF_ARCH="arm64";; *) CF_ARCH="amd64";; esac
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared || warn "cloudflared download failed"
  fi
  command -v cloudflared &>/dev/null && { cloudflared tunnel --no-autoupdate run --token "${CLOUDFLARE_TOKEN}" & ok "Cloudflare Tunnel started."; }
fi

# ── Build (optional) ──────────────────────────────────────────────────────────
BUILD_COMMAND="${BUILD_COMMAND:-}"
if [ -n "${BUILD_COMMAND}" ]; then
  log "Running build: ${BUILD_COMMAND}"
  eval "${BUILD_COMMAND}" || fail "Build failed"
  ok "Build complete."
fi

# ── Resolve Entry Point ───────────────────────────────────────────────────────
ENTRY_POINT="${ENTRY_POINT:-}"
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"

resolve_entry() {
  if [ -n "${ENTRY_POINT}" ]; then
    echo "${ENTRY_POINT}"; return
  fi
  # Try package.json main
  if [ -f package.json ]; then
    MAIN=$(bun -e "const p=require('./package.json'); process.stdout.write(p.main||'')" 2>/dev/null || true)
    [ -n "${MAIN}" ] && [ -f "${MAIN}" ] && { echo "${MAIN}"; return; }
  fi
  # Common fallbacks
  for f in src/index.ts index.ts src/index.js index.js src/server.ts server.ts src/app.ts app.ts; do
    [ -f "${f}" ] && { echo "${f}"; return; }
  done
  echo ""
}

RESOLVED=$(resolve_entry)

if [ "${NODE_RUN_ENV}" = "production" ]; then
  log "Mode: ${BOLD}production${RESET}"

  if [ -n "${RESOLVED}" ]; then
    ok "Entry: ${RESOLVED}"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production bun run "${RESOLVED}"

  elif grep -q '"start"' package.json 2>/dev/null; then
    ok "Using bun script: start"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production bun run start

  elif grep -q '"start:prod"' package.json 2>/dev/null; then
    ok "Using bun script: start:prod"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production bun run start:prod

  else
    fail "No entry point found. Set ENTRY_POINT or add a 'start' script to package.json."
  fi

else
  log "Mode: ${BOLD}development${RESET} (hot-reload with --watch)"

  if [ -n "${RESOLVED}" ]; then
    ok "Entry: ${RESOLVED} (--watch)"
    PORT=${SERVER_PORT:-3000} NODE_ENV=development bun --watch run "${RESOLVED}"

  elif grep -q '"dev"' package.json 2>/dev/null; then
    ok "Using bun script: dev"
    PORT=${SERVER_PORT:-3000} NODE_ENV=development bun run dev

  elif grep -q '"start:dev"' package.json 2>/dev/null; then
    ok "Using bun script: start:dev"
    PORT=${SERVER_PORT:-3000} NODE_ENV=development bun run start:dev

  else
    fail "No dev entry found. Set ENTRY_POINT or add a 'dev' script to package.json."
  fi
fi
