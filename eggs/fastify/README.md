# 🥚 Fastify Egg — nyxel

Production-ready Pterodactyl egg for hosting **Fastify** applications from Git.

## Import URL
```
https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/fastify/egg.json
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `GIT_URL` | — | HTTPS repo URL |
| `GIT_BRANCH` | `main` | Branch to run |
| `AUTO_UPDATE` | `1` | Pull on startup |
| `USERNAME` | — | For private repos |
| `ACCESS_TOKEN` | — | PAT with `repo` scope |
| `NODE_RUN_ENV` | `production` | `production` or `development` |
| `PACKAGE_MANAGER` | `auto` | `auto`, `npm`, `pnpm`, `yarn` |
| `ENTRY_POINT` | — | e.g. `src/index.js`, auto-detected if empty |
| `BUILD_COMMAND` | — | For TypeScript projects |
| `CLOUDFLARE_TOKEN` | — | CF Zero Trust tunnel token |

## Entry Point Resolution (production)
1. `ENTRY_POINT` variable
2. `npm run start` script
3. `package.json` `main` field
4. Common file fallbacks: `src/index.js`, `index.js`, `server.js`, `app.js`

## .env Injection
Upload `.env.pterodactyl` to `/home/container/` — auto-copied to `.env` on startup.
