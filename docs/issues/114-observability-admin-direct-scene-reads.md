# #114 · Observability and admin: replace direct SceneServer reads with event subscriptions

**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-12
**Priority:** low
**Tags:** architecture, admin

Two modules in non-Scene bounded contexts call `SceneServer.get_state/1` directly, violating the single-writer boundary (see #110) and the general polytope rule that no context reaches into another's internals.

**Violation A — `Gibbering.Monitoring.Stores.Local`**

`lib/gibbering/monitoring/stores/local.ex:142` calls `SceneServer.get_state(campaign_id)` to collect metrics snapshots. Observability should subscribe to the `{:state_updated, state}` event on the PubSub game topic and maintain its own read model rather than polling the scene.

**Violation B — `GibberingWeb.Live.Admin.CampaignMonitoringPage`**

`lib/gibbering_web/live/admin/campaign_monitoring_page.ex:164` calls `SceneServer.get_state(campaign_id)` for the admin monitoring view. The correct pattern is for the monitoring page to subscribe to scene events (or to the Observability context's read model) rather than querying SceneServer directly.

Both violations stem from the absence of a dedicated read model for scene state — addressed by #113 (CQRS read model formalization). This issue should be worked after #113 closes.

**References**
- `docs/papers/polytope-architecture.md` §5.4 (single-writer contract), §9 (CQRS read model)
- Issue #109 (compound bus audit — surfaced these violations)
- Issue #110 (SceneServer single-writer contract)
- Issue #113 (CQRS read model formalization — prerequisite)

**Acceptance criteria**
- [x] `Monitoring.Stores.Local` subscribes to scene events and maintains a local snapshot rather than calling `SceneServer.get_state`
- [x] `Admin.CampaignMonitoringPage` reads from the Observability read model (or a dedicated admin projection) rather than calling `SceneServer.get_state`
- [x] No module outside the Scene bounded context calls `SceneServer.get_state` directly
