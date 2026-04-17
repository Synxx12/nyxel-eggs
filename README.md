# 🥚 nyxel-eggs

> **Production-ready Pterodactyl & Pelican eggs** — curated and maintained by [nyxel](https://nyxel.my.id)

A unified collection of server eggs for self-hosting modern applications on [Pterodactyl Panel](https://pterodactyl.io) and [Pelican Panel](https://pelican.dev). Every egg is designed for real production workloads — not just demos.

---

## 📦 Available Eggs

### 🟢 Node.js Frameworks

Eggs for deploying modern Node.js/JavaScript server-side applications and full-stack frameworks.

| Egg                                         | Framework             | Status    | Import                                                                                                          |
| ------------------------------------------- | --------------------- | --------- | --------------------------------------------------------------------------------------------------------------- |
| [Next.js](./eggs/nodejs-frameworks/nextjs)  | React SSR/SSG         | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/nextjs/egg.json)  |
| [NestJS](./eggs/nodejs-frameworks/nestjs)   | Node.js API Framework | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/nestjs/egg.json)  |
| [Fastify](./eggs/nodejs-frameworks/fastify) | Fast Node.js Server   | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/fastify/egg.json) |
| [Bun.js](./eggs/nodejs-frameworks/bunjs)    | All-in-one JS Runtime | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/bunjs/egg.json)   |

### 🎵 Bots & Audio

Eggs for Discord bots, music bots, and audio streaming infrastructure.

| Egg                                    | Description                    | Status    | Import                                                                                                    |
| -------------------------------------- | ------------------------------ | --------- | --------------------------------------------------------------------------------------------------------- |
| [Lavalink](./eggs/bots-audio/lavalink) | Audio Streaming Node (Discord) | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/bots-audio/lavalink/egg.json) |

---

## ✨ Feature Matrix

### 🟢 Node.js Frameworks

| Feature                       | Next.js | NestJS | Fastify | Bun.js |
| ----------------------------- | ------- | ------ | ------- | ------ |
| Git clone / pull              | ✅      | ✅     | ✅      | ✅     |
| Auto-update on startup        | ✅      | ✅     | ✅      | ✅     |
| Private repo (PAT)            | ✅      | ✅     | ✅      | ✅     |
| `.env` injection              | ✅      | ✅     | ✅      | ✅     |
| Production mode               | ✅      | ✅     | ✅      | ✅     |
| Development / watch mode      | ✅      | ✅     | ✅      | ✅     |
| npm / pnpm / yarn auto-detect | ✅      | ✅     | ✅      | ✅     |
| Custom build command          | ✅      | ✅     | ✅      | ✅     |
| Cloudflare Tunnel             | ✅      | ✅     | ✅      | ✅     |
| Node.js 18/20/22/23/24        | ✅      | ✅     | ✅      | —      |
| Bun runtime                   | —       | —      | —       | ✅     |

### 🎵 Bots & Audio

| Feature                  | Lavalink |
| ------------------------ | -------- |
| Auto-download JAR        | ✅       |
| Custom `application.yml` | ✅       |
| Password protection      | ✅       |
| Version pinning          | ✅       |
| Java 17 / 21 support     | ✅       |
| Plugin support (via URL) | ✅       |
| Cloudflare Tunnel        | ✅       |

---

## 🚀 Quick Install

1. Go to your Pterodactyl/Pelican Admin Panel
2. Navigate to **Nests** → **Import Egg**
3. Paste the raw JSON URL **or** download and upload the `.json` file
4. Assign the egg to a nest, create a server, fill in variables

---

## 🐳 Supported Docker Images

**Node.js eggs** use [parkervcp/yolks](https://github.com/parkervcp/yolks):

```
ghcr.io/parkervcp/yolks:nodejs_24
ghcr.io/parkervcp/yolks:nodejs_22  ← Recommended
ghcr.io/parkervcp/yolks:nodejs_20
ghcr.io/parkervcp/yolks:nodejs_18
```

**Bun.js egg** uses:

```
ghcr.io/parkervcp/yolks:bun_1
```

**Lavalink egg** uses:

```
ghcr.io/parkervcp/yolks:java_21  ← Recommended
ghcr.io/parkervcp/yolks:java_17
```

---

## 📁 Repository Structure

```
nyxel-eggs/
├── eggs/
│   │
│   ├── nodejs-frameworks/         ← Node.js & JS runtimes
│   │   ├── nextjs/
│   │   │   ├── egg.json
│   │   │   ├── entrypoint.sh
│   │   │   └── README.md
│   │   ├── nestjs/
│   │   │   ├── egg.json
│   │   │   ├── entrypoint.sh
│   │   │   └── README.md
│   │   ├── fastify/
│   │   │   ├── egg.json
│   │   │   ├── entrypoint.sh
│   │   │   └── README.md
│   │   └── bunjs/
│   │       ├── egg.json
│   │       ├── entrypoint.sh
│   │       └── README.md
│   │
│   └── bots-audio/                ← Discord bots & audio nodes
│       └── lavalink/
│           ├── egg.json
│           ├── entrypoint.sh
│           └── README.md
│
├── .github/
│   └── workflows/
│       └── validate.yml
├── CONTRIBUTING.md
└── README.md
```

---

## 🔒 Security

- Git credentials are **injected at runtime** and never logged or stored on disk
- `.env.pterodactyl` is copied to `.env` at startup — secrets stay in the panel, not in your repo
- Cloudflare Tunnel tokens are handled in memory only
- Lavalink passwords are passed via environment variable, never hardcoded

---

## 🗺 Roadmap

| Category               | Planned                 |
| ---------------------- | ----------------------- |
| **Node.js Frameworks** | Express.js              |
| **Bots & Audio**       | Discord.js Bot template |
| **Backend Runtimes**   | Go (Fiber / Echo), Deno |
| **Python**             | FastAPI, Django         |
| **Static / Proxy**     | Nginx, Caddy            |
| **PHP**                | Laravel                 |

---

## 📝 License

MIT — free to use, modify, and redistribute.

---

Made with ☕ by **nyxel** — [nyxel.my.id](https://nyxel.my.id)
