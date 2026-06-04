# #22 · User accounts and authentication

**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** architecture, gameplay, ops

## Context

The game needs a user account system so players can be identified across sessions (resolving #18). Users fall into three roles:

| Role | Description |
|---|---|
| `player` | A standard player — can join campaigns, claim a character slot in the lobby, and play their character. |
| `dm` | Dungeon Master — can do everything a player can, plus create campaigns, add/remove character slots, and run the game world. DM actions in the lobby are gated on this role. |
| `support` | Internal support/admin — can view all campaigns and users. Does not participate as a player. Intended for operational/debugging use. |

## What is being built

- `users` table: `username` (unique), `password_hash`, `role` (player/dm/support)
- `Gibbering.Accounts` context: `register_user/1`, `authenticate_user/2`, `get_user_by_id/1`
- `GibberingWeb.UserAuth`: `:fetch_current_user` plug for controllers; `:mount_current_user` and `:ensure_authenticated` `on_mount` hooks for LiveViews
- Registration page (`/register`) — choose username, password, role
- Login page (`/login`) — username + password
- Logout (`DELETE /logout`)
- Root layout nav bar showing username, role badge, logout link
- Lobby updated: DM-only controls (add slot, remove slot) gated behind `current_user.role == "dm"`; player identity is now `current_user.id`, display name is `current_user.username`

## Known limitations / future work

- Role is self-selected at registration (anyone can register as DM). In production, DM/support roles should be assigned by an admin or require an invite code.
- No email or password reset flow.
- No "require auth" gate on `/game/:id` yet — anonymous observers can watch but cannot act (future enforcement).

**Acceptance criteria**
- [x] `users` table with username, password_hash, role
- [x] Registration and login flows working
- [x] `current_user` available in all LiveViews via `on_mount` hook
- [x] Lobby: player identity derived from `current_user`, display name shown on claimed slots
- [x] Lobby: DM-only controls hidden from plain players
- [x] Nav bar shows username + role badge + logout on all pages
