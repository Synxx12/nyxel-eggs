#!/bin/bash
# ============================================================
#   nyxel-eggs — Next.js entrypoint (production-grade)
#   https://nyxel.my.id
#   Version: 2.0.0
# ============================================================

set -o pipefail

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
echo "  ███╗   ██╗██╗   ██╗██╗  ██╗███████╗██╗"
echo "  ████╗  ██║╚██╗ ██╔╝╚██╗██╔╝██╔════╝██║"
echo "  ██╔██╗ ██║ ╚████╔╝  ╚███╔╝ █████╗  ██║"
echo "  ██║╚██╗██║  ╚██╔╝   ██╔██╗ ██╔══╝  ██║"
echo "  ██║ ╚████║   ██║   ██╔╝ ██╗███████╗███████╗"
echo "  ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
echo ""
echo "  🥚 nyxel-eggs — Next.js   |   nyxel.my.id"
# ── Environment ───────────────────────────────────────────
GIT_URL="${GIT_URL:-}"
GIT_BRANCH="${GIT_BRANCH:-main}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
USERNAME="${USERNAME:-}"
ACCESS_TOKEN="${ACCESS_TOKEN:-}"
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"
PACKAGE_MANAGER="${PACKAGE_MANAGER:-auto}"
BUILD_COMMAND="${BUILD_COMMAND:-}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

# ── Set NODE_ENV ───────────────────────────────────────────
if [ "$NODE_RUN_ENV" = "production" ]; then
  export NODE_ENV=production
else
  export NODE_ENV=development
fi

# ── Disk Space Check and Auto-Cleanup ────────────────────────
clean_disk_if_low() {
  local needs_cleanup=0

  # Test 1: Write test (Check if disk is completely full)
  if ! touch /home/container/.disk_write_test 2>/dev/null; then
    echo "[WARN] Disk is completely full or read-only! Emergency cleanup required."
    needs_cleanup=1
  else
    rm -f /home/container/.disk_write_test
  fi

  # Test 2: Percentage check (Clean if usage > 90%)
  if [ "$needs_cleanup" -eq 0 ] && command -v df &>/dev/null; then
    local usage
    usage=$(df -P /home/container 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')
    if [ -n "$usage" ] && [ "$usage" -gt 90 ]; then
      echo "[WARN] Disk usage is very high (${usage}%). Preemptive cleanup initiated."
      needs_cleanup=1
    fi
  fi

  if [ "$needs_cleanup" -eq 1 ]; then
    echo "[DISK] Starting cleanup of caches and temporary files..."

    # 1. Clear Next.js cache (largest build cache)
    if [ -d /home/container/.next/cache ]; then
      echo "[DISK] Removing Next.js cache (.next/cache)..."
      rm -rf /home/container/.next/cache
    fi

    # 2. Clear package manager stores/caches
    if command -v pnpm &>/dev/null; then
      echo "[DISK] Pruning pnpm store..."
      pnpm store prune 2>/dev/null || true
    fi
    if command -v npm &>/dev/null; then
      echo "[DISK] Cleaning npm cache..."
      npm cache clean --force 2>/dev/null || true
    fi
    if command -v yarn &>/dev/null; then
      echo "[DISK] Cleaning yarn cache..."
      yarn cache clean 2>/dev/null || true
    fi

    # 3. Clear temporary files
    echo "[DISK] Cleaning /tmp..."
    rm -rf /tmp/* 2>/dev/null || true

    # 4. Truncate cloudflared log
    if [ -f /home/container/.pterodactyl/cloudflared.log ]; then
      echo "[DISK] Truncating cloudflared.log..."
      echo -n "" > /home/container/.pterodactyl/cloudflared.log
    fi

    echo "[DISK] Cleanup finished."
    if command -v df &>/dev/null; then
      df -h /home/container 2>/dev/null || true
    fi
  fi
}

echo "[INFO] Node version: $(node --version)"
echo "[INFO] Environment: $NODE_RUN_ENV (NODE_ENV=$NODE_ENV)"

cd /home/container
clean_disk_if_low

# ── Git credentials ────────────────────────────────────────
CLONE_URL="$GIT_URL"
if [ -n "$GIT_URL" ] && [ -n "$USERNAME" ] && [ -n "$ACCESS_TOKEN" ]; then
  CLONE_URL="https://${USERNAME}:${ACCESS_TOKEN}@$(echo "$GIT_URL" | sed 's|https://||')"
fi

# ── Clone or update repo ──────────────────────────────────
if [ -n "$GIT_URL" ]; then
  if [ -d /home/container/.git ]; then
    if [ "$AUTO_UPDATE" = "1" ]; then
      echo "[GIT] Auto-updating repository..."
      git config remote.origin.url "$CLONE_URL" 2>/dev/null || true
      if git fetch origin; then
        git reset --hard "origin/${GIT_BRANCH}" 2>/dev/null || git reset --hard || echo "[WARN] Git reset failed."
        echo "[GIT] Updated to latest."
      else
        echo "[WARN] Git fetch failed. Proceeding with existing local files."
      fi
    else
      echo "[GIT] AUTO_UPDATE=0 — skipping pull."
    fi
  else
    echo "[GIT] Cloning repository..."
    find /home/container -mindepth 1 \
      -not -path '/home/container/.pterodactyl*' \
      -delete 2>/dev/null || true

    CLONE_SUCCESS=0
    if [ -z "$GIT_BRANCH" ]; then
      git clone --depth 1 "$CLONE_URL" /tmp/repo_clone && CLONE_SUCCESS=1 || true
    else
      git clone --depth 1 --single-branch --branch "$GIT_BRANCH" "$CLONE_URL" /tmp/repo_clone && CLONE_SUCCESS=1 || true
    fi

    if [ "$CLONE_SUCCESS" = "1" ]; then
      cp -a /tmp/repo_clone/. /home/container/ 2>/dev/null || echo "[WARN] Failed to copy some files."
      rm -rf /tmp/repo_clone
      echo "[GIT] Clone complete."
    else
      echo "[ERROR] Git clone failed. Cannot proceed with fresh installation."
      exit 1
    fi
  fi
else
  echo "[GIT] No GIT_URL set — using existing files."
fi

# ── .env injection ─────────────────────────────────────────
if [ -f /home/container/.env.pterodactyl ]; then
  echo "[ENV] Injecting .env.pterodactyl → .env"
  cp /home/container/.env.pterodactyl /home/container/.env || echo "[WARN] Failed to inject environment variables."
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
  pnpm) command -v pnpm &>/dev/null || npm install -g pnpm --quiet || echo "[WARN] Failed to install pnpm globally." ;;
  yarn) command -v yarn &>/dev/null || npm install -g yarn --quiet || echo "[WARN] Failed to install yarn globally." ;;
esac

# ── Install dependencies ──────────────────────────────────
if [ -f /home/container/package.json ]; then
  echo "[DEPS] Installing dependencies..."
  cd /home/container
  INSTALL_SUCCESS=0
  case "$PM" in
    pnpm)
      pnpm install --frozen-lockfile 2>/dev/null && INSTALL_SUCCESS=1 || {
        echo "[WARN] Lockfile mismatch or pnpm install failed — trying clean install..."
        pnpm install && INSTALL_SUCCESS=1 || echo "[WARN] pnpm install failed."
      }
      ;;
    yarn)
      yarn install --frozen-lockfile 2>/dev/null && INSTALL_SUCCESS=1 || {
        echo "[WARN] Lockfile mismatch or yarn install failed — trying clean install..."
        yarn install && INSTALL_SUCCESS=1 || echo "[WARN] yarn install failed."
      }
      ;;
    *)
      if [ -f package-lock.json ]; then
        npm ci && INSTALL_SUCCESS=1 || {
          echo "[WARN] npm ci failed — trying npm install..."
          npm install && INSTALL_SUCCESS=1 || echo "[WARN] npm install failed."
        }
      else
        npm install && INSTALL_SUCCESS=1 || echo "[WARN] npm install failed."
      fi
      ;;
  esac

  if [ "$INSTALL_SUCCESS" = "1" ]; then
    echo "[DEPS] Done."
  else
    echo "[WARN] Dependency installation failed. Attempting to proceed with existing node_modules..."
  fi
else
  echo "[DEPS] No package.json found — skipping install."
fi

# ── Prisma auto-generate ──────────────────────────────────
if [ -f /home/container/prisma/schema.prisma ]; then
  echo "[PRISMA] Generating Prisma client..."
  npx prisma generate 2>/dev/null || echo "[WARN] Prisma generate failed — continuing."
fi

# ── Cloudflare Tunnel ─────────────────────────────────────
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "[CF] Starting Cloudflare Tunnel..."
  CF_BIN="/home/container/.pterodactyl/cloudflared"
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

# ── Build & Start ─────────────────────────────────────────
export PORT="${SERVER_PORT:-3000}"
export HOSTNAME="0.0.0.0"

echo "[INFO] Port: $PORT"
echo ""

if [ "$NODE_RUN_ENV" = "development" ]; then
  echo "[START] Starting Next.js in development mode..."
  exec npx next dev --port "$PORT"
else
  echo "[BUILD] Building Next.js application..."
  BUILD_SUCCESS=0
  if [ -n "$BUILD_COMMAND" ]; then
    eval "$BUILD_COMMAND" && BUILD_SUCCESS=1 || echo "[WARN] Custom build command failed."
  else
    npx next build && BUILD_SUCCESS=1 || echo "[WARN] Next.js build failed."
  fi

  if [ "$BUILD_SUCCESS" = "1" ]; then
    echo "[START] Starting Next.js in production mode..."
    exec npx next start --port "$PORT"
  else
    if [ -d /home/container/.next ]; then
      echo "[WARN] Build failed, but an existing .next folder was found. Attempting to start server with the last successful build..."
      exec npx next start --port "$PORT"
    else
      echo "[ERROR] Build failed and no existing .next folder found. Cannot start Next.js."
      exit 1
    fi
  fi
fi