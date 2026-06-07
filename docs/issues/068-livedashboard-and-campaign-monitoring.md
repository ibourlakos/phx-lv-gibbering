# #68 · LiveDashboard mount + custom campaign monitoring page

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-07
**Priority:** low
**Tags:** ops, architecture

Mount Phoenix LiveDashboard behind the admin auth pipeline and add a custom page for per-campaign GenServer introspection.

Depends on [#64](064-admin-router-scope-and-pipeline.md).

**Acceptance criteria**
- [x] LiveDashboard mounted at `/admin/dashboard` behind the `:admin` plug pipeline (RequireSupportUser)
- [x] Custom `CampaignMonitoringPage` showing active campaign processes: campaign ID/name, PID, memory (KB), message queue depth, entity count, phase
- [x] Table refreshes on LiveDashboard native timer via `handle_refresh/1`
- [x] "Force close" button calls `Admin.force_close_campaign/3` and re-fetches the row list
- Note: entity count uses `SceneServer.get_state/1`; uptime not tracked (State has no start timestamp — deferred to #69 telemetry)
