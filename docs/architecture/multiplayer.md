# Multiplayer

No custom WebSocket code. SceneServer broadcasts `%EventBatch{}` to all LiveViews subscribed to `"game:#{game_id}"` via `Gibbering.EventBus`. Each LiveView re-renders only its diff.

`GameLive` subscribes to two topics on mount:

- `"game:#{id}"` — receives `%EventBatch{}` after every command
- `"notifications:#{id}"` — receives `%BroadcastSent{}` and `%WhisperDelivered{}`

`GameLive.handle_info(%EventBatch{} = batch, socket)` checks whether the batch contains a `%SessionEnded{}` event (redirect) and otherwise projects `batch.state_snapshot` into `socket.assigns.game_state`. All LiveView subscribers receive `%WhisperDelivered{}` on the notifications topic; GameLive guards on `target_player_id == current_user.id` so only the intended recipient renders the whisper.
