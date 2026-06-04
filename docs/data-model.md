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
| `role` | string | `"player"` \| `"dm"` \| `"support"` |
| `inserted_at` / `updated_at` | naive_datetime | Ecto timestamps |

The `password` field is a virtual (cast-only) field; it never reaches the DB.

---

### `campaigns`

Managed by `Gibbering.Campaign`.

| Column | Type | Notes |
|---|---|---|
| `id` | serial | PK |
| `name` | string | |
| `map_width` | integer | tile columns |
| `map_height` | integer | tile rows |
| `tile_size` | integer | pixels per tile (used by projection math) |
| `dm_id` | integer FK → users | nullable; the campaign's Dungeon Master |
| `inserted_at` / `updated_at` | naive_datetime | |

Associations: `belongs_to :dm, User` · `has_many :tiles, GridTile` · `has_many :entities, Entity` · `has_many :campaign_members, CampaignMember`

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
| `campaign_id` | integer FK → campaigns | |

No timestamps (bulk-inserted via `Repo.insert_all`). See issue #24 for a planned migration to a single JSONB column on `campaigns`.

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

---

## Runtime Layer (GameServer in-memory)

`Gibbering.Engine.GameServer` holds one `%Gibbering.Engine.State{}` struct per running campaign, keyed by `campaign_id` in a `Registry`.

### `%Gibbering.Engine.State{}`

Hydrated from the DB on `GameServer.init/1` via `State.from_campaign/1`. **Not persisted back to DB between turns** (see open issue #12).

| Field | Type | Notes |
|---|---|---|
| `campaign_id` | integer | DB campaign id |
| `map_width` | integer | |
| `map_height` | integer | |
| `tile_size` | integer | |
| `grid_tiles` | `%{{x,y} => tile_map}` | keyed by `{x, y}` integer tuples |
| `entities` | `%{id => entity_map}` | keyed by entity DB id |
| `selected_id` | integer \| nil | currently selected entity |
| `valid_moves` | `[{x, y}]` | pre-computed move options for selected entity |
| `turn_order` | `[integer]` | hero entity ids in sequence |
| `active_index` | integer | index into `turn_order` |

#### Runtime tile map shape

```elixir
%{texture: "grass", walkable: true, decoration: "dead_tree" | nil}
```

#### Runtime entity map shape

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

Note: the runtime entity map uses **atom keys** for structural fields (`name`, `x`, `hp`, …) but **string keys** inside `stats` (inherited from the DB JSONB decode). This asymmetry is intentional — structural fields are accessed hot by the engine with atom key pattern matching; stats are accessed by string key as arbitrary ruleset data.

---

## Static Reference Data (in-memory, no DB)

These modules define constant D&D 5e data. They are consulted only during lobby character setup — the engine never calls them at game time.

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

---

## Layer Relationships

```
users
  ├── campaign_members ──→ campaigns
  │                            ├── grid_tiles       (one row per tile cell)
  │                            └── entities         (heroes, monsters, objects)
  └── (dm_id on campaigns)

                campaigns
                    │
              State.from_campaign/1
                    │
                    ▼
          %Engine.State{}          ← held by GameServer (one per campaign)
          ├── grid_tiles map       (atom-keyed, {x,y} tuple keys)
          └── entities map         (atom-keyed structural fields + string stats)
```

---

## Known Gaps / Open Issues

| Issue | Gap |
|---|---|
| [#12](../.issues/012-persistence-strategy.md) | Game state (`Engine.State`) is never written back to DB — a GameServer restart resets all positions and HP |
| [#19](../.issues/019-lobby-edits-stale-gameserver.md) | Lobby edits persist to DB entities but a running GameServer holds a stale snapshot |
| [#24](../.issues/024-grid-data-jsonb.md) | `grid_tiles` uses one row per cell; planned migration to a single JSONB column on `campaigns` |
