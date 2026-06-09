# #115 · Notification event structs and dedicated topic migration

**Status:** open
**Opened:** 2026-06-09
**Priority:** medium
**Tags:** architecture, ui

`{:dm_broadcast, text}` and `{:whisper, text}` are notification events, not scene-domain events. The polytope treatise (§8.5) places them in the Notification context (`Gibbering.Notification`). Currently they are bare tuples on the game PubSub topic, mixing notification concerns with scene event concerns.

**Required changes:**

Define typed notification event structs:
```
Gibbering.Events.Notification
├── BroadcastSent       ← replaces {:dm_broadcast, text}
└── WhisperDelivered    ← replaces {:whisper, text}
```

Fields:
- `BroadcastSent`: `event_id`, `campaign_id`, `text`, `sent_at`
- `WhisperDelivered`: `event_id`, `campaign_id`, `target_player_id`, `text`, `sent_at`

Move broadcasts to a dedicated PubSub topic: `"notifications:#{campaign_id}"` (separate from `"game:#{campaign_id}"`).

Update:
1. `SceneServer.dm_broadcast/2` — emit `%BroadcastSent{}` on the notifications topic
2. Any whisper emission paths — emit `%WhisperDelivered{}` on the notifications topic
3. LiveView subscription — subscribe to `"notifications:#{campaign_id}"` in addition to the game topic
4. LiveView `handle_info` — pattern-match the new structs

**References:**
- Brainstorm #15 (Q5 decision)
- `docs/papers/polytope-architecture.md` §8.5 (Notification events as separate category)
- Issue #107 (namespace: `Gibbering.Notification` assigned)

**Acceptance criteria**
- [ ] `Gibbering.Events.Notification.BroadcastSent` struct defined
- [ ] `Gibbering.Events.Notification.WhisperDelivered` struct defined
- [ ] `SceneServer` broadcasts on `"notifications:#{campaign_id}"` using the typed structs
- [ ] LiveView subscribes to the notifications topic and handles the new structs
- [ ] No bare `{:dm_broadcast, _}` or `{:whisper, _}` tuples remain in any broadcast or `handle_info` clause
- [ ] Existing DM broadcast tests pass with the new structs
