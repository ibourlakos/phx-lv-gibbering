# #153 · SVG testability — data attributes and Floki assertion layer
**Status:** closed
**Opened:** 2026-06-19
**Closed:** 2026-06-30
**Priority:** medium
**Tags:** ops, architecture, rendering

Establish the Floki-based display testing layer from brainstorm #20. Replace raw
`=~` string assertions in `game_live_test.exs` with structural DOM assertions and
add the prerequisite data attributes and pure render helper extractions.

**Phase 1 — data attributes**

Add `data-*` attributes to SVG render output so test selectors are stable:
- Entities: `data-entity-id`, `data-entity-type`, `data-hp-pct`
- Tiles: `data-x`, `data-y`, `data-walkable`, `data-texture`
- Overlays: `data-overlay-type` (move, fog, selection)
- HP display: `.hp-bar`, `.hp-exact` (DM only), `.hp-bucket` (player)

**Phase 2 — Floki assertion helpers**

Extract a `GibberingWeb.SVGAssertions` test helper module:
```elixir
# Helpers over Floki.parse_document/render(view)
assert_entity_visible(doc, entity_id)
refute_entity_visible(doc, entity_id)       # fog of war / hidden
assert_hp_bucket(doc, entity_id, "Bloodied")  # player view
assert_hp_exact(doc, entity_id, "14/28")      # DM view
assert_tile_walkable(doc, x, y)
```

**Phase 3 — role-gating tests**

Add a two-session role-gating test pattern to `game_live_test.exs`:
- Open DM `live/2` connection + player `live/2` connection from same game state
- Assert diverging render output (DM sees exact HP; player sees bucket)
- Assert fog-of-war: hidden entity absent from player `render(view)`

**Phase 4 — pure render helper extraction (prerequisite for Layer 1 unit tests)**

Extract `render_entity/2`, `render_tile/2`, `render_overlay/2` as pure functions.
Layer 1 unit tests call them directly, no LiveView stack needed.

**Acceptance criteria**
- [ ] All SVG element types have the `data-*` attributes listed above
- [ ] `GibberingWeb.SVGAssertions` helper module exists with the listed helpers
- [ ] At least one role-gating test (DM vs player HP visibility) uses the two-session pattern
- [ ] At least one fog-of-war test uses `refute_entity_visible/2`
- [ ] `render_entity/2` and `render_tile/2` are pure functions tested at Layer 1
- [ ] All existing `game_live_test.exs` assertions converted from `=~` to Floki
- [ ] `docs/testing.md` updated with the two-session pattern and data-attribute conventions
