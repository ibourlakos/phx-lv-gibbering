# Data Model

Two distinct layers: **persistent** (PostgreSQL via Ecto) and **runtime** (in-memory structs inside the GameServer GenServer). A third layer of **static reference data** lives in pure Elixir modules — no DB, no process.

---

## Persistent Layer (PostgreSQL)

### `users`

Managed by `Gibbering.Accounts.User`.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `username` | string | unique, 3–20 chars, `[a-zA-Z0-9_]` |
| `password_hash` | string | pbkdf2-sha512 via `pbkdf2_elixir` |
| `inserted_at` / `updated_at` | naive_datetime | Ecto timestamps |

The `password` field is a virtual (cast-only) field; it never reaches the DB. DM role is campaign-scoped (`campaigns.dm_id`); support users live in a separate `support_users` table (issue [#65](issues/065-support-users-schema-and-auth.md)).

---

### `maps`

Managed by `Gibbering.GameMap`. One row per map (Phase 1: one map per campaign).

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `campaign_id` | integer FK → campaigns | cascade delete |
| `x_extent` | integer | tile columns (world-x axis, rotation-proof) |
| `y_extent` | integer | tile rows (world-y axis, rotation-proof) |
| `tile_size` | integer | pixels per tile (used by projection math) |
| `inserted_at` / `updated_at` | naive_datetime | |

Associations: `belongs_to :campaign, Campaign` · `has_many :tiles, GridTile, foreign_key: :map_id`

`z_extent` is reserved for a future vertical axis (not yet in schema).

---

### `campaigns`

Managed by `Gibbering.Campaign`.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `name` | string | |
| `status` | string | `"lobby"` \| `"active"` \| `"ended"` |
| `active_map_id` | integer FK → maps | nullable; the currently loaded map |
| `dm_id` | integer FK → users | nullable; the campaign's Dungeon Master |
| `inserted_at` / `updated_at` | naive_datetime | |

Associations: `belongs_to :dm, User` · `belongs_to :active_map, GameMap` · `has_many :maps, GameMap` · `has_many :entities, Entity` · `has_many :campaign_members, CampaignMember`

---

### `campaign_members`

Join table. Managed by `Gibbering.CampaignMember`. Context: `Gibbering.Campaigns`.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `campaign_id` | integer FK → campaigns | cascade delete |
| `user_id` | integer FK → users | cascade delete |
| `inserted_at` / `updated_at` | naive_datetime | |

Unique index on `(campaign_id, user_id)`. Index on `user_id` for membership lookups.

Membership gates access: `/lobby/:id` and `/game/:id` redirect non-members to `/`.

---

### `races`

Managed by `Gibbering.Catalogue.Race`. Primary key is `key` (string). Seeded from `Gibbering.Data.Races.seed_data/0`. Runtime reads go through `Gibbering.Catalogue.Cache`.

| Column | Type | Notes |
|---|---|---|
| `key` | string PK | e.g. `"human"`, `"elf"`, `"gnome"` |
| `name` | string | display name |
| `description` | text | |
| `speed` | integer | base movement speed in feet |
| `stat_bonuses` | JSONB map | `%{"strength" => 1, ...}` |
| `traits` | JSONB array of maps | racial trait objects `%{"name" => ..., "description" => ...}` |
| `darkvision` | boolean | |
| `inserted_at` / `updated_at` | naive_datetime | |

---

### `classes`

Managed by `Gibbering.Catalogue.Class`. Primary key is `key` (string). Seeded from `Gibbering.Data.Classes.seed_data/0`.

| Column | Type | Notes |
|---|---|---|
| `key` | string PK | e.g. `"fighter"`, `"wizard"`, `"rogue"` |
| `name` | string | |
| `description` | text | |
| `hit_die` | string | e.g. `"d10"` |
| `base_hp` | integer | HP at level 1 |
| `primary_stats` | `string[]` | |
| `saving_throws` | `string[]` | |
| `armor_proficiencies` | `string[]` | |
| `weapon_proficiencies` | `string[]` | |
| `spellcasting` | boolean | |
| `spells` | `string[]` | default spell keys for spellcasting classes |
| `features` | JSONB array of maps | class feature objects |
| `stats` | JSONB map | default stat block |
| `inserted_at` / `updated_at` | naive_datetime | |

---

### `spells`

Managed by `Gibbering.Catalogue.Spell`. Primary key is `key` (string). Seeded from `Gibbering.Data.Spells.seed_data/0`.

| Column | Type | Notes |
|---|---|---|
| `key` | string PK | e.g. `"fire_bolt"`, `"magic_missile"` |
| `name` | string | |
| `level` | integer | 0 = cantrip |
| `school` | string | e.g. `"evocation"`, `"illusion"` |
| `casting_time` | string | e.g. `"1 action"` |
| `range` | string | numeric feet `"120"`, or named `"touch"`, `"cone_15"`, `"cube_15"` |
| `description` | text | |
| `damage_dice` | string | nullable — e.g. `"1d10"`, `"3d6"` |
| `damage_type` | string | nullable — SRD type string e.g. `"fire"` |
| `attack_type` | string | nullable — `"ranged"`, `"save"`, `"aoe"`, `"auto"`, `"touch"`, `"utility"` |
| `save` | string | nullable — saving throw stat e.g. `"dexterity"` |
| `tags` | `string[]` | e.g. `["offensive", "aoe"]` |
| `inserted_at` / `updated_at` | naive_datetime | |

---

### `monsters`

Managed by `Gibbering.Catalogue.Monster`. Primary key is `key` (string = Open5e slug). Populated by `mix gibbering.ingest` (Open5e API, CC-BY-4.0). Runtime reads via `Gibbering.Catalogue.Cache`.

| Column | Type | Notes |
|---|---|---|
| `key` | string PK | Open5e slug e.g. `"goblin"`, `"ancient-red-dragon"` |
| `name` | string | |
| `size` | string | `"Tiny"` \| `"Small"` \| `"Medium"` \| `"Large"` \| `"Huge"` \| `"Gargantuan"` |
| `monster_type` | string | `"aberration"`, `"beast"`, `"humanoid"`, etc. |
| `alignment` | string | |
| `armor_class` | integer | |
| `hit_points` | integer | average HP |
| `hit_dice` | string | e.g. `"2d6"` |
| `speed` | JSONB map | `%{"walk" => "30 ft.", "swim" => "40 ft."}` |
| `strength` … `charisma` | integer | ability scores |
| `challenge_rating` | string | `"1/4"`, `"1"`, `"10"` etc. |
| `xp_reward` | integer | XP on defeat |
| `source_license` | string | `"CC-BY-4.0"` |
| `stat_block` | JSONB map | saving throws, skills, damage tags, actions, special abilities |
| `inserted_at` / `updated_at` | naive_datetime | |

Indexes on `monster_type` and `challenge_rating` for encounter-building queries.

---

### `grid_tiles`

Managed by `Gibbering.GridTile`. One row per tile cell.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `x` | integer | grid column |
| `y` | integer | grid row |
| `texture` | string | `"grass"` \| `"stone"` |
| `walkable` | boolean | |
| `decoration` | string | nullable — `"dead_tree"` \| `"rock_cluster"` \| `"bones"` \| `"grass_tuft"` |
| `map_id` | integer FK → maps | cascade delete |

No timestamps (bulk-inserted via `Repo.insert_all`). See issue #130 for the planned migration from `walkable` to a JSONB `movement` map for multi-mode movement (walk/climb/swim/fly).

---

### `entities`

Managed by `Gibbering.Entity`. Stores both player characters and map objects.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `name` | string | display name |
| `type` | string | `"hero"` \| `"monster"` \| `"object"` |
| `sprite` | string | key dispatched to SVG sprite component, e.g. `"elf_wizard"`, `"rock"` |
| `race` | string | `"human"` \| `"elf"` \| `"gnome"` — for heroes |
| `class` | string | `"fighter"` \| `"wizard"` \| `"rogue"` — for heroes |
| `x` | integer | grid column |
| `y` | integer | grid row |
| `hp` | integer | current hit points |
| `max_hp` | integer | maximum hit points |
| `tags` | `string[]` | e.g. `["player_controlled"]`, `["destructible", "blocking"]` |
| `stats` | JSONB map | flexible stat bag (see below) |
| `campaign_id` | integer FK → campaigns | |
| `inserted_at` / `updated_at` | naive_datetime | |

#### `stats` JSONB — known keys

The `stats` map is intentionally schemaless so any ruleset can store what it needs. Current D&D 5e keys:

| Key | Type | Set by |
|---|---|---|
| `"strength"` | integer | lobby save_slot |
| `"dexterity"` | integer | lobby save_slot |
| `"constitution"` | integer | lobby save_slot |
| `"intelligence"` | integer | lobby save_slot |
| `"wisdom"` | integer | lobby save_slot |
| `"charisma"` | integer | lobby save_slot |
| `"speed"` | integer | lobby save_slot (from race) |
| `"spells"` | `string[]` | lobby save_slot (wizards only) — spell key list |
| `"claimed_by"` | integer (user id) | lobby claim_slot |
| `"claimed_by_name"` | string | lobby claim_slot |
| `"equipped_weapon"` / `"equipped_armor"` | JSONB map | lobby save_slot (see tactical item model below) |
| `"inventory"` | JSONB array of item instances | creature carried items (`"hero"`, `"monster"`) — see WorldObject & inventory below |
| `"object_subtype"` | string | `"object"` entities only: `"loot_source"` \| `"static_decor"` |
| `"items"` | JSONB array of item instances | loot-source containers — items available to take |

---

## Runtime Layer (SceneServer in-memory)

`Gibbering.Engine.SceneServer` (planned rename of `GameServer` — see issue #36) holds one
`%Gibbering.Engine.State{}` struct per running scene, keyed by `campaign_id` in a `Registry`.

### `%Gibbering.Engine.State{}`

Hydrated from the DB on `SceneServer.init/1` via `State.from_campaign/1`. **Not persisted back to DB between turns** (see open issue #12).

#### Structural fields (current)

| Field | Type | Notes |
|---|---|---|
| `campaign_id` | integer | DB campaign id |
| `map_id` | integer | DB map id (active map) |
| `x_extent` | integer | tile columns (world-x axis) |
| `y_extent` | integer | tile rows (world-y axis) |
| `tile_size` | integer | pixels per tile |
| `grid_tiles` | `%{{x,y} => tile_map}` | keyed by `{x, y}` integer tuples |
| `entities` | `%{id => entity_map}` | keyed by entity DB id |
| `selected_id` | integer \| nil | currently selected entity |
| `valid_moves` | `[{x, y}]` | pre-computed move options for selected entity |
| `turn_order` | `[integer]` | hero entity ids in sequence |
| `active_index` | integer | index into `turn_order` |

#### Planned additions (issues #36, #37)

| Field | Type | Notes |
|---|---|---|
| `phase` | `scene_phase()` | `:lobby \| :exploration \| :initiative_rolling \| :in_combat \| :paused` |
| `previous_phase` | `scene_phase() \| nil` | restored on `:paused → <previous>` transition |
| `active_effects` | `[active_effect()]` | scene-level effects registry — all conditions, buffs, ability states |
| `event_log` | `[event()]` | append-only; structural dependency for predicate evaluation |

#### Runtime tile map shape

```elixir
%{texture: "grass", walkable: true, decoration: "dead_tree" | nil}
```

#### Runtime entity map shape (current)

```elixir
%{
  name: string,
  type: "hero" | "monster" | "object",
  sprite: string,
  race: string,
  class: string,
  x: integer,
  y: integer,
  hp: integer,
  max_hp: integer,
  tags: [string],
  stats: map()        # same keys as DB stats JSONB
}
```

#### Runtime entity map — planned extensions (issue #37)

```elixir
%{
  # ... existing fields above ...
  level: integer,
  temp_hp: integer,
  ability_modifiers: %{string() => integer()},   # pre-computed at hydration
  proficiency_bonus: integer,
  armor_class: integer,
  resources: %{
    spell_slots: %{integer() => integer()},   # level => remaining
    # class-specific: second_wind, action_surge, ki_points, rage_charges, …
  },
  conditions: [condition_ref()],             # projected from scene active_effects registry
  action_economy: %{
    action:            :available | :spent,
    bonus_action:      :available | :spent,
    reaction:          :available | :spent,
    movement_remaining: integer()
  }
}
```

Atom keys for structural fields, string keys inside `stats` (inherited from DB JSONB decode).
This asymmetry is intentional — structural fields are accessed hot by the engine via atom-key
pattern matching; stats are arbitrary ruleset data accessed by string key.

---

## Static Reference Data (in-memory, no DB)

These modules define constant D&D 5e data. Current modules are consulted only during lobby
character setup. Planned modules (`RuleModifier`, `Condition`, `Spell`) will be queried by the
rules engine at resolution time.

### `Gibbering.Data.Races`

Key: string (`"human"` / `"elf"` / `"gnome"`). Value shape:

```elixir
%{
  name: string,
  description: string,
  speed: integer,
  stat_bonuses: %{ability => integer},
  traits: [%{name: string, description: string}],
  darkvision: boolean
}
```

### `Gibbering.Data.Classes`

Key: string (`"fighter"` / `"wizard"` / `"rogue"`). Value shape:

```elixir
%{
  name: string,
  description: string,
  hit_die: string,        # e.g. "d10"
  base_hp: integer,
  stats: %{ability => integer},
  spellcasting: boolean,
  spells: [string],       # spell keys; empty for non-casters
  features: [%{name: string, description: string}]
}
```

### `Gibbering.Data.Spells`

Key: atom (e.g. `:fire_bolt`, `:magic_missile`). Value shape:

```elixir
%{
  name: string,
  level: integer,         # 0 = cantrip
  school: string,
  casting_time: string,
  range: string,
  damage_dice: string | nil,
  damage_type: string | nil,
  attack_type: string,    # "ranged_spell" | "melee_spell" | "saving_throw" | "utility"
  save: string | nil,     # ability for saving throw, e.g. "wisdom"
  tags: [atom]
}
```

See issue #41 for the planned migration to `%Gibbering.Rulesets.DnD5e.Spell{}` struct below.

---

### Planned: `Gibbering.Rulesets.DnD5e.Spell` (issue #41)

Replaces the flat map in `Data.Spells`:

```elixir
defstruct [:key, :name, :level, :school, :casting_time, :range, :components,
           :duration, :target_area, :effect, :tags]
# casting_time: {:action} | {:bonus_action} | {:reaction, trigger_pred} | {:minutes, n}
# components:   %{verbal: bool, somatic: bool, material: bool, material_desc: string | nil}
# duration:     %{type: :instantaneous | {:rounds, n} | {:minutes, n}, is_concentration: bool}
# target_area:  %{shape: :single | :cone | :cube | :sphere | :line, size_feet: integer | nil}
# effect:       %{type: :damage | :healing | :condition | :utility, ...}
```

---

### Planned: `Gibbering.Rulesets.DnD5e.RuleModifier` (issue #40)

The engine's rule representation — no DB, pure Elixir data:

```elixir
defstruct [:id, :name, :description, :source, :trigger, :predicate, :effect,
           stacking: :additive, min_level: 1]
# trigger:    {:on_attack, :melee | :ranged | :any} | {:passive} | {:on_damage_received, type}
#             | {:on_saving_throw, ability} | {:on_condition_applied, cond} | {:on_being_attacked}
# predicate:  closed-vocabulary expression — see docs/architecture/predicate-vocabulary.md
# effect:     {:add_damage_dice, "1d6", :any} | {:grant_advantage, :attack_rolls}
#             | {:set_speed, 0} | {:grant_resistance} | {:add_bonus, :ac, n}
#             | {:override_ac_formula, formula} | {:force_critical_hit}
# stacking:   :additive | :named_bonus | :binary_flag
```

Pipeline: `collect_modifiers(entity, trigger, context)` → `[%RuleModifier{}]` from race traits +
class features + active conditions. `apply_modifiers(roll_context, modifiers)` folds each
effect in layering order. No `if entity.class == "rogue"` branches in the rules engine.

---

### Planned: `Gibbering.Rulesets.DnD5e.Condition` (issue #42)

Static definition of every SRD condition — no DB:

```elixir
defstruct [:id, :name, :description, :modifiers]
# modifiers: [%RuleModifier{}]
# Example — Paralyzed:
#   modifiers: [
#     %RuleModifier{trigger: :passive,           effect: {:set_speed, 0}},
#     %RuleModifier{trigger: :on_being_attacked, predicate: {:entity_adjacent_to_target},
#                   effect: {:force_critical_hit}},
#     %RuleModifier{trigger: :passive,           effect: {:grant_disadvantage, :attack_rolls}},
#     %RuleModifier{trigger: :passive,           effect: {:grant_disadvantage, :ability_checks}}
#   ]
```

Conditions are applied as `ActiveEffect` entries in the scene registry; the `Condition` module
is the static definition consulted when building those entries.

---

### Planned: `Gibbering.Rulesets.DnD5e.Stats` (issue #38)

Pure stat computation — no DB, no process:

```elixir
def ability_modifier(score),      do: Integer.floor_div(score - 10, 2)
def proficiency_bonus(level),     do: div(level - 1, 4) + 2
def spell_dc(entity),             do: 8 + proficiency_bonus(entity.level) + spellcasting_modifier(entity)
def armor_class(entity),          do: # reads stats["equipped_armor"] or defaults 10 + dex_mod
def attack_bonus(entity, type),   do: # proficiency_bonus + relevant ability modifier
def initial_resources(entity),    do: # builds resources map from class + level
```

Called by `State.from_campaign/1` to hydrate `ability_modifiers`, `proficiency_bonus`,
`armor_class` onto each entity map at session start.

---

### Tactical item model in `stats` JSONB (issue #46)

Full inventory is deferred. Equipped weapon and armor live in the `stats` JSONB map:

```elixir
"equipped_weapon" => %{
  "key"           => "longsword",
  "damage_dice"   => "1d8",
  "damage_type"   => "slashing",
  "attack_ability"=> "strength",
  "properties"    => ["versatile"]
},
"equipped_armor" => %{
  "key"           => "chain_mail",
  "base_ac"       => 16,
  "armor_category"=> "heavy",
  "stealth_disadv"=> true
}
```

`DnD5e.Stats.armor_class/1` reads these keys. Forward-compatible: replace with a proper
Ecto schema when full inventory is needed.

---

### WorldObject & inventory model (issues #80, #126)

Items exist in two contexts, both stored as **item-instance lists** inside `stats` JSONB —
no separate items table. Helpers and read accessors live in `Gibbering.Rulesets.DnD5e.Inventory`.

**Item instance shape** (uniform for both contexts):

```elixir
%{
  "instance_id" => "9f1c…",   # UUID — distinguishes otherwise-identical stacks/uniques
  "item_key"    => "shortsword", # key into Gibbering.Data.Items
  "quantity"    => 1
}
```

**Possession (creatures).** `"hero"` and `"monster"` entities carry `stats["inventory"]`
(empty list `[]` initially). Equipped items still live in `stats["equipped_weapon"]` /
`stats["equipped_armor"]` and inject mechanics via the rules pipeline (#128).

**Spatial (world objects).** `type: "object"` entities are the on-grid object variant — no
separate spatial layer. The sub-type lives in `stats["object_subtype"]`:

| `object_subtype` | Meaning | Inventory |
|---|---|---|
| `"loot_source"` | A container a player can open and ransack | `stats["items"]` holds takeable instances (`[]` when empty) |
| `"static_decor"` | Purely visual / obstacle | none |

**Canonical world-object tags.** Spatial flags live in `tags`, following the existing
`["blocking"]` / `["destructible"]` convention:

| Tag | Meaning |
|---|---|
| `"interactable"` | Players can target the object with an interact action (open, search) |
| `"passable"` | The object does not block movement (entities may enter its tile) |

Stack-merge on pickup and equipped-item stat injection are handled by the pickup event
loop (#127) and the `:equipped_items` modifier source (#128) respectively.

---

### `Gibbering.Ruleset` behaviour (issue #39, closes #14)

All `DnD5e.*` modules live under `Gibbering.Rulesets.DnD5e.*` and the top-level module
implements the `Gibbering.Ruleset` behaviour, providing a single entry point for the engine:

```elixir
@callback collect_modifiers(entity_map(), trigger(), eval_context()) :: [RuleModifier.t()]
@callback initial_resources(entity_map()) :: resources_map()
@callback initial_action_economy(entity_map()) :: action_economy_map()
@callback advance_turn(State.t()) :: State.t()
```

---

## Layer Relationships

```
users
  ├── campaign_members ──→ campaigns ──→ maps ──→ grid_tiles   (one row per tile cell)
  │                            └── entities                    (heroes, monsters, objects)
  └── (dm_id on campaigns)
                             campaigns.active_map_id ──→ maps

                campaigns (preloaded with active_map: :tiles)
                    │
              State.from_campaign/1
                    │
                    ▼
          %Engine.State{}            ← held by SceneServer (one per campaign)
          ├── campaign_id / map_id   (DB references)
          ├── x_extent / y_extent / tile_size  (from active map)
          ├── phase                  (scene phase state machine)
          ├── grid_tiles map         (atom-keyed, {x,y} tuple keys)
          ├── entities map           (atom-keyed structural + string stats + planned extensions)
          ├── active_effects         (scene-level registry — conditions, buffs, ability states)
          └── event_log              (append-only; predicate evaluator structural dep)

Static reference data (pure Elixir modules, no DB, no process):
  Gibbering.Data.{Races, Classes, Spells}           ← lobby use only (current)
  Gibbering.Rulesets.DnD5e.{Stats, Spell,
    RuleModifier, Condition}                         ← planned; engine queries at resolution time
```

---

## Known Gaps / Open Issues

| Issue | Gap |
|---|---|
| [#12](issues/012-persistence-strategy.md) | `Engine.State` never written back to DB — SceneServer restart resets all positions and HP |
| [#19](issues/019-lobby-edits-stale-gameserver.md) | Lobby edits persist to DB but a running SceneServer holds a stale snapshot |
| [#24](issues/024-grid-data-jsonb.md) | `grid_tiles` uses one row per cell; planned migration to JSONB on `campaigns` |
| [#35](issues/035-entity-schema-level-temp-hp.md) | `entities` table missing `level`, `temp_hp`, `challenge_rating`, `xp_reward` columns |
| [#36](issues/036-scene-phase-state-machine.md) | `GameServer` has no phase field; no scene state machine; rename to `SceneServer` |
| [#37](issues/037-runtime-entity-map-extensions.md) | Runtime entity map missing `action_economy`, `resources`, `conditions` extensions |
| [#38](issues/038-dnd5e-stats-module.md) | No derived stat computation (`ability_modifier`, `proficiency_bonus`, `armor_class`) |
| [#39](issues/039-ruleset-behaviour.md) | No `Gibbering.Ruleset` behaviour; rules engine is not ruleset-swappable (see #14) |
| [#40](issues/040-rule-modifier-predicate-evaluator.md) | No `RuleModifier` struct or predicate evaluator — rules hardcoded in `Rules` module |
| [#41](issues/041-spell-struct.md) | `Data.Spells` is a flat map; no `%Spell{}` struct with structured fields |
| [#42](issues/042-condition-struct.md) | No `%Condition{}` struct; conditions not applied to entities at runtime |
| [#43](issues/043-action-economy-tracking.md) | No action economy tracking; no `advance_turn` reset |
| [#44](issues/044-spell-slots-resource-pools.md) | No spell slot or class resource tracking |
| [#45](issues/045-attack-roll-vs-ac.md) | `Rules.attack/3` rolls 1d6 with no attack roll, no AC check, no modifiers |
| [#46](issues/046-equipped-item-jsonb.md) | No equipped weapon/armor in `stats` JSONB; no seed data |
| [#47](issues/047-migrate-features-to-rule-modifiers.md) | `Data.Classes`/`Data.Races` features are inert text; not migrated to `%RuleModifier{}` |
| [#48](issues/048-saving-throw-pipeline.md) | No saving throw pipeline; AoE and save-based spells cannot be resolved |
