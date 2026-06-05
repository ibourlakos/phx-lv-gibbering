# Admin Web App

**Topic:** Design and scope of the admin/support panel — a separate web application for platform operators, BEAM-level monitoring, entity management, and (eventually) user-facing content creation tools.

**Status:** exploration

---

## Context

The Gibbering Engine needs operational tooling that is structurally separate from the player-facing game app. This brainstorm maps out what "admin web app" means: who uses it, what it contains, how it relates to the game app, and where the content-creation story fits.

---

## A. Separation From the Game App

The placeholder says "separate app." There are three interpretations in a Phoenix project:

| Option | Description | Trade-off |
|---|---|---|
| **Router scope** | `/admin` scope in the same Phoenix app; separate pipeline with a support-only plug | Simplest; shared config and DB connection pool; harder to deploy independently |
| **Umbrella sub-app** | `apps/gibbering_admin` — its own Phoenix endpoint in an OTP umbrella | Clean boundary; can deploy separately; more setup overhead now |
| **Fully separate service** | Separate repo and Docker image, calls back to the main app over API | Maximum isolation; significant overhead; only worth it at scale |

The router-scope option is low-cost to start and can be extracted into an umbrella sub-app later. The key invariant is: the admin UI must be behind a separate authentication pipeline, not reachable by regular player accounts.

---

## B. User Types and Roles

Three distinct actor categories:

**Support users** — platform operators; they log in to the admin panel. They should have an internal roles system:

| Role | Capabilities |
|---|---|
| `viewer` | Read-only access to all entities and monitoring |
| `moderator` | Can act on user accounts and campaigns (ban, terminate) |
| `editor` | Can manage catalogue content (items, races, classes, etc.) |
| `admin` | Full access including support user management |

**Player users** — regular accounts; they do not log in to the admin app. A player can be a DM in a campaign — DM is a per-campaign role, not a global user-system role. The admin panel may display a player's campaign memberships and DM history, but it doesn't model DM as an account attribute.

**Auth model:** Support users can share the same `users` table, distinguished by a `support_role` column (null = player). Alternatively, a separate `support_users` table keeps the namespaces fully clean. This is a decision for the auth system brainstorm — the admin app should not drive that choice.

---

## C. CRUD Entity Surface

The entities a support user would need to read/modify, grouped by urgency:

### Core (must-have for operations)

- **Users** — list, inspect, suspend/ban, reset password, verify email manually, view campaign memberships
- **Campaigns** — list active/inactive, inspect metadata, view participant list, force-close a misbehaving campaign
- **Characters** — inspect (for moderation or debugging), not edit unless there's a specific support reason
- **Sessions / Audit log** — read-only; support actions should themselves be logged

### Content Management (required once content is data-driven)

- **Catalogue entries** — Races, Classes, Backgrounds, Spells, Items, Conditions — these are the static reference tables; editors need to add/update them without a deploy
- **Map modules** — tilesets and map templates (when map authoring exists)
- **User-submitted content** — review queue for publicly shared custom items, custom races, etc. (see section F)

### Operational

- **Feature flags** — if the engine uses them (e.g. gating new rule modules)
- **Announcements / maintenance windows** — push a banner to the game app

---

## D. BEAM Monitoring

Elixir/OTP gives first-class introspection. The monitoring surface should cover two levels:

### Platform-level (Phoenix LiveDashboard)

Phoenix LiveDashboard is purpose-built for this and is already a dependency in Phoenix projects. It provides:

- OS metrics: CPU, RAM, disk
- BEAM metrics: process count, atom table, ETS memory, ports
- Request metrics (via Telemetry): latency, throughput, error rate
- Custom Telemetry pages (pluggable)

Embedding LiveDashboard behind the admin auth pipeline gives all of the above for free. The admin app mounts it at `/admin/dashboard`.

### Campaign-level (custom)

Each active campaign runs as a supervised `GenServer` registered in a `Registry`. The admin panel needs a campaign-specific view on top of LiveDashboard:

| Metric | How |
|---|---|
| Active campaign process list | `Registry.select/2` on the campaign registry |
| Per-campaign memory | `:erlang.process_info(pid, :memory)` |
| Per-campaign message queue depth | `:erlang.process_info(pid, :message_queue_len)` — a queue spike is a sign of a hung campaign |
| Connected player count | derived from `PubSub` subscriptions or a counter stored on the campaign state |
| Uptime | timestamp stored in campaign GenServer state at init |
| Graceful shutdown | `DynamicSupervisor.terminate_child/2` with a drain period |

This campaign monitoring view is a LiveView that polls or subscribes to Telemetry events. It is the operational heart of the admin panel — support staff watch it when a campaign is reported as unresponsive.

---

## E. Audit Logging

Any action taken by a support user must be logged: who did what, to which entity, when. This is a hard requirement — without it, support actions are unaccountable.

Minimal shape:

```elixir
%SupportAuditLog{
  actor_id:    support_user_id,
  action:      "campaign.force_close" | "user.suspend" | "catalogue.update_item" | ...,
  target_type: "campaign" | "user" | "character" | ...,
  target_id:   integer | string,
  metadata:    map,     # diff, reason, etc.
  inserted_at: DateTime.t()
}
```

Stored in the DB, not in-process. Log entries are never deleted. The audit log is readable (not editable) by all support roles.

---

## F. Content Creation and the UGC Bridge

The forward note describes two overlapping surfaces:

**1. Official catalogue tooling (admin-side)**

Support editors build and maintain the catalogue: adding new items, tweaking balance numbers, writing descriptions. This is a standard CRUD admin UI backed by the catalogue tables. Changes are versioned — catalogue entries have a `version` field so the engine can detect when a character's stored item data is stale.

**2. Player UGC (game-app-side, moderated by admin)**

Players can create:
- Custom items, custom races, custom character templates
- Map modules (tiles, room layouts)

These live in a `user_content` namespace, distinct from the official catalogue. A piece of user content has:

| Field | Purpose |
|---|---|
| `owner_id` | the creating player |
| `visibility` | `:private` / `:campaign` / `:public` |
| `status` | `:draft` / `:published` / `:under_review` / `:rejected` |
| `content_type` | `"item"` / `"race"` / `"map_module"` / ... |
| `data` | JSONB blob matching the catalogue schema for that type |

When a player submits content for public visibility, it enters a moderation queue visible in the admin panel. Moderators approve or reject; rejected submissions get a reason string shown back to the player.

The admin panel is the moderation surface. The game app is the creation surface. The catalogue schema is the shared contract.

**This toolset is also available to players in the game app** — they access it through a content creator mode in their personal account area, not through the admin panel. Same underlying schemas and business logic; different UI and permission boundaries.

---

## G. Deployment and Security Considerations

- The admin app endpoint must not be exposed on the public-facing port in production. A separate port or an internal network address is appropriate — ops decision, but worth flagging now.
- CSRF, rate limiting, and session timeouts apply with higher strictness than the player app (shorter session TTL, stricter CSRF).
- Support users must use strong credentials; MFA is an eventual requirement.
- All HTTP access to admin routes should be logged at the load-balancer level, independently of the app-level audit log.

---

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | App separation strategy | Router scope within the single Phoenix app. Umbrella restructure deferred to [#60](.issues/060-umbrella-restructure-for-admin-app.md) — revisit only if independent deployment or separate supervision trees become real requirements. |
| 2 | Auth model for support users | Separate `support_users` table — fully decoupled from `users`. A shared `email` field allows the same person to hold both a player account and a support account; the two identities are linked by convention (email), not by schema. This also keeps the boundary clean for a future umbrella extraction. |
| 3 | Monitoring depth and history | LiveDashboard + custom campaign server page. History via ETS ring buffer (short-term sparklines) + DB snapshots (sampled ~60s, pruned after 7 days). Strain detection fires a debounced Telemetry event → PubSub: support alert on `system:admin`, optional rate-limited UX banner on `campaign:<id>` (no metrics exposed to players). Query side abstracted behind a `Gibbering.Monitoring.MetricsStore` behaviour (`Stores.Local` now; `Stores.Prometheus` when Prometheus is added). Emission side uses `:telemetry` directly — no wrapper needed. |
| 4 | UGC moderation policy | Hybrid trust model. `users` carries a `content_trust` boolean. On public submission: trusted players → status jumps directly to `:published` (auto-publish); untrusted players → status set to `:under_review` (human review queue in admin panel). Trust is granted by a moderator or admin. Unapproved content (`:draft`, `:under_review`, `:rejected`) is previewable but cannot be selected or used in a campaign. Only `:published` content is campaign-eligible. |
| 5 | Catalogue versioning / export-import format | Export/import serialization uses a `schema_version` integer tag at the root + a migration pipeline (`v1_to_v2`, etc.). All catalogue references export as stable string keys, never database IDs. Tolerant reader rules apply: unknown fields are dropped, missing fields get defaults. Additive changes are free; breaking changes increment the version. Catalogue entry versioning (tracking edits to live catalogue data) is a separate concern, deferred to [#61](.issues/061-catalogue-entry-versioning.md). Export/import implementation tracked in [#59](.issues/059-character-export-import.md). |

---

## Open Questions

- ~~**App separation strategy**: Router scope (fast) vs. umbrella sub-app (clean) — which to start with?~~ *(decided — see Decisions table)*
- ~~**Auth overlap**: Do support users share the `users` table (with a `support_role` field) or get a separate `support_users` table?~~ *(decided — see Decisions table)*
- ~~**LiveDashboard customisation depth**: How much custom Telemetry instrumentation is needed beyond the built-in metrics?~~ *(decided — see Decisions table)*
- ~~**UGC moderation SLA**: Is human review mandatory for all public submissions, or is there a trust-level system (trusted players auto-publish)?~~ *(decided — see Decisions table)*
- ~~**Catalogue versioning / export-import format**~~ *(decided — see Decisions table; catalogue entry versioning deferred to [#61](.issues/061-catalogue-entry-versioning.md))*
- **Content creation UI scope**: Is the player-facing content creation tool in scope for this brainstorm, or does it get its own?
