#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         NestJS Pterodactyl Entrypoint — nyxel               ║
# ║         https://nyxel.my.id                                  ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[EGG]${RESET} $*"; }
ok()   { echo -e "${GREEN}[EGG] ✓${RESET} $*"; }
warn() { echo -e "${YELLOW}[EGG] ⚠${RESET} $*"; }
fail() { echo -e "${RED}[EGG] ✗${RESET} $*"; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
echo "  ███╗   ██╗███████╗███████╗████████╗     ██╗███████╗"
echo "  ████╗  ██║██╔════╝██╔════╝╚══██╔══╝     ██║██╔════╝"
echo "  ██╔██╗ ██║█████╗  ███████╗   ██║        ██║███████╗"
echo "  ██║╚██╗██║██╔══╝  ╚════██║   ██║   ██   ██║╚════██║"
echo "  ██║ ╚████║███████╗███████║   ██║   ╚█████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚══════╝╚══════╝   ╚═╝    ╚════╝ ╚══════╝"
echo -e "${RESET}${CYAN}  Pterodactyl Egg by nyxel — https://nyxel.my.id${RESET}"
echo ""

# ── Validate working directory ────────────────────────────────────────────────
cd /home/container || fail "Cannot cd into /home/container"

# ── Git Operations ────────────────────────────────────────────────────────────
GIT_URL="${GIT_URL:-}"
GIT_BRANCH="${GIT_BRANCH:-}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
USERNAME="${USERNAME:-}"
ACCESS_TOKEN="${ACCESS_TOKEN:-}"

if [ -n "${GIT_URL}" ]; then
  # Inject credentials if provided (never expose in logs)
  AUTHENTICATED_URL="${GIT_URL}"
  if [ -n "${USERNAME}" ] && [ -n "${ACCESS_TOKEN}" ]; then
    AUTHENTICATED_URL="https://${USERNAME}:${ACCESS_TOKEN}@$(echo "${GIT_URL}" | sed 's|https://||')"
  fi

  if [ -d /home/container/.git ]; then
    if [ "${AUTO_UPDATE}" = "1" ]; then
      log "Auto-update enabled — pulling latest commits..."
      git -C /home/container remote set-url origin "${AUTHENTICATED_URL}" 2>/dev/null || true
      git -C /home/container reset --hard
      git -C /home/container pull origin "${GIT_BRANCH:-$(git -C /home/container symbolic-ref --short HEAD 2>/dev/null || echo main)}" || warn "git pull failed — continuing with existing code"
      ok "Repository updated."
    else
      log "Auto-update disabled — using existing code."
    fi
  else
    log "Cloning repository..."
    CLONE_ARGS=("${AUTHENTICATED_URL}" /tmp/nestjs_clone)
    if [ -n "${GIT_BRANCH}" ]; then
      git clone --single-branch --branch "${GIT_BRANCH}" "${CLONE_ARGS[@]}" || fail "git clone failed"
    else
      git clone "${CLONE_ARGS[@]}" || fail "git clone failed"
    fi
    find /home/container -mindepth 1 \
      -not -path '/home/container/.pterodactyl*' \
      -delete 2>/dev/null || true
    cp -a /tmp/nestjs_clone/. /home/container/
    rm -rf /tmp/nestjs_clone
    ok "Repository cloned."
  fi
else
  log "GIT_URL not set — using files already in /home/container"
fi

# ── .env Injection ────────────────────────────────────────────────────────────
if [ -f /home/container/.env.pterodactyl ]; then
  cp -f /home/container/.env.pterodactyl /home/container/.env
  ok ".env.pterodactyl → .env (injected)"
elif [ ! -f /home/container/.env ]; then
  warn "No .env file found. Upload .env.pterodactyl via File Manager if your app requires env vars."
fi

# ── Validate package.json ─────────────────────────────────────────────────────
if [ ! -f /home/container/package.json ]; then
  fail "No package.json found. Is this a valid NestJS project?"
fi

# ── Detect Package Manager ────────────────────────────────────────────────────
PACKAGE_MANAGER="${PACKAGE_MANAGER:-auto}"

if [ "${PACKAGE_MANAGER}" = "auto" ]; then
  if [ -f /home/container/pnpm-lock.yaml ]; then
    PACKAGE_MANAGER="pnpm"
  elif [ -f /home/container/yarn.lock ]; then
    PACKAGE_MANAGER="yarn"
  else
    PACKAGE_MANAGER="npm"
  fi
fi

log "Package manager: ${BOLD}${PACKAGE_MANAGER}${RESET}"

# Ensure package manager is installed
case "${PACKAGE_MANAGER}" in
  pnpm)
    if ! command -v pnpm &>/dev/null; then
      log "Installing pnpm..."
      npm install -g pnpm --quiet || fail "Failed to install pnpm"
    fi
    ;;
  yarn)
    if ! command -v yarn &>/dev/null; then
      log "Installing yarn..."
      npm install -g yarn --quiet || fail "Failed to install yarn"
    fi
    ;;
esac

# ── Install @nestjs/cli globally if not present ───────────────────────────────
if ! command -v nest &>/dev/null; then
  log "Installing @nestjs/cli globally..."
  npm install -g @nestjs/cli --quiet || warn "Could not install @nestjs/cli globally — build may fall back to npm scripts"
fi

# ── Install Dependencies ──────────────────────────────────────────────────────
log "Installing dependencies..."
cd /home/container

NODE_RUN_ENV="${NODE_RUN_ENV:-production}"

case "${PACKAGE_MANAGER}" in
  pnpm)
    if [ "${NODE_RUN_ENV}" = "production" ]; then
      pnpm install --frozen-lockfile 2>/dev/null || pnpm install
    else
      pnpm install
    fi
    ;;
  yarn)
    if [ "${NODE_RUN_ENV}" = "production" ]; then
      yarn install --frozen-lockfile 2>/dev/null || yarn install
    else
      yarn install
    fi
    ;;
  *)
    if [ "${NODE_RUN_ENV}" = "production" ]; then
      if [ -f package-lock.json ]; then
        npm ci
      else
        npm install
      fi
    else
      npm install
    fi
    ;;
esac

ok "Dependencies installed."

# ── Cloudflare Tunnel ─────────────────────────────────────────────────────────
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

if [ -n "${CLOUDFLARE_TOKEN}" ]; then
  log "Starting Cloudflare Tunnel..."
  if ! command -v cloudflared &>/dev/null; then
    log "Downloading cloudflared..."
    ARCH=$(uname -m)
    case "${ARCH}" in
      x86_64)  CF_ARCH="amd64" ;;
      aarch64) CF_ARCH="arm64" ;;
      armv7l)  CF_ARCH="arm"   ;;
      *)       CF_ARCH="amd64" ;;
    esac
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" \
      -o /usr/local/bin/cloudflared || warn "Failed to download cloudflared — tunnel will not start"
    chmod +x /usr/local/bin/cloudflared 2>/dev/null || true
  fi

  if command -v cloudflared &>/dev/null; then
    cloudflared tunnel --no-autoupdate run --token "${CLOUDFLARE_TOKEN}" &
    CF_PID=$!
    ok "Cloudflare Tunnel started (PID: ${CF_PID})"
  fi
fi

# ── Build & Start ─────────────────────────────────────────────────────────────
BUILD_COMMAND="${BUILD_COMMAND:-}"
START_COMMAND="${START_COMMAND:-}"

if [ "${NODE_RUN_ENV}" = "production" ]; then
  # ── Production: build then start ────────────────────────────────────────────
  log "Mode: ${BOLD}production${RESET}"
  log "Building NestJS application..."

  if [ -n "${BUILD_COMMAND}" ]; then
    log "Using custom build command: ${BUILD_COMMAND}"
    eval "${BUILD_COMMAND}" || fail "Build failed"
  else
    # Try nest build, fall back to npm/pnpm/yarn build script
    if command -v nest &>/dev/null && [ -f nest-cli.json ]; then
      nest build || fail "nest build failed"
    elif grep -q '"build"' package.json; then
      case "${PACKAGE_MANAGER}" in
        pnpm) pnpm run build || fail "pnpm run build failed" ;;
        yarn) yarn build     || fail "yarn build failed"     ;;
        *)    npm run build  || fail "npm run build failed"  ;;
      esac
    else
      fail "No build command found. Provide a BUILD_COMMAND or add a 'build' script to package.json."
    fi
  fi

  ok "Build complete."

  log "Starting NestJS in production mode..."

  if [ -n "${START_COMMAND}" ]; then
    log "Using custom start command: ${START_COMMAND}"
    eval "PORT=${SERVER_PORT:-3000} NODE_ENV=production ${START_COMMAND}"

  elif [ -f dist/main.js ]; then
    ok "Entry point: dist/main.js"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production node dist/main.js

  elif [ -f dist/src/main.js ]; then
    ok "Entry point: dist/src/main.js"
    PORT=${SERVER_PORT:-3000} NODE_ENV=production node dist/src/main.js

  elif grep -q '"start:prod"' package.json; then
    ok "Using npm script: start:prod"
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=production pnpm run start:prod ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=production yarn start:prod     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=production npm run start:prod  ;;
    esac

  elif grep -q '"start"' package.json; then
    warn "start:prod not found — falling back to npm run start"
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=production pnpm run start ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=production yarn start     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=production npm run start  ;;
    esac

  else
    fail "Cannot find a way to start the application. Ensure dist/main.js exists or add a 'start:prod' script."
  fi

else
  # ── Development: hot-reload ──────────────────────────────────────────────────
  log "Mode: ${BOLD}development${RESET} (hot-reload)"

  if command -v nest &>/dev/null && [ -f nest-cli.json ]; then
    ok "Starting with: nest start --watch"
    PORT=${SERVER_PORT:-3000} NODE_ENV=development nest start --watch

  elif grep -q '"start:dev"' package.json; then
    ok "Using npm script: start:dev"
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=development pnpm run start:dev ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=development yarn start:dev     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=development npm run start:dev  ;;
    esac

  elif grep -q '"dev"' package.json; then
    ok "Using npm script: dev"
    case "${PACKAGE_MANAGER}" in
      pnpm) PORT=${SERVER_PORT:-3000} NODE_ENV=development pnpm run dev ;;
      yarn) PORT=${SERVER_PORT:-3000} NODE_ENV=development yarn dev     ;;
      *)    PORT=${SERVER_PORT:-3000} NODE_ENV=development npm run dev  ;;
    esac

  else
    warn "No dev script found — falling back to: node dist/main.js"
    PORT=${SERVER_PORT:-3000} NODE_ENV=development node dist/main.js
  fi
fi
