# Player Character Creation

**Topic:** Design and implementation of character creation — allowing a player user to build D&D 5e characters and maintain a personal collection.

**Status:** exploration

---

## The Core Tension: Template vs. Instance

The most important design decision here is the **Template / Instance split**.

A character created by a player is a **roster character** — a persistent, player-owned record that lives independently of any campaign. When that character enters a campaign, the DM instantiates it as a **Campaign PC** — the live entity that participates in that specific story. The DM may adjust level, stats, items, and anything else at preparation time without altering the original template.

```
users
  └── characters (player-owned templates)
            │
            └── campaign_characters  ←  DM-adjusted instance per campaign
                        │
                        └── [live entity the engine operates on]
```

The `Character` is what the player builds and owns. The `CampaignCharacter` is what the DM tailors and deploys. The live entity is what the engine runs on in a scene.

---

## A. Appearance

**Fidelity target: Don't Starve Together.** Bold outlines, stylised proportions, expressive enough to distinguish race features, hair, and equipped gear at a glance — not photorealistic, not crude geometry.

The SVG sprite is assembled from ordered layers at render time. Two maps drive it: `appearance` (player-defined cosmetics, stored on the character) and `equipment` (derived from equipped items, not stored on appearance):

| Layer | Driven by |
|---|---|
| Body silhouette | `body_type` + armour class |
| Clothing / armour | equipped armour key |
| Arms + weapon | equipped weapon key |
| Head base | `head` (race-constrained) |
| Hair | `hair_style` + `hair_color` |
| Face | `skin_tone` + `eye_color` |
| Accessories | cloak, hat, misc |

Equipment is visible on the sprite — an armoured character looks different from an unarmoured one; a sword-wielder looks different from a staff-wielder. Race constrains valid head options (e.g. Elves must have pointed ears).

A fixed, named colour palette governs all fills — no free hex colours — to keep art coherent across the composable parts.

**Legal note:** all SVG paths must be original artwork — no raster assets, no third-party art (see [legal.md](../legal.md)).

---

## B. D&D 5e Character Sheet

### Core identity
- `name`
- `race` — reference to the race catalogue (Human, Elf, Gnome, Dwarf, …)
- `class` — reference to the class catalogue; array to support multi-classing
- `level` — default 1 at creation; DM overrides per campaign
- `alignment` — (LG, NG, CG, LN, TN, CN, LE, NE, CE)
- `background` — reference to the background catalogue (see section C)

### Ability scores
- The six: Strength, Dexterity, Constitution, Intelligence, Wisdom, Charisma
- Set by the player at creation (standard array, point buy, or rolled — method is a UI choice; the result is just six integers)
- Race bonuses are **applied at instantiation** to the Campaign PC, not baked into the template — this keeps the template portable

### Derived stats
- Not stored on the template — computed at hydration time from scores + race + class + level
- Ability modifiers, proficiency bonus, armour class, spell DC, attack bonuses

### Proficiencies
- Skill proficiencies (e.g. Athletics, Stealth)
- Saving throw proficiencies — driven by class
- Tool proficiencies — from background or class
- Languages

### Spells known
- Spellcasting classes: list of spell keys
- Non-casters: empty

### Personality (standard sheet fields)
- Personality traits, ideals, bonds, flaws — free text or chosen from background suggestions

---

## C. Extended Background and Life Events

### Backgrounds (BG3-style archetypes)

D&D 5e already has a **Background** concept (Acolyte, Criminal, Folk Hero, Noble, Sage, Soldier, …) that grants:
- 2 skill proficiencies
- Possibly tool proficiency or language
- Starting equipment package
- A narrative feature (flavour ability, no engine mechanics)
- Default suggestions for personality traits / ideals / bonds / flaws (player chooses or customises)

This becomes a `Backgrounds` catalogue module, parallel to `Races` and `Classes`:

```elixir
%{
  "acolyte" => %{
    name: "Acolyte",
    description: "...",
    skill_proficiencies: ["insight", "religion"],
    tool_proficiencies: [],
    languages: 2,           # player picks 2
    starting_equipment: ["holy_symbol", "prayer_book", "incense_x5",
                         "vestments", "common_clothes", "belt_pouch_15gp"],
    feature: %{name: "Shelter of the Faithful", description: "..."},
    suggested_traits: [...],
    suggested_ideals: [...],
    suggested_bonds: [...],
    suggested_flaws: [...]
  },
  ...
}
```

When a background is selected, its proficiencies merge with class proficiencies. Duplicates give the player a free replacement pick — the standard 5e rule.

### Life Events (semi-formal chronicle)

A lightweight, append-only list of structured events — narrative history without becoming a full story engine:

```elixir
[
  %{
    era:             "childhood",    # childhood | adolescence | young_adult | recent
    type:            "loss",         # loss | discovery | conflict | bond | achievement | wound
    title:           "The Night of the Fire",
    description:     "The village was raided. My family did not survive.",
    mechanical_note: nil             # optional DM flavour hook
  },
  ...
]
```

- No mechanical effect at creation time — narrative anchors for player and DM
- `mechanical_note` is a soft hook for DMs to attach flavour consequences (advantage in specific situations etc.) without requiring engine support
- Could evolve into a campaign event-sourcing chronicle later

### Relations

Relations are inherently **campaign-scoped** — who a character knows depends on the campaign's fiction. A character template may carry free-text fields like `origin_faction` or `known_npcs`, but structured bidirectional relations (rival, ally, family) belong on the `CampaignCharacter`, not the template. Defer the full relations system to campaign context.

---

## D. Initial Items

Starting equipment comes from three sources:

1. **Class starting equipment** — defined in the class catalogue (e.g. Fighter gets chain mail + a martial weapon choice)
2. **Background starting equipment** — defined in the background catalogue
3. **Player additions** — free-form items the player wants to include (DM can modify)

Each item entry has a catalogue key (for known items) or free-text name (for custom items), a source tag, and a quantity:

```elixir
[
  %{key: "chain_mail",     source: :class,      quantity: 1},
  %{key: "longsword",      source: :class,      quantity: 1},
  %{key: "common_clothes", source: :background, quantity: 1},
  %{key: "rations",        source: :player,     quantity: 5},
  %{key: nil, name: "Lucky coin", source: :player, quantity: 1}
]
```

**DM adjustability:** The DM works from a copy of this list on the `CampaignCharacter` — the template is untouched. At campaign instantiation the system resolves what is equipped from what is available.

---

## E & F. DM Adjustability and the Template/Instance Model

A `Character` is a **reusable template** — defined once, deployable to many campaigns. The DM's adjustments live on `CampaignCharacter` and never pollute the original.

### What the DM can adjust on a Campaign PC

| Field | Player sets on template | DM can override on instance |
|---|---|---|
| Name | ✓ | ✓ (e.g. in-world alias) |
| Level | default 1 | ✓ (campaign may start at level 5) |
| Ability scores | ✓ | ✓ (variant rules, rolled differently) |
| Race / Class | ✓ | read-only |
| Background | ✓ | ✓ |
| Starting items | ✓ | ✓ (full add/remove/replace) |
| Proficiencies | derived from class + bg | ✓ (add bonus proficiencies) |
| Life events | ✓ | ✓ (DM adds campaign-relevant history) |
| Relations | — | ✓ (campaign-scoped) |
| Appearance | ✓ | read-only (it's their avatar) |

### Multiple characters per campaign

A player may have more than one `CampaignCharacter` in a campaign — for ensemble play, character death and replacement, or campaigns that explicitly rotate the cast. Only a subset is *active* at any given time. `CampaignCharacter` carries an `active` flag that the DM controls.

### Ownership vs control

These are two distinct axes:

- **Owner** — the player who created the character template. Has full edit rights on the template and can see the character in their personal `/characters` roster.
- **Controller** — who is actively playing the character in the current session. Defaults to the owner. The DM can reassign control to any campaign member (e.g. to hand a sidekick or fallen PC to another player temporarily).

A non-owner controller gets **read-only access** to the full character sheet within the campaign context — stats, abilities, items, personality, life events — so they can play the character faithfully. They cannot edit the template. This view surfaces in the campaign UI, not in `/characters` (which stays the owner's personal roster only).

### Data shape sketch

```
Character (player-owned template)
  identity: name, race, class[], level, alignment, background
  ability scores: str, dex, con, int, wis, cha
  proficiencies: skills[], saving_throws[], tools[], languages[]
  spells_known: []
  personality: traits, ideals, bonds, flaws
  appearance: { body_type, head, hair_style, hair_color, skin_tone, eye_color }
  life_events: [{ era, type, title, description, mechanical_note }]
  starting_items: [{ key, name, source, quantity }]

CampaignCharacter (DM-adjusted instance)
  refs: campaign_id, character_id
  owner_id      — user who owns the template
  controller_id — user currently playing this character (DM-assignable; defaults to owner)
  active        — boolean; DM controls which characters are in play
  overrides (all nullable — nil means "use template value"):
    level, ability_scores, background, starting_items, bonus_proficiencies
  dm_life_events: []      — merged with template events at hydration
  campaign_relations: []  — campaign-scoped only
```

Access rules:
| Role | Character template | CampaignCharacter |
|---|---|---|
| Owner | full edit | full edit (own fields) |
| Controller (non-owner) | read-only (campaign view) | read-only |
| DM | read-only | full edit (overrides, active, controller assignment) |
| Spectator | — | — |

**Spectator:** a campaign member with no `CampaignCharacter` records. The model supports this naturally — a `campaign_member` without a character is simply an observer. They have read access to the game state but no in-game agency. Useful for friends who want to watch a session, or for a DM-assistant role in a large campaign.

At campaign start the engine merges `Character` + `CampaignCharacter` overrides (overrides win) to produce the live entity record. The data model design will follow from this shape — not the other way round.

---

## Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Appearance scope | Composable SVG appearance from the start — no flat sprite key placeholder |
| 2 | Ability score method | Standard array only for MVP; point buy as a follow-up issue |
| 3 | Multi-class at creation | Single class at creation; multi-class via level-up flow only |
| 4 | Background catalogue scope | Full mechanical effects (proficiency grants) from the start |
| 5 | `campaign_characters` vs extending `campaign_members` | Separate `campaign_characters` table — access control and character state stay decoupled |
| 6 | Character collection UI | `/characters` top-level route; creation via **multi-step modal** overlaid on the roster page (no separate `/characters/new` route) |
| 7 | Importing into a campaign | **Bidirectional:** player can request to bring a character (DM approves/rejects) **and** DM can invite a player (player accepts and selects which character to bring) |

---

## Issues Opened

All work items from this exploration have been filed:

| Issue | Title |
|---|---|
| [#49](../issues/049-backgrounds-catalogue-module.md) | Backgrounds catalogue module |
| [#50](../issues/050-character-schema-and-context.md) | Character schema and context |
| [#51](../issues/051-character-collection-liveview.md) | Character collection LiveView (`/characters`) |
| [#52](../issues/052-character-creation-modal.md) | Character creation multi-step modal |
| [#53](../issues/053-composable-svg-appearance-system.md) | Composable SVG appearance system |
| [#54](../issues/054-campaign-character-schema.md) | CampaignCharacter schema |
| [#55](../issues/055-bidirectional-campaign-joining.md) | Bidirectional campaign joining |
| [#56](../issues/056-character-template-merge-logic.md) | Character template → live entity merge logic |
| [#57](../issues/057-dm-character-adjustment-ui.md) | DM character adjustment UI |
| [#58](../issues/058-point-buy-ability-scores.md) | Point buy ability scores *(deferred)* |
| [#59](../issues/059-character-export-import.md) | Character export/import with versioning *(deferred)* |

The DST-fidelity sprite discussion also opened a rendering architecture thread — see brainstorm [#08](08-isometric-rendering-depth-viewport.md) for viewport zoom/pan, elevation, and volumetric effects.

**This document can be closed once brainstorm #08 is also closed.**
