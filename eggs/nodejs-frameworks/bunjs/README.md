# 🥚 Bun.js Egg — nyxel

Production-ready Pterodactyl egg for hosting **Bun.js** applications (Elysia, Hono, plain Bun) from Git.

## Import URL

```
https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/bunjs/egg.json
```

## Variables

| Variable           | Default      | Description                                 |
| ------------------ | ------------ | ------------------------------------------- |
| `GIT_URL`          | —            | HTTPS repo URL                              |
| `GIT_BRANCH`       | `main`       | Branch to run                               |
| `AUTO_UPDATE`      | `1`          | Pull on startup                             |
| `USERNAME`         | —            | For private repos                           |
| `ACCESS_TOKEN`     | —            | PAT with `repo` scope                       |
| `NODE_RUN_ENV`     | `production` | `production` or `development` (--watch)     |
| `ENTRY_POINT`      | —            | e.g. `src/index.ts`, auto-detected if empty |
| `BUILD_COMMAND`    | —            | Optional build step                         |
| `CLOUDFLARE_TOKEN` | —            | CF Zero Trust tunnel token                  |

## Entry Point Resolution

1. `ENTRY_POINT` variable
2. `package.json` `main` field
3. Common fallbacks: `src/index.ts`, `index.ts`, `src/index.js`, `index.js`, `server.ts`, `app.ts`

## Notes

- Bun is auto-installed if not present in the Docker image
- Supports TypeScript natively — no transpilation needed
- Development mode uses `bun --watch` for hot-reload

## .env Injection

Upload `.env.pterodactyl` to `/home/container/` — auto-copied to `.env` on startup.
