# Game Content Taxonomy

_Reference document extracted from brainstorm #11 and issue #88. Use this as the checklist
whenever a new content item of any type is added to the game._

---

## Content Types

| Type | Storage | Scene-rendered | Appearance slot? |
|---|---|---|---|
| Race | DB table (`races`) | No | No |
| Class | DB table (`classes`) | No | No |
| Background | DB table (planned) | No | No |
| Spell | DB table (`spells`) | No (effect only) | Future: `"effect"` |
| Active effect / condition | Elixir struct + DB enum | Visual overlay | Future: `"effect"` |
| Feat / ability | DB table (planned) | No | No |
| Item | DB table (planned) | Inventory icon | Future: `"item"` |
| Tile texture | `grid_tiles.texture` string | Yes | Yes — `"tile"` |
| Map decoration | `grid_tiles.decoration` string | Yes | Yes — `"decoration"` |
| Map object (interactive) | Entity row, `type: "object"` | Yes | Yes — `"entity"` |
| Monster | Entity row, `type: "monster"` | Yes | Yes — `"entity"` |
| Notable individual | Entity row, `type: "hero"` | Yes | Yes — `"entity"` |
| Visual effect | Transient (PubSub payload) | Yes (animation) | Future: `"effect"` |
| Appearance component | `appearances` table row | n/a — is the slot | n/a |

---

## Upsert Checklist by Type

For each content type below, ✓ the relevant layers when adding a new item.

### Race

| Layer | What to do |
|---|---|
| **Schema** | `races` table + `Race` schema — already exist |
| **Data module** | Add entry to `Gibbering.Data.Races.seed_data/0` |
| **Seed** | Picked up automatically by `priv/repo/seeds.exs` race loop |
| **Appearance** | None — race has no SVG representation |
| **UI surface** | Character creation race picker (dropdown or card); stat bonuses shown |
| **Rendering** | None |
| **Rules integration** | `stat_bonuses`, `speed`, `darkvision`, `traits` applied by `DnD5e.Stats` at character hydration |
| **Tests** | `Data.Races` unit test; character creation integration test |

### Class

| Layer | What to do |
|---|---|
| **Schema** | `classes` table + `Class` schema — already exist |
| **Data module** | Add entry to `Gibbering.Data.Classes.seed_data/0` |
| **Seed** | Picked up automatically by seeds loop |
| **Appearance** | None |
| **UI surface** | Character creation class picker; hit die, primary stats, spells shown |
| **Rendering** | None |
| **Rules integration** | `hit_die`, `base_hp`, `primary_stats`, `saving_throws`, `spells`, `features` applied at hydration and combat |
| **Tests** | `Data.Classes` unit test; check derived HP and spell list in character merge test |

### Background

| Layer | What to do |
|---|---|
| **Schema** | `backgrounds` table + schema — **not yet implemented** (#49, deferred) |
| **Data module** | `Gibbering.Data.Backgrounds` — **not yet implemented** |
| **Seed** | Add to seeds loop once schema exists |
| **Appearance** | None |
| **UI surface** | Character creation background picker; skill proficiencies + feature shown |
| **Rules integration** | Skill proficiencies, tool proficiencies, starting equipment applied at hydration |
| **Tests** | `Data.Backgrounds` unit test |

### Spell

| Layer | What to do |
|---|---|
| **Schema** | `spells` table + `Spell` schema — already exist |
| **Data module** | Add entry to `Gibbering.Data.Spells.seed_data/0` |
| **Seed** | Picked up automatically |
| **Appearance** | None now; future `"effect"` slot for cast animation |
| **UI surface** | Spell action bar (class spell list); targeting overlay on cast |
| **Rules integration** | `damage_dice`, `attack_type`, `save` wired into `Rules.cast_spell/3` |
| **Tests** | `Data.Spells` unit test; cast_spell rules integration test |

### Active Effect / Condition

| Layer | What to do |
|---|---|
| **Schema** | `Gibbering.Rulesets.DnD5e.Condition` Elixir module — exists; no DB table (enum-backed) |
| **Data module** | Add atom + struct to `Condition.all/0` |
| **Seed** | None |
| **Appearance** | Future `"effect"` appearance slot: tint color, icon key, animation params |
| **UI surface** | DM condition panel (already exists); entity condition badge on sprite |
| **Rendering** | Compositor `:conditions` layer (planned in SpriteCompositor) |
| **Rules integration** | Predicate evaluated by `RuleModifier` pipeline; applied by `SceneServer.dm_apply_condition/3` |
| **Tests** | Condition unit test; rule modifier integration test |

### Feat / Ability

| Layer | What to do |
|---|---|
| **Schema** | No table yet — tracked as `features` JSONB on `classes` |
| **Data module** | Expressed as `%RuleModifier{}` entries in class `features` list |
| **Seed** | Covered by class seed data |
| **Appearance** | None (passive modifier — no visual) |
| **UI surface** | Character sheet (future); feat list at level-up (future) |
| **Rules integration** | `RuleModifier` pipeline; applies passive bonuses at hydration or trigger bonuses in combat |
| **Tests** | Rule modifier unit tests |

### Item (Weapon / Armor / Consumable / Clothing)

| Layer | What to do |
|---|---|
| **Schema** | No `items` table yet — stored as JSONB in `entity.stats["equipped_weapon"]` / `stats["equipped_armor"]` (#79, closed) |
| **Data module** | `Gibbering.Data.Items` — exists (#79 closed); add new item entry |
| **Seed** | No standalone seed; items seed via entity `stats` JSONB |
| **Appearance** | Future `"item"` appearance slot: icon SVG key, style-specific color palette |
| **UI surface** | Inventory panel (future #80); equipment slot in character sheet |
| **Rendering** | Future: item sprite overlay on entity in scene |
| **Rules integration** | `attack_ability`, `damage_dice`, `base_ac`, `armor_category` used by `DnD5e.Stats` and `Rules.attack/3` |
| **Tests** | `Data.Items` unit test; attack roll integration test |

### Tile Texture

| Layer | What to do |
|---|---|
| **Schema** | `grid_tiles.texture` string column — exists |
| **Data module** | No module; texture key is a free string on `GridTile` |
| **Seed** | Add tile rows with the new texture key in campaign seed data |
| **Appearance** | **Required** — add `appearances` row: `content_type: "tile"`, `content_key: "<key>"`, `data: %{"fill" => ..., "stroke" => ...}` for each active style |
| **UI surface** | DM map editor (future #85); tile picker palette |
| **Rendering** | `tile_fill/2` + `tile_stroke/2` in `GameLive` — already style-aware |
| **Rules integration** | `walkable` boolean drives movement validation |
| **Tests** | Appearance DB record test; `tile_fill` fallback test |

### Map Decoration

| Layer | What to do |
|---|---|
| **Schema** | `grid_tiles.decoration` nullable string — exists |
| **Data module** | No module; decoration key is a free string |
| **Seed** | Set `decoration: "<key>"` on relevant tile rows |
| **Appearance** | Future `"decoration"` appearance slot: style-specific color palette; currently hardcoded SVG colors in `decoration_sprite` components |
| **UI surface** | DM map editor decoration picker |
| **Rendering** | Add `decoration_sprite` clause for the new key in `GameLive` (or compositor layer once #27 is resolved) |
| **Rules integration** | None (cosmetic) |
| **Tests** | Visual regression (future); no unit test required for static SVG |

### Map Object (Interactive: door, box, chest)

| Layer | What to do |
|---|---|
| **Schema** | `entities` table, `type: "object"` — exists |
| **Data module** | No module; objects are entity rows seeded directly |
| **Seed** | `Repo.insert!(%Entity{type: "object", sprite: "<key>", ...})` in campaign seed |
| **Appearance** | `"entity"` appearance slot: `body_color` (and future shape params) |
| **UI surface** | Entity list panel (already renders objects); DM per-entity controls |
| **Rendering** | Add `entity_sprite` clause for the new sprite key; compositor HP bar applies if `max_hp > 0` |
| **Rules integration** | `tags: ["blocking"]` for collision; `tags: ["destructible"]` for HP-based destruction |
| **Tests** | Entity rules test (walkable check, destruction) |

### Monster

| Layer | What to do |
|---|---|
| **Schema** | `entities` table, `type: "monster"` — exists |
| **Data module** | No module; monsters are entity rows seeded or created via DM tools |
| **Seed** | `Repo.insert!(%Entity{type: "monster", sprite: "<key>", challenge_rating: ..., xp_reward: ...})` |
| **Appearance** | `"entity"` appearance slot: `body_color`; future sprite shape params |
| **UI surface** | Entity list (exists); DM HP override panel (exists) |
| **Rendering** | Add `entity_sprite` clause; compositor HP bar and selection ring apply automatically |
| **Rules integration** | `stats` map carries speed, ability scores, AC, weapon; all resolved by existing `DnD5e.Stats` and `Rules` modules |
| **Tests** | Attack roll test against new monster AC; XP award test |

### Notable Individual (named NPC)

Identical checklist to Monster. Use `type: "hero"` if the individual is player-controllable, `type: "monster"` otherwise. The distinction is purely in `tags` and `controller_id` on `CampaignCharacter`.

### Visual Effect (spell cast, area overlay)

| Layer | What to do |
|---|---|
| **Schema** | No DB table — effects are transient PubSub payloads |
| **Data module** | No module — effect parameters defined at call site |
| **Seed** | None |
| **Appearance** | Future `"effect"` appearance slot: animation type, color, duration |
| **UI surface** | Triggered by `push_event/3` → JS hook (DiceRoll hook pattern) |
| **Rendering** | JS hook animates the SVG; hook reads appearance data sent in the event payload |
| **Rules integration** | Triggered by `Rules.cast_spell/3`; no persistent state |
| **Tests** | LiveView event test asserting `push_event` payload |

---

## Multi-Style Appearance Slot

Resolved by issue #99 (closed). Summary for reference:

**Table:** `appearances (id, style_id FK, content_type text, content_key text, data JSONB)`  
**Unique constraint:** `(style_id, content_type, content_key)`  
**Access pattern:** `Catalogue.appearances_for_style/1` returns `%{{type, key} => data_map}` keyed by tuple.

### Active `content_type` values

| `content_type` | `content_key` example | Required `data` fields | Status |
|---|---|---|---|
| `"tile"` | `"grass"`, `"stone"` | `fill`, `stroke` | Implemented |
| `"entity"` | `"human_fighter"`, `"goblin"` | `body_color`, `anchor_x`\*, `anchor_y`\* | Implemented |
| `"decoration"` | `"dead_tree"`, `"bones"` | `fill`, `stroke` | Planned (#27) |
| `"effect"` | `"fire_bolt_impact"`, `"sleep_aura"` | `color`, `duration_ms`, `animation` | Future |
| `"item"` | `"longsword"`, `"health_potion"` | `icon_key`, `tint` | Future |

\* `anchor_x`/`anchor_y` default to 0 when absent; style-specific bounding box offsets.

### Content types with NO appearance slot

Races, classes, backgrounds, spells, feats — these are data records, not scene visuals.
Their appearance (if any) is mediated through the entity or effect that references them.

---

## Open Questions — Resolved or Deferred

| Question | Resolution |
|---|---|
| Are characters campaign-scoped or portable? | Portable templates (`characters` table); campaign-scoped via `CampaignCharacter` (#54, closed) |
| Exact appearance component schema | `(style_id, content_type, content_key, data JSONB)` (#99, closed) |
| Player/DM interface for new abilities | Deferred to character creation UI (#52, closed for modal shell) and future level-up flow |
| What does a "content slot" look like? | Defined above — appearance slot is the row in `appearances` keyed by type+key |
| Subclasses — separate table or JSONB on class? | Deferred; express as class features (`features` JSONB array) until a subclass picker is needed |
| Interactive object state (open/closed door) | Deferred to #80 (inventory/loot); use entity `stats` JSONB for state fields in the interim |
