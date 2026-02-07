# Web Release Guide (FlightFinder Web)

## 1) Localhost release candidate

From repo root:

```bash
cd web
npm install
npm run build
NODE_ENV=production npm run start
```

Validate:

- `http://localhost:8787` loads UI
- `http://localhost:8787/api/health` returns JSON status

## 2) Webhost deployment (single service)

This web app is built for one-process hosting:

- Express serves API (`/api/*`)
- Express serves static frontend build (`client/dist`)

### Recommended first host: Render or Railway

Build command:

```bash
cd web && npm install && npm run build
```

Start command:

```bash
cd web && NODE_ENV=production npm run start
```

Set env vars:

- `NODE_ENV=production`
- `PORT` (host-provided)
- optional affiliate vars from `web/.env.example`

## 3) Post-deploy checks

- load home page
- run a sample search (US domestic + USA->PVG)
- run China probe sweep
- confirm outbound deep links open correctly
- confirm affiliate params appear when configured

## 4) Traffic scaling notes

- Keep provider probe timeout at 5s unless needed.
- Rate-limit probe endpoint in front of public traffic.
- Add request logging and per-IP throttling before marketing pushes.
