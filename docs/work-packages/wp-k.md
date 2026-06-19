# WP-K · Spectator Implementation
**Status:** active
**Added:** 2026-06-14

Derived from closed discovery #92. Sequence: data layer → presentation.

## Dependency chain

```
#121 (membership model: DB migration, auth) → #122 (LiveView session view)
```

## Issues

| # | Title | Priority | Depends on |
|---|---|---|---|
| [#121](../issues/121-spectator-membership-model.md) | Campaign membership: spectator role and invite flow | low | — |
| [#122](../issues/122-spectator-session-view.md) | Spectator session view: shared GameLive mount, full-map default, PC-perspective toggle | low | #121 |

## Sequencing

#121 first — adds the `:spectator` enum value, `invited_by_user_id` FK, and extends the invite token mechanism. #122 second — wires spectator detection into `GameLive`, full-map render, PC-perspective toggle, spectator count HUD.
