# 🎵 Lavalink

> Audio streaming node for Discord bots — maintained by [nyxel](https://nyxel.my.id)

[Lavalink](https://github.com/lavalink-devs/Lavalink) is a standalone audio streaming server built on Lavaplayer and Koe. It is the de-facto standard for powering music bots on Discord, enabling high-quality, low-latency audio playback without putting load on your bot process.

---

## ✨ Features

- **Auto-download JAR** — fetches the latest (or pinned) Lavalink release on first boot, no manual upload needed
- **`application.yml` generation** — config is written from panel variables on every startup
- **Password protection** — set your server password directly from the panel
- **Version pinning** — lock to a specific release tag (e.g. `v4.0.8`) or use `LATEST`
- **Plugin support** — pass a comma-separated list of plugin JAR URLs via `LAVALINK_PLUGINS`
- **Java 17 / 21** — choose your Java version at the server level
- **Cloudflare Tunnel** — expose your node securely without opening ports
- **Colored console output** — startup logs are formatted and readable

---

## 🐳 Docker Images

| Image | Java Version | Recommended |
|-------|-------------|-------------|
| `ghcr.io/parkervcp/yolks:java_21` | Java 21 | ✅ |
| `ghcr.io/parkervcp/yolks:java_17` | Java 17 | For Lavalink v3 |

---

## ⚙️ Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LAVALINK_VERSION` | Release tag or `LATEST` | `LATEST` |
| `SERVER_PORT` | Port Lavalink listens on | `2333` |
| `SERVER_PASSWORD` | Authentication password for clients | `youshallnotpass` |
| `SERVER_MEMORY` | Java heap size in MB | `512` |
| `LAVALINK_PLUGINS` | Comma-separated plugin JAR URLs (optional) | *(empty)* |
| `CLOUDFLARE_TOKEN` | CF Zero Trust tunnel token (optional) | *(empty)* |

---

## 🚀 Quick Install

1. Go to **Admin Panel** → **Nests** → **Import Egg**
2. Upload or paste the raw URL for `egg.json`:
   ```
   https://raw.githubusercontent.com/Synxx12/nyxel-eggs/main/eggs/bots-audio/lavalink/egg.json
   ```
3. Create a server using this egg
4. Set `SERVER_PASSWORD` to a strong secret
5. Start the server — Lavalink will auto-download and launch

---

## 🔌 Connecting Your Bot

Use any Lavalink v4-compatible client. Examples:

**Node.js — [Shoukaku](https://github.com/Deivu/Shoukaku)**
```js
const nodes = [{
  name: 'nyxel',
  url: 'your-server-ip:2333',
  auth: 'your-password',
}];
```

**Python — [Wavelink](https://github.com/PythonDiscord/wavelink)**
```python
node = wavelink.Node(
    uri="http://your-server-ip:2333",
    password="your-password"
)
```

**Java — [Lavalink-Client](https://github.com/lavalink-devs/lavalink-client)**
```java
LavalinkClient client = new LavalinkClient(userId);
client.addNode(new NodeOptions("nyxel", "http://your-server-ip:2333", "your-password"));
```

---

## 🔌 Recommended Plugins

| Plugin | Description | URL |
|--------|-------------|-----|
| [LavaSrc](https://github.com/topi314/LavaSrc) | Spotify, Apple Music, Deezer sources | [JAR](https://github.com/topi314/LavaSrc/releases) |
| [SponsorBlock-Plugin](https://github.com/TopiSenpai/Sponsorblock-Plugin) | Skip sponsor segments | [JAR](https://github.com/TopiSenpai/Sponsorblock-Plugin/releases) |
| [youtube-source](https://github.com/lavalink-devs/youtube-source) | YouTube with rotation support | [JAR](https://github.com/lavalink-devs/youtube-source/releases) |

To use plugins, paste the JAR download URLs (comma-separated) into `LAVALINK_PLUGINS`.

---

## 🔒 Security Notes

- Change `SERVER_PASSWORD` — never leave it as `youshallnotpass` in production
- Consider using Cloudflare Tunnel instead of exposing port `2333` publicly
- `application.yml` is regenerated on every restart from panel variables — do not edit it manually inside the container

---

Made with ☕ by **nyxel** — [nyxel.my.id](https://nyxel.my.id)
