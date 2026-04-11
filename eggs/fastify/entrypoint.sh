#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         Fastify Pterodactyl Entrypoint — nyxel              ║
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
echo "  ███████╗ █████╗ ███████╗████████╗██╗███████╗██╗   ██╗"
echo "  ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝╚██╗ ██╔╝"
echo "  █████╗  ███████║███████╗   ██║   ██║█████╗   ╚████╔╝ "
echo "  ██╔══╝  ██╔══██║╚════██║   ██║   ██║██╔══╝    ╚██╔╝  "
echo "  ██║     ██║  ██║███████║   ██║   ██║██║        ██║   "
echo "  ╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝╚═╝        ╚═╝   "
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
      log "Auto-update — pulling latest..."
      git -C /home/container remote set-url origin "${AUTHENTICATED_URL}" 2>/dev/null || true
      git -C /home/container reset --hard
      git -C /home/container pull origin "${GIT_BRANCH:-$(git -C /home/container symbolic-ref --short HEAD 2>/dev/null || echo main)}" || warn "git pull failed"
      ok "Repository updated."
    fi
  else
    log "Cloning repository..."
    if [ -n "${GIT_BRANCH}" ]; then
      git clone --single-branch --branch "${GIT_BRANCH}" "${AUTHENTICATED_URL}" /tmp/fastify_clone || fail "git clone failed"
    else
      git clone "${AUTHENTICATED_URL}" /tmp/fastify_clone || fail "git clone failed"
    fi
    find /home/container -mindepth 1 -not -path '/home/container/.pterodactyl*' -delete 2>/dev/null || true
    cp -a /tmp/fastify_clone/. /home/container/
    rm -rf /tmp/fastify_clone
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
  [ -f /home/container/pnpm-lock.yaml ] && PACKAGE_MANAGER="pnpm" \
    || { [ -f /home/container/yarn.lock ] && PACKAGE_MANAGER="yarn" || PACKAGE_MANAGER="npm"; }
fi
log "Package manager: ${BOLD}${PACKAGE_MANAGER}${RESET}"
case "${PACKAGE_MANAGER}" in
  pnpm) command -v pnpm &>/dev/null || npm install -g pnpm --quiet ;;
  yarn) command -v yarn &>/dev/null || npm install -g yarn --quiet ;;
esac

# ── Install ───────────────────────────────────────────────────────────────────
log "Installing dependencies..."
cd /home/container
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

# ── Build (TypeScript projects) ───────────────────────────────────────────────
BUILD_COMMAND="${BUILD_COMMAND:-}"
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"

if [ -n "${BUILD_COMMAND}" ]; then
  log "Running build: ${BUILD_COMMAND}"
  eval "${BUILD_COMMAND}" || fail "Build failed"
  ok "Build complete."
elif [ "${NODE_RUN_ENV}" = "production" ] && grep -q '"build"' package.json; then
  log "Running build script..."
  case "${PACKAGE_MANAGER}" in
    pnpm) pnpm run build || fail "Build failed" ;;
    yarn) yarn build     || fail "Build failed" ;;
    *)    npm run build  || fail "Build failed" ;;
  esac
  ok "Build complete."
fi

# ── Start ─────────────────────────────────────────────────────────────────────
ENTRY_POINT="${ENTRY_POINT:-}"

if [ "${NODE_RUN_ENV}" = "production" ]; then
  log "Mode: ${BOLD}production${RESET}"

  # Resolve entry point
  if [ -n "${ENTRY_POINT}" ]; then
    ok "Entry point: ${ENTRY_POINT}"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production node "${ENTRY_POINT}"

  elif grep -q '"start"' package.json; then
    ok "Using npm script: start"
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=production pnpm run start ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=production yarn start     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=production npm run start  ;;
    esac

  else
    # Auto-detect main field from package.json
    MAIN_FILE=$(node -e "try{const p=require('./package.json');console.log(p.main||'')}catch(e){}" 2>/dev/null || true)
    if [ -n "${MAIN_FILE}" ] && [ -f "${MAIN_FILE}" ]; then
      ok "Entry point (package.json main): ${MAIN_FILE}"
      PORT=${SERVER_PORT:-3000} NODE_ENV=production node "${MAIN_FILE}"
    else
      # Common fallbacks
      for f in src/index.js index.js dist/index.js dist/server.js server.js app.js; do
        if [ -f "${f}" ]; then
          ok "Entry point (auto-detected): ${f}"
          PORT=${SERVER_PORT:-3000} NODE_ENV=production node "${f}"
          exit 0
        fi
      done
      fail "Cannot find entry point. Set ENTRY_POINT or add a 'start' script to package.json."
    fi
  fi

else
  log "Mode: ${BOLD}development${RESET} (watch)"

  if grep -q '"dev"' package.json; then
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=development pnpm run dev ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=development yarn dev     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=development npm run dev  ;;
    esac
  elif grep -q '"start:dev"' package.json; then
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=development pnpm run start:dev ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=development yarn start:dev     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=development npm run start:dev  ;;
    esac
  else
    warn "No dev/start:dev script found — trying nodemon..."
    if command -v nodemon &>/dev/null || npx nodemon --version &>/dev/null 2>&1; then
      MAIN_FILE=$(node -e "try{const p=require('./package.json');console.log(p.main||'index.js')}catch(e){console.log('index.js')}" 2>/dev/null || echo "index.js")
      PORT=${SERVER_PORT:-3000} NODE_ENV=development npx nodemon "${MAIN_FILE}"
    else
      fail "No dev start method found. Add a 'dev' script to package.json."
    fi
  fi
fi
