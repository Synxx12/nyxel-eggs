# 🥚 NestJS Egg — nyxel

Production-ready Pterodactyl egg for hosting **NestJS** applications from Git.

## Import URL

```
https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/nodejs-frameworks/nestjs/egg.json
```

## Variables

| Variable           | Default      | Description                   |
| ------------------ | ------------ | ----------------------------- |
| `GIT_URL`          | —            | HTTPS repo URL                |
| `GIT_BRANCH`       | `main`       | Branch to run                 |
| `AUTO_UPDATE`      | `1`          | Pull on startup               |
| `USERNAME`         | —            | For private repos             |
| `ACCESS_TOKEN`     | —            | PAT with `repo` scope         |
| `NODE_RUN_ENV`     | `production` | `production` or `development` |
| `PACKAGE_MANAGER`  | `auto`       | `auto`, `npm`, `pnpm`, `yarn` |
| `BUILD_COMMAND`    | —            | Override `nest build`         |
| `START_COMMAND`    | —            | Override start resolution     |
| `CLOUDFLARE_TOKEN` | —            | CF Zero Trust tunnel token    |

## Start Resolution (production)

1. `node dist/main.js`
2. `node dist/src/main.js`
3. `npm run start:prod`
4. `npm run start`

## .env Injection

Upload `.env.pterodactyl` to `/home/container/` — auto-copied to `.env` on startup.
