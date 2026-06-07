# #69 · `MetricsStore` behaviour + `Stores.Local` implementation

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** low
**Tags:** architecture, ops

Implement the hexagonal monitoring layer: a `MetricsStore` behaviour for history querying, a `Stores.Local` adapter backed by ETS ring buffer + DB snapshots, and strain detection via Telemetry.

Depends on [#68](068-livedashboard-and-campaign-monitoring.md).

**Acceptance criteria**
- [x] `Gibbering.Monitoring.MetricsStore` behaviour with `record/3` and `history/2`
- [x] `Gibbering.Monitoring.Stores.Local` — ETS ordered_set ring buffer (5-min window); polls GameRegistry every 10s; snapshots to `campaign_metric_snapshots` every 60s; prunes after 7 days hourly
- [x] `Gibbering.Monitoring.Stores.NoOp` — drops writes, returns `[]`; active in test env via config
- [x] Adapter configured via `config :gibbering, Gibbering.Monitoring.MetricsStore, adapter: ...`
- [x] Polling in `Stores.Local` (not via Telemetry events) — records memory_bytes, queue_depth, entity_count per active campaign
- [x] Strain detection: PubSub broadcast on `system:admin` after ≥10s above threshold (100MB memory or 500 queue depth)
- [x] CampaignMonitoringPage uses `MetricsStore.history/2` for inline SVG sparklines (memory trend)
- [x] `Stores.Prometheus` not implemented — behaviour is the extension point
