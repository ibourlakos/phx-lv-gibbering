# Engine Decomposition — Generic Core vs. D&D 5e

Working document tracking the planned separation of the reusable game engine from its D&D 5e implementation. Companion to [bounded-contexts.md](bounded-contexts.md) and [ruleset-behaviour.md](ruleset-behaviour.md).

**Status**: Phase 0 complete (2026-06-30). Phase 1 complete (2026-07-01, #163). Updated as decisions are made.

---

## Goal

Extract a self-contained game engine that can host a second game (e.g., a simple card game or tile-based auto-battler) without carrying any D&D 5e concepts. The D&D 5e game becomes one implementation on top of that engine. The engine's correctness can then be concept-proved by building the second toy game.

Appearance/display elements are intentionally **vertical** — the rendering pipeline (SpriteCompositor, AppearanceArchetype, IsoProjection) is generic engine code; the sprites and appearance records that feed it are game-specific content. This vertical split is already the right model and does not need to change.

**File placement follows the same split (#180):** DB-backed content (`Catalogue.Style`/`Catalogue.Appearance` rows) has always lived in `gibbering_tales`. File-based content — e.g. `GibberingTales.Catalogue.TemplateStore` and `apps/gibbering_tales/priv/appearance_templates/**/*.svg.eex` — follows the same rule and lives in `gibbering_tales` too, never in `gibbering_engine` (which must stay content-free and eventually Hex-publishable) and not in either Phoenix app unless the content is genuinely Phoenix/LiveView-specific (e.g. HEEx templates). `GibberingEngine.ActorAppearance.render_body/4` takes an injected renderer callback rather than depending on `TemplateStore` directly, so the engine never needs to know a template file exists.

---

## Classification: What is Generic Today

### Fully Generic Engine (no D&D concepts)

| Module | Notes |
|--------|-------|
| `Engine.SceneServer` | OTP GenServer; dispatches to `state.ruleset` for all rule decisions |
| `Engine.GameSession` | Registry + supervision; game-type agnostic |
| `Engine.SpriteCompositor` | Pure SVG layer composition; no game rules |
| `Engine.AppearanceArchetype` | Sprite socket/layer model; no game rules |
| `Engine.ConditionBadge` | Badge rendering logic generic; condition name strings are game-supplied |
| `GibberingWeb.IsoProjection` | 2:1 dimetric math; reusable for any square-tile game |
| `EventBus` port + adapters | Pure broadcast infrastructure |
| `Ruleset` behaviour | The seam — defines the contract any ruleset must implement |
| `Events.Upcaster` behaviour | Schema versioning contract; game-agnostic |
| `Events.EventBatch` | Transport envelope; game-agnostic |
| `Catalogue.Cache` | Generic ETS caching layer |
| `Catalogue.Appearance` / `Style` schemas | Generic `{content_type, content_key, state}` → visual data |
| `Monitoring.*` | Metrics port + adapters |

### Generic Logic, D&D Data References (~30% coupling)

| Module | D&D coupling | Path to clean separation |
|--------|-------------|--------------------------|
| `Engine.State` | 13 of 24 fields are D&D-specific (see field table below) | Add `:ruleset_state` opaque field; move initiative/phase/effects there |
| `Engine.Rules` | Tile cost = 5 ft; Chebyshev = D&D diagonal rule; stat key `"speed"` | Parameterise cost via ruleset callback; stat keys abstracted |
| `Engine.Inventory` | Carry weight in D&D pounds; uses `Data.Items` | Move D&D weight logic to `DnD5e` ruleset; engine handles only item transfer |
| `Rulesets.DnD5e.ModifierPipeline` | Algorithm generic; data sources are D&D | Algorithm extractable to `Engine.ModifierPipeline`; data sources injected |
| `Rulesets.DnD5e.Predicate` | Evaluator logic generic; 12 of 51 predicates name D&D concepts | Core evaluator extractable; D&D predicates stay in ruleset |
| `Engine.RuleModifier` | Data struct; no D&D logic | Moved to engine namespace (Phase 0 ✓) |

### Generic Events (Phase 0 complete ✓)

| `Events.Engine.*` (generic) | `Events.DnD5e.*` (D&D-specific) |
|---------|-------------|
| `EntityMoved` | `AttackResolved` |
| `TurnAdvanced` | `DamageDealt` |
| `PhaseTransitioned` | `SpellCast` |
| `HPAdjusted` | `ConditionApplied` / `ConditionRemoved` |
| `ResourceConsumed` | `ItemEquipped` / `ItemTaken` |
| `ContainerOpened` | |
| `RollRequired` | |
| `SessionEnded` | |
| `LogEntryRevealed` / `LogEntryHidden` | |

`BroadcastSent` / `WhisperDelivered` remain in `Events.Notification.*` (already separated).

### Pure D&D (never reusable as-is)

- `Rulesets.DnD5e` — full 5e ruleset implementation
- `Rulesets.DnD5e.Stats` — ability modifiers, proficiency bonus, AC formulas
- `Rulesets.DnD5e.Condition` — 14 SRD conditions with `%RuleModifier{}` lists
- `Rulesets.DnD5e.Spell` — spell mechanics struct
- `Catalogue.Monster`, `Race`, `Class`, `Spell` — SRD content schemas
- `Data.*` — all static reference tables (Items, Spells, Classes, Races, Backgrounds, Monsters)
- `Events.DnD5e.AttackResolved`, `DamageDealt`, `SpellCast`, `ConditionApplied`, `ConditionRemoved`, `ItemEquipped`, `ItemTaken`
- All LiveView campaign UI (`GameLive`, `CampaignPrepLive`, `CharactersLive`, `DashboardLive`, `InviteLive`)

---

## State Struct: Field Boundary

`%Engine.State{}` has 24 fields. Current split:

**Generic (keep in engine State):**
`campaign_id`, `map_id`, `x_extent`, `y_extent`, `tile_size`, `grid_tiles`, `entities`, `turn_order`, `active_index`, `actor_id`, `valid_moves`, `valid_move_costs`, `ruleset`

**D&D-specific (move to `:ruleset_state`):**
`phase`, `previous_phase`, `active_effects`, `initiative_values`, `hidden_entities`, `session_log`, `open_container_id`, `awaiting_roll`, `pending_roll`, `pending_initiative_rolls`

`valid_targets` is borderline — the engine can compute "entities in range" generically, but what counts as a valid target depends on ruleset rules (line of sight, immunity, etc.). Keep in engine state, computed via ruleset callback.

**Proposed change:** Add `ruleset_state: term()` to `Engine.State`. Engine treats it as an opaque pass-through. Every ruleset callback receives the full `%State{}` and returns `{events, new_state}` where the ruleset is free to update `ruleset_state`. The engine never inspects `ruleset_state` fields directly.

This is the single highest-value structural change — it removes 10 fields from the engine struct without changing any external API.

---

## Reorganization Strategy

### Recommended: Umbrella Application

Convert the project to a Mix umbrella with four apps:

```
gibbering_umbrella/
  apps/
    gibbering_engine/        ← GibberingEngine — pure Elixir/OTP, no Phoenix dependency
                                OTP, SVG pipeline, generic events, ports, IsoProjection
                                Published to Hex.pm when the API stabilizes
    gibbering_tales/         ← GibberingTales — "The Gibbering Tales" pure Elixir core
                                D&D 5e ruleset, Data.*, Catalogue schemas, Accounts, Campaigns
                                No Phoenix dependency; shared by both web apps below
    gibbering_tales_web/     ← GibberingTalesWeb — player/DM Phoenix app
                                GameLive, LobbyLive, CampaignPrepLive, CharactersLive, etc.
                                Public-facing deployment
    gibbering_tales_admin/   ← GibberingTalesAdmin — support/moderation Phoenix app
                                Admin CRUD, LiveDashboard, support_users auth, audit log
                                Internal/VPN-only deployment
```

Dependency graph:
```
gibbering_tales_web   → gibbering_tales → gibbering_engine
gibbering_tales_admin → gibbering_tales → gibbering_engine
```

**Why umbrella over simple namespace reorganization:**
- Compile-time enforcement: `gibbering_engine` cannot import `gibbering_tales` — the dependency is strictly one-way
- `gibbering_tales` is the reference implementation; both web apps prove the seam is real
- Dependency graph is explicit in `mix.exs`
- Admin and game apps can be deployed and scaled independently

**External game developers:**
- They do not touch the umbrella; they depend on `{:gibbering_engine, "~> 1.0"}` from Hex.pm
- They implement their own web layer; `gibbering_tales_web` is the reference pattern
- Publish `gibbering_engine` to Hex when the API stabilizes (not yet — engine API still changes frequently)
- Umbrella gives separation without premature publication

### Migration path (incremental, no big-bang rewrite)

1. **Phase 0 — Namespace cleanup (complete ✓ 2026-06-30):**
   - Moved `Rulesets.DnD5e.RuleModifier` → `Engine.RuleModifier`
   - Moved generic events to `Events.Engine.*`, D&D events to `Events.DnD5e.*`
   - Added `@moduledoc` to all event structs stating layer, emitter, and signal

2. **Phase 1 — State boundary (complete ✓ 2026-07-01):**
   - Add `ruleset_state: term()` to `Engine.State`
   - Move D&D-specific fields out of State into a `%DnD5e.RulesetState{}` struct stored in `ruleset_state`
   - Update all SceneServer and Rules call sites

3. **Phase 2 — Umbrella conversion:**
   - `mix new gibbering_engine --module GibberingEngine` in `apps/`
   - `mix new gibbering_tales --module GibberingTales` in `apps/`
   - `mix phx.new gibbering_tales_web --module GibberingTalesWeb --no-ecto` in `apps/`
   - `mix phx.new gibbering_tales_admin --module GibberingTalesAdmin --no-ecto` in `apps/`
   - Move engine modules into `gibbering_engine`; move D&D ruleset + domain into `gibbering_tales`
   - Move `GibberingWeb.*` LiveViews into `gibbering_tales_web`; admin modules into `gibbering_tales_admin`
   - Move `IsoProjection` from `GibberingWeb` to `GibberingEngine` (pure math, no Phoenix dep)
   - Verify `gibbering_tales` compiles with only `gibbering_engine` as dependency

4. **Phase 3 — Toy game (concept proof):**
   - `apps/gibbering_duels/` — a simple 2-player card-placement game on a 5×5 grid
   - Implements `GibberingEngine.Ruleset` behaviour
   - Uses `GibberingEngine.SceneServer`, `EventBus`, `IsoProjection`
   - No D&D imports anywhere

### Toy game concept: `GibberingDuels`

A minimal card-placement game to concept-proof the engine:

- **Grid**: 5×5 tiles, two players
- **Entities**: "creature cards" placed on tiles; each has HP and one attack
- **Ruleset**: `GibberingDuels.Ruleset` — `@behaviour GibberingEngine.Ruleset`
  - No spell slots, no initiative rolls, no ability modifiers
  - Turn = place a card OR move a card OR attack adjacent card
  - Attack = attacker HP minus 1 from target (no dice if we want zero D&D)
- **Events**: Only generic engine events — `EntityMoved`, `HpAdjusted`, `TurnAdvanced`, `SessionEnded`
- **Rendering**: Same SpriteCompositor pipeline with custom card appearances

If the engine can host this without needing to import anything from `gibbering_tales`, the decomposition is clean.

---

## Appearance System: Vertical Slice (No Change Needed)

The appearance system is already correctly structured as a vertical:

```
Engine layer (generic):     SpriteCompositor  ←  AppearanceArchetype  ←  ConditionBadge
                                    ↓
Content layer (game-specific):  Catalogue.Appearance records  (keyed by content_key)
```

- `SpriteCompositor.compose(entity, appearances, opts)` receives game-specific appearance data but doesn't know what game it is
- The `appearances` map is built from `Catalogue.Cache`, which holds D&D content records
- In a card game, the same cache would hold card appearance records
- **No structural change needed** — just populate with different content

The one coupling to clean: `SpriteCompositor` currently calls `ConditionBadge.render_badges(entity.conditions, ...)` with D&D condition names. The fix: inject a `badge_renderer` function or make badge rendering optional via the appearances data. Tracked implicitly by the composable appearances work.

---

## Open Questions

- [ ] Does `Engine.Rules` movement cost (5 ft/tile) need to be a ruleset callback, or is a configurable tile cost sufficient?
- [ ] Phase machine: is the generic engine's phase model `{:lobby, :active, :paused, :ended}` with ruleset-defined sub-phases, or is it a fully custom state machine per ruleset?

## Resolved Questions

- [x] **Web layer placement:** `gibbering_engine` has no Phoenix dependency. The web layer lives in `gibbering_tales_web` (player/DM) and `gibbering_tales_admin` (admin), both separate Phoenix apps that depend on `gibbering_tales` for domain logic.
- [x] **Admin separation:** Admin app (`gibbering_tales_admin`) is a separate Phoenix deployment — different auth pipeline (`support_users`), internal/VPN-only exposure, independent release cadence.
- [x] **`IsoProjection` placement:** Moves to `gibbering_engine` — pure math module with no Phoenix dependency; the engine owns its projection geometry.

---

## Related Issues

- #156 Coordinate model formalization (prerequisite for clean engine geometry)
- #123 `Projection` behaviour: Isometric + TopDown modules
- #152 Action struct unification (shapes the ruleset callback API)
- #85 Content creation tools (shapes the content-layer ingestion pipeline)
- #113 CQRS projection formalization (shapes event namespacing)
