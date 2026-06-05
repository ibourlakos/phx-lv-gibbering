# #68 · LiveDashboard mount + custom campaign monitoring page

**Status:** open
**Opened:** 2026-06-05
**Priority:** low
**Tags:** ops, architecture

Mount Phoenix LiveDashboard behind the admin auth pipeline and add a custom page for per-campaign GenServer introspection.

Depends on [#64](064-admin-router-scope-and-pipeline.md).

**Acceptance criteria**
- [ ] LiveDashboard mounted at `/admin/dashboard` — accessible only to authenticated support users; not reachable without a valid support session
- [ ] Custom `CampaignMonitoringPage` LiveDashboard page showing a table of all active campaign processes:
  - Campaign ID and name
  - PID (via Registry lookup)
  - Memory (`:erlang.process_info(pid, :memory)`)
  - Message queue depth (`:erlang.process_info(pid, :message_queue_len)`)
  - Connected player count
  - Uptime (derived from timestamp in GenServer state)
- [ ] Table refreshes on a LiveDashboard-native timer (no manual polling)
- [ ] "Force close" action on each row delegates to `DynamicSupervisor.terminate_child/2` and logs via audit log
