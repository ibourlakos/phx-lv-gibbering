# #191 · `freeform_roll` broadcasts directly on SceneServer's topic, violating single-writer contract

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, architecture

`SceneServer`'s moduledoc states a single-writer contract: "SceneServer is
the sole emitter of `%EventBatch{}` messages on the game PubSub topic ...
No other process may broadcast to these topics." This contract was
established and closed under #110.

`GameLive.handle_event("freeform_roll", ...)` constructs a
`%FreeformRolled{}` event directly and calls
`EventBus.broadcast(SceneServer.topic(socket.assigns.game_id), event)` —
`GameLive` broadcasting directly onto SceneServer's topic, bypassing
SceneServer's GenServer API entirely. This is a live regression against
#110's closed contract (note: `FreeformRolled` isn't wrapped in an
`%EventBatch{}`, so it's arguably a distinct message type sharing the
topic — but the moduledoc's wording doesn't carve out an exception for
non-`EventBatch` messages, so it reads as drift either way).

Benign in practice (freeform dice rolls don't touch scene state), but the
doc and code now disagree, and the precedent risks eroding the contract
for future additions.

**Acceptance criteria**
- [ ] Decide: route `freeform_roll` through SceneServer's API (preferred,
      matches the documented contract), or explicitly amend the
      moduledoc to carve out non-domain-event broadcast types
- [ ] Whichever is chosen, code and moduledoc agree
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
