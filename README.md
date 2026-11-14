# NYIT Pool

Billiards-table portal for the NYIT pool hall: shot clocks, chess-clock game banks, and (coming soon) a live table queue.

Single-page timer app (`public/index.html`, vanilla JS, no build step) served by a Cloudflare Worker that also exposes `/api/*` endpoints backed by D1.

## Structure

```
nyitpool/
├── public/index.html    # the timer SPA (served as static assets)
├── src/index.js         # Worker: /api/* routes, everything else -> static assets
├── migrations/          # D1 schema migrations (Table Queue)
├── wrangler.jsonc       # Workers + assets + D1 config
└── package.json         # wrangler scripts
```

## Local dev

```bash
npm install
npm run db:migrate:local   # apply D1 schema to the local dev database
npm run dev                # http://127.0.0.1:8787  (timer + /api/*)
```

Plain static preview without the Worker: serve `public/` with any static server (e.g. `npx serve public`).

## First deploy (wrangler)

```bash
npx wrangler login
npm run db:create          # copy the printed database_id into wrangler.jsonc
npm run db:migrate         # apply schema to remote D1
npm run deploy
```

## Automatic deploys from GitHub (recommended)

Connect the repo to Cloudflare **Workers Builds** so every `git push` to `main` deploys automatically:

1. Cloudflare dashboard → **Workers & Pages** → **Create** → **Import from Git** (or open the existing `nyitpool` worker → **Settings → Builds → Connect to Git**).
2. Authorize the GitHub app and select `silverftw/nyitpool`.
3. Branch: `main` · Build command: *(none)* · Deploy command: `npx wrangler deploy`.
4. Push — watch the build in the dashboard; the worker URL updates on every push.

## API (placeholder)

- `GET /api/health` — liveness probe.
- `GET /api/queue` — list queue entries (D1).
- `POST /api/queue` `{ "team_name": "...", "players": "A · B" }` — join the queue.

## Production

Live at **https://app.nyitpool.workers.dev** — every merge to `main` auto-deploys via Cloudflare Workers Builds.

## Timer controls

`SPACE` pass turn / start · `ENTER` reset shot clock (or refund turn time in game mode) · `P` pause — all work while paused too. Web Audio cues + Screen Wake Lock included.
