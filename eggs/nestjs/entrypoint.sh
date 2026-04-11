#!/bin/bash
# ============================================================
#   nyxel-eggs — NestJS entrypoint
#   https://nyxel.my.id
# ============================================================

echo ""
echo "  ███╗   ██╗██╗   ██╗██╗  ██╗███████╗██╗"
echo "  ████╗  ██║╚██╗ ██╔╝╚██╗██╔╝██╔════╝██║"
echo "  ██╔██╗ ██║ ╚████╔╝  ╚███╔╝ █████╗  ██║"
echo "  ██║╚██╗██║  ╚██╔╝   ██╔██╗ ██╔══╝  ██║"
echo "  ██║ ╚████║   ██║   ██╔╝ ██╗███████╗███████╗"
echo "  ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
echo ""
echo "  🥚 nyxel-eggs — NestJS   |   nyxel.my.id"
echo "  ──────────────────────────────────────────"
echo ""

# ── Environment ───────────────────────────────────────────
GIT_URL="${GIT_URL:-}"
GIT_BRANCH="${GIT_BRANCH:-main}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
USERNAME="${USERNAME:-}"
ACCESS_TOKEN="${ACCESS_TOKEN:-}"
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-auto}"
BUILD_COMMAND="${BUILD_COMMAND:-}"
START_COMMAND="${START_COMMAND:-}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

cd /home/container

# ── Git credentials ────────────────────────────────────────
CLONE_URL="$GIT_URL"
if [ -n "$GIT_URL" ] && [ -n "$USERNAME" ] && [ -n "$ACCESS_TOKEN" ]; then
  CLONE_URL="https://${USERNAME}:${ACCESS_TOKEN}@$(echo "$GIT_URL" | sed 's|https://||')"
fi

# ── Clone or update repo ───────────────────────────────────
if [ -n "$GIT_URL" ]; then
  if [ -d /home/container/.git ]; then
    if [ "$AUTO_UPDATE" = "1" ]; then
      echo "[GIT] Auto-updating repository..."
      git config remote.origin.url "$CLONE_URL" 2>/dev/null || true
      git fetch origin
      git reset --hard "origin/${GIT_BRANCH}" 2>/dev/null || git reset --hard
      echo "[GIT] Updated to latest."
    else
      echo "[GIT] AUTO_UPDATE=0 — skipping pull."
    fi
  else
    echo "[GIT] Cloning repository..."
    find /home/container -mindepth 1 \
      -not -path '/home/container/.pterodactyl*' \
      -delete 2>/dev/null || true

    if [ -z "$GIT_BRANCH" ]; then
      git clone "$CLONE_URL" /tmp/repo_clone
    else
      git clone --single-branch --branch "$GIT_BRANCH" "$CLONE_URL" /tmp/repo_clone
    fi
    cp -a /tmp/repo_clone/. /home/container/
    rm -rf /tmp/repo_clone
    echo "[GIT] Clone complete."
  fi
fi

# ── .env injection ─────────────────────────────────────────
if [ -f /home/container/.env.pterodactyl ]; then
  echo "[ENV] Copying .env.pterodactyl → .env"
  cp /home/container/.env.pterodactyl /home/container/.env
fi

# ── Detect package manager ─────────────────────────────────
PM="$PACKAGE_MANAGER"
if [ "$PM" = "auto" ]; then
  if [ -f /home/container/pnpm-lock.yaml ]; then PM="pnpm";
  elif [ -f /home/container/yarn.lock ]; then PM="yarn";
  else PM="npm"; fi
fi
echo "[PKG] Using package manager: $PM"

# ── Install package manager if needed ─────────────────────
case "$PM" in
  pnpm) command -v pnpm &>/dev/null || npm install -g pnpm --quiet ;;
  yarn) command -v yarn &>/dev/null || npm install -g yarn --quiet ;;
esac

# ── Install dependencies ───────────────────────────────────
echo "[DEPS] Installing dependencies..."
cd /home/container
case "$PM" in
  pnpm) pnpm install --frozen-lockfile 2>/dev/null || pnpm install ;;
  yarn) yarn install --frozen-lockfile 2>/dev/null || yarn install ;;
  *)    [ -f package-lock.json ] && npm ci || npm install ;;
esac
echo "[DEPS] Done."

# ── Cloudflare Tunnel ──────────────────────────────────────
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "[CF] Starting Cloudflare Tunnel..."
  if ! command -v cloudflared &>/dev/null; then
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
      -o /usr/local/bin/cloudflared
    chmod +x /usr/local/bin/cloudflared
  fi
  cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TOKEN" &
fi

# ── Build & Start ──────────────────────────────────────────
export PORT="${SERVER_PORT:-3000}"

if [ "$NODE_RUN_ENV" = "development" ]; then
  echo "[START] Starting NestJS in development mode (hot-reload)..."
  exec npx nest start --watch
else
  echo "[BUILD] Building NestJS application..."
  if [ -n "$BUILD_COMMAND" ]; then
    eval "$BUILD_COMMAND"
  else
    npx nest build
  fi

  echo "[START] Starting NestJS in production mode..."
  if [ -n "$START_COMMAND" ]; then
    eval "$START_COMMAND"
  elif [ -f dist/main.js ]; then
    exec node dist/main.js
  else
    exec npm run start:prod
  fi
fi