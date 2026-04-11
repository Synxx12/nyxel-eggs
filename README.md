# 🥚 nyxel-eggs

> **Production-ready Pterodactyl & Pelican eggs** — curated and maintained by [nyxel](https://nyxel.my.id)

A unified collection of server eggs for self-hosting modern Node.js frameworks on [Pterodactyl Panel](https://pterodactyl.io) and [Pelican Panel](https://pelican.dev). Every egg is designed for real production workloads — not just demos.

---

## 📦 Available Eggs

| Egg                        | Framework             | Status    | Import                                                                                        |
| -------------------------- | --------------------- | --------- | --------------------------------------------------------------------------------------------- |
| [Next.js](./eggs/nextjs/)  | React SSR/SSG         | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nextjs/egg.json)  |
| [NestJS](./eggs/nestjs/)   | Node.js API Framework | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nestjs/egg.json)  |
| [Fastify](./eggs/fastify/) | Fast Node.js Server   | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/fastify/egg.json) |
| [Bun.js](./eggs/bunjs/)    | All-in-one JS Runtime | ✅ Stable | [⬇ Download](https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/bunjs/egg.json)   |

---

## ✨ Feature Matrix

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

---

## 🚀 Quick Install

1. Go to your Pterodactyl/Pelican Admin Panel
2. Navigate to **Nests** → **Import Egg**
3. Paste the raw JSON URL **or** download and upload the `.json` file
4. Assign the egg to a nest, create a server, fill in variables

---

## 🐳 Supported Docker Images

All Node.js eggs use [parkervcp/yolks](https://github.com/parkervcp/yolks):

```
ghcr.io/parkervcp/yolks:nodejs_24
ghcr.io/parkervcp/yolks:nodejs_22  ← Recommended
ghcr.io/parkervcp/yolks:nodejs_20
ghcr.io/parkervcp/yolks:nodejs_18
```

Bun.js egg uses:

```
ghcr.io/parkervcp/yolks:bun_1
```

---

## 📁 Repository Structure

```
nyxel-eggs/
├── eggs/
│   ├── nextjs/
│   │   ├── egg.json          ← Pterodactyl import file
│   │   ├── entrypoint.sh     ← Runtime startup script
│   │   └── README.md         ← Egg-specific docs
│   ├── nestjs/
│   │   ├── egg.json
│   │   ├── entrypoint.sh
│   │   └── README.md
│   ├── fastify/
│   │   ├── egg.json
│   │   ├── entrypoint.sh
│   │   └── README.md
│   └── bunjs/
│       ├── egg.json
│       ├── entrypoint.sh
│       └── README.md
├── .github/
│   └── workflows/
│       └── validate.yml      ← Auto-validate egg JSON on push
└── README.md
```

---

## 🔒 Security

- Git credentials are **injected at runtime** and never logged or stored on disk
- `.env.pterodactyl` is copied to `.env` at startup — secrets stay in the panel, not in your repo
- Cloudflare Tunnel tokens are handled in memory only

---

## 🗺 Roadmap

- [ ] Go (Fiber/Echo/Gin)
- [ ] Python (FastAPI / Django)
- [ ] Deno
- [ ] Static site (Nginx/Caddy)
- [ ] Laravel (PHP)

---

## 📝 License

MIT — free to use, modify, and redistribute.

---

Made with ☕ by **nyxel** — [nyxel.my.id](https://nyxel.my.id)
