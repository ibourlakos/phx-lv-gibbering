# #69 · `MetricsStore` behaviour + `Stores.Local` implementation

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** architecture, ops

Implement the hexagonal monitoring layer: a `MetricsStore` behaviour for history querying, a `Stores.Local` adapter backed by ETS ring buffer + DB snapshots, and strain detection via Telemetry.

Depends on [#68](068-livedashboard-and-campaign-monitoring.md).

**Acceptance criteria**
- [ ] `Gibbering.Monitoring.MetricsStore` behaviour defined with `record/3` and `history/2` callbacks
- [ ] `Gibbering.Monitoring.Stores.Local` implements the behaviour:
  - ETS ring buffer per campaign — fixed-size circular buffer of recent samples (~5 min); feeds sparklines
  - DB snapshots — `campaign_metric_snapshots` table sampled ~every 60s; pruned after 7 days via a scheduled job
- [ ] `Gibbering.Monitoring.Stores.NoOp` for test environments (drops all writes, returns `[]` for history)
- [ ] Active adapter configured via application config (default: `Stores.Local`)
- [ ] Campaign GenServer emits `:telemetry.execute/3` events for memory, queue depth, player count; a Telemetry handler calls `MetricsStore.record/3`
- [ ] Strain detection: if message queue depth or memory exceeds a configurable threshold for ≥ 10s, fire a debounced PubSub broadcast on `system:admin`
- [ ] Admin monitoring page (from [#68](068-livedashboard-and-campaign-monitoring.md)) uses `MetricsStore.history/2` for sparklines
- [ ] `Stores.Prometheus` is **not** implemented here — the behaviour makes it a future drop-in
