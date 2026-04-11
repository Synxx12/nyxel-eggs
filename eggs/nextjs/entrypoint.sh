#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         Next.js Pterodactyl Entrypoint — nyxel              ║
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
echo "  ███╗   ██╗███████╗██╗  ██╗████████╗   ██╗███████╗"
echo "  ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝   ██║██╔════╝"
echo "  ██╔██╗ ██║█████╗   ╚███╔╝    ██║      ██║███████╗"
echo "  ██║╚██╗██║██╔══╝   ██╔██╗    ██║ ██   ██║╚════██║"
echo "  ██║ ╚████║███████╗██╔╝ ██╗   ██║ ╚█████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝  ╚════╝ ╚══════╝"
echo -e "${RESET}${CYAN}  Pterodactyl Egg by nyxel — https://nyxel.my.id${RESET}"
echo ""

cd /home/container || fail "Cannot cd into /home/container"

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
      log "Auto-update — pulling latest commits..."
      git -C /home/container remote set-url origin "${AUTHENTICATED_URL}" 2>/dev/null || true
      git -C /home/container reset --hard
      git -C /home/container pull origin "${GIT_BRANCH:-$(git -C /home/container symbolic-ref --short HEAD 2>/dev/null || echo main)}" || warn "git pull failed"
      ok "Repository updated."
    else
      log "Auto-update disabled."
    fi
  else
    log "Cloning repository..."
    CLONE_ARGS=("${AUTHENTICATED_URL}" /tmp/nextjs_clone)
    if [ -n "${GIT_BRANCH}" ]; then
      git clone --single-branch --branch "${GIT_BRANCH}" "${CLONE_ARGS[@]}" || fail "git clone failed"
    else
      git clone "${CLONE_ARGS[@]}" || fail "git clone failed"
    fi
    find /home/container -mindepth 1 -not -path '/home/container/.pterodactyl*' -delete 2>/dev/null || true
    cp -a /tmp/nextjs_clone/. /home/container/
    rm -rf /tmp/nextjs_clone
    ok "Repository cloned."
  fi
fi

# ── .env Injection ────────────────────────────────────────────────────────────
if [ -f /home/container/.env.pterodactyl ]; then
  cp -f /home/container/.env.pterodactyl /home/container/.env
  ok ".env.pterodactyl → .env"
fi

[ -f /home/container/package.json ] || fail "No package.json found."

# ── Package Manager ───────────────────────────────────────────────────────────
PACKAGE_MANAGER="${PACKAGE_MANAGER:-auto}"
if [ "${PACKAGE_MANAGER}" = "auto" ]; then
  if [ -f /home/container/pnpm-lock.yaml ]; then PACKAGE_MANAGER="pnpm"
  elif [ -f /home/container/yarn.lock ]; then PACKAGE_MANAGER="yarn"
  else PACKAGE_MANAGER="npm"; fi
fi
log "Package manager: ${BOLD}${PACKAGE_MANAGER}${RESET}"

case "${PACKAGE_MANAGER}" in
  pnpm) command -v pnpm &>/dev/null || npm install -g pnpm --quiet ;;
  yarn) command -v yarn &>/dev/null || npm install -g yarn --quiet ;;
esac

# ── Install Dependencies ──────────────────────────────────────────────────────
log "Installing dependencies..."
cd /home/container
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"

case "${PACKAGE_MANAGER}" in
  pnpm) pnpm install --frozen-lockfile 2>/dev/null || pnpm install ;;
  yarn) yarn install --frozen-lockfile 2>/dev/null || yarn install ;;
  *)    [ -f package-lock.json ] && npm ci || npm install ;;
esac
ok "Dependencies installed."

# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"
if [ -n "${CLOUDFLARE_TOKEN}" ]; then
  if ! command -v cloudflared &>/dev/null; then
    ARCH=$(uname -m); case "${ARCH}" in x86_64) CF_ARCH="amd64";; aarch64) CF_ARCH="arm64";; *) CF_ARCH="amd64";; esac
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared || warn "cloudflared download failed"
  fi
  command -v cloudflared &>/dev/null && { cloudflared tunnel --no-autoupdate run --token "${CLOUDFLARE_TOKEN}" & ok "Cloudflare Tunnel started."; }
fi

# ── Build & Start ─────────────────────────────────────────────────────────────
BUILD_COMMAND="${BUILD_COMMAND:-}"

if [ "${NODE_RUN_ENV}" = "production" ]; then
  log "Mode: ${BOLD}production${RESET} — building..."

  if [ -n "${BUILD_COMMAND}" ]; then
    eval "${BUILD_COMMAND}" || fail "Build failed"
  elif grep -q '"build"' package.json; then
    case "${PACKAGE_MANAGER}" in
      pnpm) pnpm run build || fail "Build failed" ;;
      yarn) yarn build     || fail "Build failed" ;;
      *)    npm run build  || fail "Build failed" ;;
    esac
  else
    fail "No build script in package.json. Add a 'build' script or set BUILD_COMMAND."
  fi
  ok "Build complete."

  log "Starting Next.js in production mode..."
  PORT=${SERVER_PORT:-3000} NODE_ENV=production \
    case "${PACKAGE_MANAGER}" in
      pnpm) pnpm run start ;;
      yarn) yarn start     ;;
      *)    npm run start  ;;
    esac

else
  log "Mode: ${BOLD}development${RESET} (hot-reload)"
  PORT=${SERVER_PORT:-3000} NODE_ENV=development \
    case "${PACKAGE_MANAGER}" in
      pnpm) pnpm run dev ;;
      yarn) yarn dev     ;;
      *)    npm run dev  ;;
    esac
fi
