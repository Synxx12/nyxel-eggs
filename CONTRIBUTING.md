# Contributing — Adding a New Egg

This guide explains how to add a new egg to `nyxel-eggs` so the repo stays consistent long-term.

---

## Folder Structure

Every egg lives in its own folder under `eggs/`:

```
eggs/
└── your-framework/
    ├── egg.json          ← Pterodactyl/Pelican import file (PTDL_v2)
    ├── entrypoint.sh     ← Runtime startup script (fetched at container start)
    └── README.md         ← Egg-specific documentation
```

---

## Step 1 — Create the folder

```bash
mkdir eggs/your-framework
```

---

## Step 2 — Write `entrypoint.sh`

Copy from an existing egg as a base. Key rules:

- Always start with `#!/bin/bash` and `set -euo pipefail`
- Use the color helpers: `log`, `ok`, `warn`, `fail`
- Handle the standard variables: `GIT_URL`, `GIT_BRANCH`, `AUTO_UPDATE`, `USERNAME`, `ACCESS_TOKEN`, `CLOUDFLARE_TOKEN`, `NODE_RUN_ENV`, `PACKAGE_MANAGER`
- Always handle `.env.pterodactyl` injection
- Never print credentials to stdout

---

## Step 3 — Write `egg.json`

Required fields (PTDL_v2):

```json
{
  "_comment": "DO NOT EDIT: FILE GENERATED AUTOMATICALLY BY PTERODACTYL PANEL - PTERODACTYL.IO",
  "meta": { "version": "PTDL_v2", "update_url": null },
  "name": "Your Framework",
  "author": "https://nyxel.my.id",
  "description": "...",
  "docker_images": { ... },
  "startup": "bash -c \"...curl entrypoint.sh...\"",
  "config": { "files": "{}", "startup": "{\"done\":[...]}", "logs": "{}", "stop": "^^C" },
  "scripts": { "installation": { ... } },
  "variables": [ ... ]
}
```

**Startup URL pattern:**
```
https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/YOUR_FOLDER/entrypoint.sh
```

**Minimum required variables** (include these in every egg):

| Variable | Required |
|---|---|
| `GIT_URL` | ✅ |
| `GIT_BRANCH` | ✅ |
| `AUTO_UPDATE` | ✅ |
| `USERNAME` | ✅ |
| `ACCESS_TOKEN` | ✅ |
| `NODE_RUN_ENV` | ✅ |
| `CLOUDFLARE_TOKEN` | ✅ |

Add framework-specific variables after these.

---

## Step 4 — Write `README.md`

Include:
- Import URL (raw GitHub URL to `egg.json`)
- Variables table
- How start/build resolution works
- `.env` injection note

---

## Step 5 — Update root `README.md`

Add your egg to the **Available Eggs** table and **Feature Matrix** table in `/README.md`.

---

## Step 6 — Update docs

Add a card for your egg in `docs/index.html`.

---

## Validation

Push to a branch — GitHub Actions will automatically validate:
- `egg.json` is valid JSON
- PTDL_v2 structure is correct
- `entrypoint.sh` has `#!/bin/bash` shebang
- Startup URL matches egg folder

---

## Naming Conventions

| Thing | Convention |
|---|---|
| Folder name | `lowercase-hyphen` (e.g. `fastify`, `bunjs`, `go-fiber`) |
| `egg.json` name field | Framework display name (e.g. `"Fastify"`, `"Go Fiber"`) |
| Env variables | `UPPER_SNAKE_CASE` |
