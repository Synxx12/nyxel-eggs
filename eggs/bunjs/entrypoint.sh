#!/bin/bash
# ============================================================
#   nyxel-eggs — Bun.js entrypoint
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
echo "  🥚 nyxel-eggs — Bun.js   |   nyxel.my.id"
echo "  ──────────────────────────────────────────"
echo ""

# ── Environment ───────────────────────────────────────────
GIT_URL="${GIT_URL:-}"
GIT_BRANCH="${GIT_BRANCH:-main}"
AUTO_UPDATE="${AUTO_UPDATE:-1}"
USERNAME="${USERNAME:-}"
ACCESS_TOKEN="${ACCESS_TOKEN:-}"
NODE_RUN_ENV="${NODE_RUN_ENV:-production}"
ENTRY_POINT="${ENTRY_POINT:-}"
BUILD_COMMAND="${BUILD_COMMAND:-}"
CLOUDFLARE_TOKEN="${CLOUDFLARE_TOKEN:-}"

# ── Ensure Bun is on PATH ──────────────────────────────────
export PATH="$HOME/.bun/bin:/root/.bun/bin:$PATH"

if ! command -v bun &>/dev/null; then
  echo "[BUN] Bun not found — installing..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
fi

echo "[BUN] Bun version: $(bun --version)"

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

# ── Install dependencies ───────────────────────────────────
echo "[DEPS] Installing dependencies with Bun..."
cd /home/container
bun install
echo "[DEPS] Done."

# ── Cloudflare Tunnel ──────────────────────────────────────
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "[CF] Starting Cloudflare Tunnel..."
  CF_BIN="/home/container/.pterodactyl/cloudflared"
  if [ ! -x "$CF_BIN" ]; then
    echo "[CF] Downloading cloudflared..."
    curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
      -o "$CF_BIN" && chmod +x "$CF_BIN" || { echo "[CF] Failed to download cloudflared!"; CF_BIN=""; }
  fi
  if [ -n "$CF_BIN" ]; then
    "$CF_BIN" tunnel --no-autoupdate run --token "$CLOUDFLARE_TOKEN" &
  fi
fi

# ── Detect entry point ─────────────────────────────────────
if [ -z "$ENTRY_POINT" ]; then
  if [ -f /home/container/package.json ]; then
    ENTRY_POINT=$(grep -m1 '"main"' /home/container/package.json | sed 's/.*"main"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)
  fi
  # Fallback: cek file umum jika main tidak ditemukan
  if [ -z "$ENTRY_POINT" ]; then
    for f in index.ts src/index.ts index.js src/index.js server.ts server.js app.ts app.js; do
      [ -f "/home/container/$f" ] && ENTRY_POINT="$f" && break
    done
  fi
  [ -z "$ENTRY_POINT" ] && ENTRY_POINT="src/index.ts"
fi

export PORT="${SERVER_PORT:-3000}"

# ── Build & Start ──────────────────────────────────────────
if [ "$NODE_RUN_ENV" = "development" ]; then
  echo "[START] Starting Bun.js in development mode (--watch)..."
  exec bun --watch "$ENTRY_POINT"
else
  if [ -n "$BUILD_COMMAND" ]; then
    echo "[BUILD] Running build: $BUILD_COMMAND"
    eval "$BUILD_COMMAND"
  fi
  echo "[START] Starting Bun.js in production mode..."
  exec bun run "$ENTRY_POINT"
fi