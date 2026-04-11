# 🥚 Next.js Egg — nyxel

Production-ready Pterodactyl egg for hosting **Next.js** applications from Git.

## Import URL
```
https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nextjs/egg.json
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
| `BUILD_COMMAND` | — | Override `next build` |
| `CLOUDFLARE_TOKEN` | — | CF Zero Trust tunnel token |

## .env Injection
Upload `.env.pterodactyl` to `/home/container/` — auto-copied to `.env` on startup.
