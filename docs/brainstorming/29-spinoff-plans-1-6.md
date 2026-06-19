# #29 · Spinoff Game Mode Concepts — Plans 1–6

## Context

Exploratory session mapping six distinct alternative game modes that could be built on top of the
Gibbering Engine (isometric SVG grid, D&D 5e ruleset, Active Effect cascades, event sourcing,
CQRS projections, Phoenix PubSub). None of these are committed directions — the session established
a design-space map and identified which plans have the lowest architectural friction.

Cross-reference: see brainstorm [#30](30-spinoff-plan-7-expedition-chronicle.md) for a seventh
plan that synthesises several ideas from this session.

---

## Plan 1 — The Autobattler (GIB-AutoDungeon)

**Core concept:** Simultaneous tick-based autobattler where players act as Tacticians (not hero
controllers) and watch D&D mechanics play out in real time.

| Mechanic | Detail |
|---|---|
| Action Speed | Cooldown ticks; DEX + weapon speed determine tick rate |
| Movement | Auto-pathfinding to nearest enemy with flanking logic |
| AI | Threat-weighted priority matrix (low HP, AoE value, positioning) |
| Reactions | Trigger events on the bus (e.g. "When ally targeted, use Protection") |
| DM role | "Gauntlet Architect" — builds dungeon flowcharts with AI personalities; Override Tokens for live difficulty adjustment |
| Synergy | Class/Race adjacency bonuses |
| Progression | Shared War Chest (XP/Gold pool); permanent injury scars |

**New engine needs:**
- `GameMode` context (`:tabletop` vs `:autobattle`)
- `AI.Behaviour` module with personality variants (Zerg, Caster, Support)
- Cooldown timing model replacing turn-based initiative
- Batch emission for 10× speed simulation
- Replay scrubber via event store

---

## Plan 2 — The Darkest Dungeon (Gibbering Gauntlet)

**Core concept:** Attritional dungeon crawl with roster management and stress mechanics. Players
are "Reluctant Quartermasters" managing 15+ mercenaries through a branching dungeon.

| Mechanic | Detail |
|---|---|
| Hub | Hamlet — upgrade facilities, buy provisions, manage roster |
| Map | Room graph; corridors with Curios |
| Combat renderer | Side-view 2×4 rank layout (not isometric) |
| Stress | D&D Exhaustion + Madness meter (0–100); triggers Affliction/Virtue at ≥100 |
| Torchlight | Global variable (0–100) affecting monster crit chance and loot quality |
| Progression | Permanent death; Quirks (positive/negative traits) persist on heroes |
| DM role | "The Ancestor" — narrator; designs corridors, triggers Curios |

**New engine needs:**
- `SVG.RankStrategy` renderer (replaces isometric for combat)
- Room Graph module for corridor traversal
- Stress meter + Affliction/Virtue cascade triggers
- Curio interaction system (DM picks from hidden options)
- Graveyard / Trophy Wall for shared communal trauma

---

## Plan 3 — The Riftbound Chronicle (Deckbuilder)

**Core concept:** Competitive/cooperative dungeon deckbuilder with an automated "Warden." Players
are Rival Guild Leaders racing to loot a collapsing reality-bubble. A "Screw You" mechanic lets
opponents modify your dungeon.

| Mechanic | Detail |
|---|---|
| Card types | Scenes (Terrain), Denizens (Monsters/Traps), Twists (Blessings/Curses) |
| Auction of Agony | Active player plays Scene; opponent places Denizen face-down; active player counters with Twist |
| Doom Meter | Warden AI tracks 0–100; triggers Wandering Calamities at 25/50/75 |
| Loot Core | Central objective; room shrinks like battle royale |
| Room Cards | Each Scene = 6×6 isometric bubble; collapses after 3 rounds |
| Rift Pulse | SVG shatter transition between rooms |
| Chronicle | Procedural narration from card stack |

**New engine needs:**
- Card system with legality predicates
- Rift Stack (history of played Scene cards)
- Warden AI with Doom Meter state machine
- SVG shatter / transition animation batch
- Ghost replays of card sequences

---

## Plan 4 — Oblivion's Border (Terrain-Wrangling Survival)

**Core concept:** Reverse tower defence where players manipulate terrain (not units) to redirect
enemy hordes toward each other's Anchor Crystals, while a shared crystal in the centre means total
failure is always possible.

| Mechanic | Detail |
|---|---|
| Grid | 12×12 isometric; horde spawns from edges toward Anchor Crystals |
| Edict Cards | Terrain manipulations (Raise Rampart, Excavate Chasm, Veil of Mist) |
| Horde Mind | Neutral pathfinding AI; adapts every 3rd wave (Flying vs Burrowing) |
| Shared centre | Anchor Crystal with shared HP — everyone loses if centre falls |
| Cataclysmic Shifts | Global Edicts every 4th wave (palette swaps, terrain resets) |
| Chronicle | Cold after-action topographical kill feed |

**New engine needs:**
- Tile state tracking (height, fire, ice, mist, scorched)
- Pathfinding legality predicates (e.g. "Can Fire Elemental cross water?")
- Heatmap projection for monster traffic prediction
- Edict drafting system
- Async mode: inherit previous player's maze

---

## Plan 5 — The Rift Heralds (Co-op Raid Autobattler)

**Core concept:** Static formation co-op boss raid with visible dice and shared glory. Inspired by
Heroes of the Storm shared XP — no PvP sabotage, no loot competition.

| Mechanic | Detail |
|---|---|
| Deployment | Place 3 units (Tank/DPS/Support) on static 5×5 formation |
| Combat | Grid freezes; simultaneous attack rounds every 3 s |
| Dice | d20 visible every attack; 1 = crit miss, 20 = crit hit |
| Boss | Massive segmented SVG entity (Head, Claws, Heart); unique targeting per segment |
| Spell Slots | Reactive AI (Shield if big hit incoming, else Magic Missile) |
| Boss Tempo | Rampage → Guard → Weakened → Summon cycle |
| Warden | Neutral predictable AI; targets highest or lowest HP |
| Achievements | Pacifist, Gambler, Last Stand, Overkill, Clumsy, Herbalist |
| Codex of Shame | Leaderboards for fastest clear, most mitigation, highest HPS |
| Relics | Unlockable passive buffs tied to achievements |

**New engine needs:**
- Static deployment renderer (grid used for setup only)
- Segment targeting predicates
- Boss Tempo Wheel state machine (Global Active Effect)
- Achievement tracker projections (real-time unlock notifications)
- Replay system for Codex of Shame

---

## Plan 6 — The Maw of Fate (Roguelike Tower)

**Core concept:** Cooperative roguelike dungeon crawl with procedurally generated floors and
run-breaking Anima Powers. Most directly extends existing engine mechanics.

| Mechanic | Detail |
|---|---|
| Structure | 1–4 players ascend a 6-floor tower |
| Generation | Procedural layout, enemies, traps, puzzles per run |
| Anima Powers | Temporary run-specific buffs; class-specific and generic variants |
| Synergy | Active Effects stacking creates "crazy combinations" |
| Tarragrue | Soft enrage timer; spawns after X deaths, slowly pursues party |
| Phantasma | Run-specific currency (lost on failure); spent at Shackled Broker |
| Rewards | Legendary crafting materials, Soul Ash, cosmetics |
| Meta | Unlock starting bonuses for future runs |

**New engine needs:**
- Procedural Generation module (random floor layouts)
- Anima Power effect system (modifies predicates and Active Effects)
- Tarragrue death-tracking with event sourcing
- Phantasma economy tied to run lifecycle
- Broker vendor UI

---

## Common Architectural Foundations (All Plans)

The following engine features are reused across all six plans — no new work required:

- Isometric SVG rendering (Plan 2 requires an additional rank renderer)
- Predicate vocabulary for rule validation
- Active Effect cascades for buffs/debuffs/triggers
- Event sourcing for replay and state persistence
- CQRS projections for real-time updates
- Phoenix PubSub for multiplayer
- DM Override events (Plans 3+ automate the DM role)

---

## Rough Architectural Friction (Low → High)

| Plan | Friction | Reason |
|---|---|---|
| 6 — Roguelike Tower | Low | Extends existing combat; adds procedural gen + Anima Powers |
| 5 — Co-op Raid | Low | Simplest autobattler; no movement AI required |
| 2 — Darkest Dungeon | Medium | Requires rank renderer; reuses turn-based combat |
| 1 — Autobattler | Medium-High | Requires cooldown timing model replacing initiative |
| 4 — Terrain Wrangling | High | New tile state tracking, heatmap projection, pathfinding |
| 3 — Deckbuilder | High | Card system, Warden AI, SVG shatter transitions |

---

## Open Questions

- Which plan (if any) to prototype first?
- Are these standalone modes or layers on the same campaign world?
- Should the DM role always exist, or can all modes be fully automated?
- How much UI / UX work does each plan require beyond engine mechanics?
