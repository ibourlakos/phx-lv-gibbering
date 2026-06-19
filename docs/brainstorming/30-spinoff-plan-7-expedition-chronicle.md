# #30 · Spinoff Plan 7 — The Expedition Chronicle

## Context

Synthesises elements from brainstorm [#29](29-spinoff-plans-1-6.md) (Plans 1–6) into a single
structured, objective-based adventure mode. Think "Deep Rock Galactic Dives + WoW Delves +
D&D Campaign." It is the plan most aligned with the engine's current capabilities and the
project's co-op, no-PvP design philosophy.

---

## Design Pillars

| Pillar | Detail |
|---|---|
| No PvP trickery | Pure cooperative PvE; all rewards, XP, and progress are party-wide |
| Meaningful movement | Objective-driven, not tactical repositioning; smaller maps than open campaigns |
| D&D mechanics stay intact | d20, spell slots, AC, saving throws, Hit Dice — no oversimplification |
| Procedural narration | Chronicle generated from event log after each expedition; no human DM required |
| Deep meta-progression | Multiple growth vectors beyond XP: gear, materials, proficiencies, subclass potentials, Paragon Ranks, military Ranks |

---

## Core Loop

### The Expedition

A curated adventure with 3–5 Stages (like DRG's Dives). Each Stage is a self-contained isometric
map with specific objectives. Between Stages: brief rest/rewind — players may spend Hit Dice and
review strategy before the next deployment.

### The Ticking Clock — Rift Stability

Every action (combat round, movement step, interaction) ticks down a global Stability meter.
Stability hits zero → expedition collapses → forced extraction with reduced rewards.

The pressure is about *efficiency*, not raw speed — thoughtful play is still rewarded.

**Implementation:** global Active Effect with a counter; cascade triggers extraction on zero.

### The Preparation Phase — Leader Role

Before deployment, one player is designated Expedition Leader. Leader actions:

- Assign party roles (Tank / Healer / DPS / Utility) — sets default AI behaviour and loot priority
- Select consumables from the shared Supply Pack (limited slots)
- Spend accumulated Reputation for temporary expedition buffs
- Review a procedurally generated Strategic Briefing derived from the Stage objectives

---

## Stage Objectives

Each Stage randomly selects from a pool:

| Objective | Description | Flavour |
|---|---|---|
| Extermination | Kill all enemies in the zone | _"The Necromancer's horde must be purged."_ |
| Relic Recovery | Locate and retrieve a specific artefact | _"The Amulet of Aegis lies in the central chamber."_ |
| Data Extraction | Interact with 3–5 terminals while defending against waves | _"Decipher 3 runestones before the flames consume them."_ |
| Escort / Protection | Guard a slow-moving NPC or object across the map | _"The Oracle's caravan must reach the portal."_ |
| Boss Slay | Single powerful boss with unique mechanics | _"The Frost Wyrm stirs. Find its heart."_ |
| Gauntlet | Survive a fixed number of enemy waves without a break | _"The horde knows you're here. Outlast them."_ |
| Stealth / Evasion | Traverse without alerting patrols; combat = failure | _"The Shadowfell patrols are blind. Tread carefully."_ |
| Resource Scavenging | Collect X resources scattered across the map | _"Harvest crystal veins before tremors collapse the cave."_ |

---

## Secondary Objectives

Each Stage carries 1–3 hidden/optional objectives feeding the Achievement System and awarding
bonus Expedition Currency:

| Secondary | Condition |
|---|---|
| Speed Clear | Complete within X rounds |
| Pacifist Run | Complete without killing certain enemy types |
| Perfect Defence | Escort NPC takes 0 damage |
| Treasure Hunter | Find and open all secret caches |
| Limited Rest | Complete without using a Short Rest |

---

## Rewards & Progression

| Reward | Description |
|---|---|
| Gear | Weapons, armour, accessories with unique stats |
| Materials | Crafting components for campaign hub upgrades |
| Proficiencies | Unlock new weapon / armour / tool proficiencies from repeated use |
| Subclass Potentials | Unlock new subclass feature paths |
| Paragon Ranks | Levels beyond 20 — +1 ability scores, feats, unique class abilities (up to rank 50; beyond 50 = cosmetic / title rewards) |
| Military Ranks | Sergeant → Captain → General; each rank grants passive party bonuses |

---

## Daily & Weekly Quest Loop

**Daily (small rewards):**
- Clear 1 Expedition → 100 Gold, 1× Random Material
- Complete an Extermination objective → 50 Reputation

**Weekly (large rewards):**
- Clear 5 Expeditions → 1× Rare Gear Box
- Complete an Expedition with all secondary objectives → 1× Subclass Potential Token
- Defeat the weekly Expedition Boss → 1× Paragon Rank Upgrade

**World State:** the server tracks active Expeditions per day/week, creating a shared meta-game
where the community coordinates on the hardest weekly challenges.

---

## Procedural Narration — The Chronicle

At the end of each expedition, a CQRS projection reads the event log and generates a plain-text
summary:

> *"The Crimson Company ventured into the Crypt of Whispers. Stage 1: Extermination — cleared
> with 2 casualties. Stage 2: Relic Recovery — the Amulet was retrieved despite a Goblin ambush.
> Stage 3: Boss Slay — the Spider Queen fell to [Player]'s critical strike. Expedition successful.
> Rewards: 450 Gold, 2× Emberite Shards, 1× 'Webweaver's Cloak.'"*

Chronicle can be shared in global chat, saved to the campaign map as lore, or displayed in a
party trophy wall.

---

## Engine Mapping

| Engine Feature | Plan 7 Use |
|---|---|
| Isometric Grid | Each Stage = fresh map; grid resets between Stages for performance |
| Predicate Vocabulary | Validates objective completion (e.g. death-count predicate for Extermination) |
| Active Effect Cascades | Rift Stability = global Active Effect with tick counter; zero triggers extraction cascade |
| Event Sourcing | Every action logged; enables perfect replay and Chronicle generation |
| CQRS Projections | Chronicle summary, achievement tracking, daily/weekly quest progress |
| Preparation Phase UI | Dedicated SVG overlay — role assignment, consumable selection, Strategic Briefing |

---

## Potential Mutations

- **Doom Clock Twist:** failed expeditions permanently alter the campaign world (e.g. "The Goblin
  Horde grows stronger — future expeditions spawn 20% more enemies").
- **Guild Hall Meta-Layer:** invest rewards into a shared base that unlocks new consumables, buffs,
  or expedition types.
- **Expedition Leaderboard:** fastest clear, most secondary objectives, highest difficulty.
- **Dynamic Difficulty Scaling:** expeditions scale on party composition or recent performance.

---

## Open Questions

- **Leader Role**: one Leader per expedition, or rotating per Stage?
- **Rift Stability**: tick per action or per combat round? (Per round is simpler; per action is
  more granular.)
- **Paragon Ranks**: how many before diminishing returns? (50 ranks with power; 50+ cosmetic.)
- **Daily/Weekly Reset**: UTC or per-server local time?
- **Chronicle Visibility**: party-only with opt-in global sharing, or always public?
- **Standalone mode or campaign layer**: does this replace the existing campaign structure or
  sit alongside it?
