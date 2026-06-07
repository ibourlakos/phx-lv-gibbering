# 13 — Monitoring Infrastructure (Prometheus + Grafana)

## Context

As the app grows — multiple game sessions, LiveView processes, PubSub channels, DB load — we need
observability beyond `Logger`. This brainstorm explores a Prometheus + Grafana stack, what to instrument,
and how it fits architecturally (separate service, admin app component, or both).

---

## What We Want to Observe

### Application-Level (Elixir / Phoenix)
- LiveView socket count and mount/unmount rate
- PubSub message throughput per topic
- GenServer (SceneServer, GameServer, LobbyServer) process counts, mailbox sizes, crash rate
- Ecto query duration and error rate
- HTTP request rate, latency, and error rate (Phoenix Telemetry)
- Memory and GC pressure per node

### Game-Level
- Active sessions (lobbies + in-progress games)
- Players connected per session
- Turn processing latency (time from player action to state broadcast)
- Event queue depth

### Infrastructure
- PostgreSQL: connection pool usage, slow queries, lock waits
- Docker container CPU/memory
- Disk I/O (relevant once we add binary assets via LFS)

---

## Stack Choice: Prometheus + Grafana

This is a well-trodden path for Elixir apps via `PromEx` (built on Telemetry).

### PromEx
- Elixir library that ships pre-built Grafana dashboards for Phoenix, Ecto, Oban, Erlang VM
- Exposes a `/metrics` HTTP endpoint for Prometheus to scrape
- Dashboards are versioned JSON uploaded to Grafana on app start (or manually)
- Minimal instrumentation code — mostly config + existing `:telemetry` events

### Prometheus
- Runs as a separate Docker service
- Scrapes the app's `/metrics` endpoint on a configurable interval
- Stores time-series data locally (or remote write to Grafana Cloud — defer)

### Grafana
- Runs as a separate Docker service (or Grafana Cloud free tier — to decide)
- Connects to Prometheus as a data source
- PromEx uploads dashboards automatically on app boot (requires Grafana API key)

---

## Architectural Options

### Option A — Pure Docker Compose services (no app changes beyond PromEx)
- Add `prometheus` and `grafana` services to `docker-compose.yml` (or a separate `compose.monitoring.yml`)
- App exposes `/metrics`, Prometheus scrapes it, Grafana visualises it
- Grafana lives at `localhost:3000` in dev, behind a reverse proxy in prod
- Pros: clean separation, no admin app changes
- Cons: Grafana is a separate UI, not integrated into the admin app

### Option B — Admin app embeds a Grafana iframe / live dashboard panel
- Grafana still runs as a service, but is embedded in the admin LiveView via iframe or proxy
- Admins don't leave the app to check metrics
- Pros: single pane of glass for ops
- Cons: Grafana auth and embedding config can be fiddly; adds coupling

### Option C — Custom LiveView metrics dashboard (no Grafana)
- Pull Prometheus data via HTTP from a LiveView, render charts in SVG or a lightweight chart lib
- Pros: fully in-stack, no external UI dep
- Cons: significant build effort, reinventing the wheel; Grafana is better at this

Likely winner: **Option A** to start, **Option B** as a later enhancement once metrics are stable.

---

## Integration Points in This Project

- `PromEx` added as a dep, configured as an OTP application
- Supervisor tree: PromEx process added to app supervision
- Router: `/metrics` endpoint added (protected — not public in prod)
- `docker-compose.yml` (or overlay): `prometheus` + `grafana` services with named volumes
- Grafana provisioning: datasource and dashboard JSON in `priv/grafana/` or `config/grafana/`
- CI: metrics endpoint smoke-test (optional, defer)

---

## Security Considerations

- `/metrics` endpoint must be private (not exposed in prod without auth or network restriction)
- Grafana admin password via env var, not hardcoded
- Prometheus scrape config should restrict to internal Docker network only
- Grafana Cloud option avoids self-hosting but sends data to a third party — check legal/privacy

---

## Open Questions

- Do we want Grafana self-hosted (Docker) or Grafana Cloud free tier?
- Separate `compose.monitoring.yml` overlay or baked into the main `docker-compose.yml`?
- Should the admin app embed Grafana from day one or treat it as phase 2?
- What is the minimum set of dashboards / alerts to have before first real-player session?
- Do we want alerting (PagerDuty/email/Slack) — or just dashboards for now?
- Is PromEx the right choice, or roll minimal custom telemetry? (PromEx has good Elixir community support — lean toward it)
- Retention policy for Prometheus data in dev vs. prod?

---

## Cross-References

- Brainstorm #12 — player/DM experience (game session metrics will tie to session lifecycle defined there)

---

## Issues Opened
_Triaged 2026-06-06_

| # | Title | Open questions handled |
|---|---|---|
| [#96](../issues/096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | Stack choice (PromEx), Docker compose strategy, security for `/metrics` endpoint |

Deferred open questions (not yet resolved in #96):
- Grafana self-hosted vs. Grafana Cloud — deferred; #96 defaults to self-hosted Docker
- Alerting (PagerDuty/email/Slack) — deferred indefinitely; dashboards-first
- Custom game-level metrics (active sessions, turn latency) — follow-up issue after #96 lands
- Retention policy dev vs. prod — deferred to production infra phase ([#62](../issues/062-multi-environment-infra.md))
- Admin app Grafana embed (Option B) — tracked in [#68](../issues/068-livedashboard-and-campaign-monitoring.md) as a later enhancement
