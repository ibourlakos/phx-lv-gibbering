# #96 · PromEx + Prometheus + Grafana monitoring stack
**Status:** deferred
**Opened:** 2026-06-06
**Deferred because:** Monitoring infrastructure is not on the critical path; implement after content and gameplay foundation is established. Brainstorm #13 is settled — un-defer this when ready to proceed.
**Priority:** low
**Tags:** ops, architecture

Add structured observability via PromEx (Elixir Telemetry → Prometheus) and a self-hosted Grafana instance in Docker.

Scope:
- Add `prom_ex` dep; configure it as an OTP application in the supervision tree
- Expose a `/metrics` endpoint (protected — internal only, not public in prod)
- Add `prometheus` and `grafana` services to a `compose.monitoring.yml` overlay (not the main compose file to keep dev startup lean)
- Grafana provisioning: datasource and PromEx dashboard JSON in `priv/grafana/`
- Grafana admin credentials via env var (not hardcoded)
- Prometheus scrape config restricted to internal Docker network

Default dashboards to enable: Phoenix, Ecto, Erlang VM (all shipped by PromEx). Custom game-level metrics (active sessions, turn processing latency, connected players) can follow in a separate issue.

Relationship to existing issues: #68 (LiveDashboard + campaign monitoring) and #69 (MetricsStore) are in-app custom metrics; this issue is the external observability stack. They are complementary.

**Acceptance criteria**
- [ ] `prom_ex` configured and `/metrics` endpoint responds with valid Prometheus text format
- [ ] `compose.monitoring.yml` brings up Prometheus (scraping the app) and Grafana
- [ ] Grafana at `localhost:3000` with Phoenix, Ecto, and VM dashboards loaded automatically
- [ ] Credentials sourced from `.env`; no secrets hardcoded in compose or config files
- [ ] `docs/dev-setup.md` updated with instructions for starting the monitoring overlay
- [ ] `/metrics` endpoint returns 403 or is network-restricted in prod config
