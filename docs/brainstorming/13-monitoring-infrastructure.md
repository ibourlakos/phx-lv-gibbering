# 13 — Monitoring Infrastructure (Prometheus + Grafana)

**Status:** settled

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

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Library choice | **PromEx** — strong Elixir/Phoenix community support, ships pre-built Grafana dashboards for Phoenix, Ecto, and Erlang VM, minimal instrumentation code on top of existing `:telemetry` events |
| 2 | Grafana hosting | **Self-hosted Docker** — no third-party data sharing, consistent with Docker-first approach; Grafana Cloud deferred to production infra phase |
| 3 | Compose strategy | **Separate `compose.monitoring.yml` overlay** — keeps dev startup lean; monitoring is opt-in via `docker compose -f docker-compose.yml -f compose.monitoring.yml up` |
| 4 | Admin embed (Option B) | **Phase 2** — start with standalone Grafana at `localhost:3000`; embedding in the admin LiveView is deferred until metrics are proven stable |
| 5 | Minimum dashboards | **PromEx defaults: Phoenix, Ecto, Erlang VM** — covers the baseline before any real-player session; custom game-level dashboards are a separate follow-up |
| 6 | Alerting | **Deferred indefinitely** — dashboards-first; no PagerDuty, email, or Slack integration planned in the near term |
| 7 | Retention policy | **Deferred to production infra phase** — local dev uses Prometheus default retention; prod strategy tracked with [#62](../issues/062-multi-environment-infra.md) |
| 8 | `/metrics` security | **Not public** — endpoint restricted to internal Docker network only; admin credentials via `.env` |

---

## Cross-References

- Brainstorm #12 — player/DM experience (game session metrics will tie to session lifecycle defined there)

---

## Issues

_Triaged 2026-06-06, deferred 2026-06-12_

| # | Title | Status |
|---|---|---|
| [#96](../issues/096-promex-prometheus-grafana-stack.md) | PromEx + Prometheus + Grafana monitoring stack | deferred — monitoring infrastructure is not on the critical path; implement after content and gameplay foundation is established |

Deferred follow-ons (no issue yet — open when #96 is un-deferred):
- Custom game-level metrics (active sessions, turn processing latency, connected players) — depends on #96
- Admin app Grafana embed (Option B) — depends on #96 and stable metrics baseline
