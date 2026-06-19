# #28 · Player Dice Roll Prompt and Auto-Roll Preference

## Context

All dice rolls in the engine are currently automatic — the server generates a random
result and applies it immediately. For a tabletop feel, players should be able to
physically roll their own dice (or click a digital roll button) when the game demands
a roll from them, then submit the result. Some players prefer not to be interrupted
and want the old auto-roll behaviour. The preference should be persistent per player
per campaign.

This brainstorm defines: what triggers a player roll prompt, what the prompt looks like,
how the server handles the pending-roll state, and how the auto-roll preference is
stored and toggled.

---

## What triggers a player roll prompt

Rolls that belong to the **active player** and must pause execution until the result
arrives:

| Roll type | Trigger |
|---|---|
| Attack roll (weapon) | Player confirms an attack action |
| Spell attack roll | Player casts a spell with `attack_type: :ranged_spell_attack` or `:melee_spell_attack` |
| Damage roll | After a hit is confirmed (attack roll succeeded) |
| Ability check | Engine demands a check from the active entity (e.g. Athletics for grapple) |
| Saving throw (player side) | Engine demands a saving throw from an entity the player controls |

Rolls that are **not** player-facing (DM-controlled entities, NPCs) always auto-roll.

---

## Server-side pending-roll state

When a roll is required from the active player and `auto_roll` is false:

1. Engine reaches the point where the roll is needed.
2. Instead of generating the roll, SceneServer emits a `%Events.RollRequired{}` event
   with `{entity_id, roll_type, dice_expression, context}`.
3. SceneServer transitions the scene to a `:awaiting_roll` sub-state within the current
   phase (not a full phase transition — just a flag that blocks further action events).
4. GameLive receives the event and renders the dice prompt UI.
5. Player rolls (or auto-roll fires) and sends a `submit_roll` event with the value.
6. SceneServer resumes the interrupted resolution pipeline with the submitted value.

**Important:** the `:awaiting_roll` flag must have a server-side timeout (e.g. 60 s)
after which the server auto-rolls and continues. This prevents a player from stalling
the game indefinitely.

---

## Player-facing prompt design

Minimum viable component:

```
┌─────────────────────────────────────┐
│  ATTACK ROLL                        │
│  Roll: 1d20 + 4                     │
│                                     │
│   [ 🎲 Roll ]   or enter:  [____]   │
│                                     │
│   (auto-rolling in 58s...)          │
└─────────────────────────────────────┘
```

- **Roll button** — generates a random result client-side (or server-side via LV event),
  displays the die face animation, then submits.
- **Manual entry** — player typed their physical dice result; integer 1–20 validated.
- **Countdown** — auto-rolls when timer expires.

The existing `push_event("roll_dice", …)` animation should fire in both the Roll button
and auto-roll paths.

---

## Auto-roll preference

Stored on `campaign_characters` (the per-player-per-campaign entity bridge):

```
auto_roll: boolean, default true
```

When `true`: server skips `%Events.RollRequired{}` and resolves the roll immediately —
current behaviour preserved. When `false`: server emits the event and enters
`:awaiting_roll`.

Toggle should be accessible in-session (player settings tab or gear icon), not buried
in a pre-session menu.

---

## Decisions

| Q | Decision |
|---|---|
| **Q1 — Granularity** | Single `auto_roll` toggle for v1. Per-roll-type granularity deferred. |
| **Q2 — AoE concurrency** | Deferred — filed as #148 (multi-owner concurrent saving throw prompts). |
| **Q3 — Physical dice honour system** | Manual entry trusts the player. Validated only against range 1–die_face_count. Intentional design — no server-side enforcement. |
| **Q4 — DM roll prompts** | Always auto-roll for DM/NPC. Future reveal feature filed as #149 (NPC/DM roll visibility). |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#145](../issues/145-player-auto-roll-preference.md) | Player auto-roll preference | open (WP-P) |
| [#146](../issues/146-dice-roll-prompt-component.md) | Dice roll prompt component + SceneServer pending-roll state | open (WP-P) |
| [#147](../issues/147-initiative-roll-prompt.md) | Initiative roll prompt | open (WP-P) |
| [#148](../issues/148-aoe-saving-throw-prompts.md) | AoE saving throw prompts — multi-owner concurrent rolls | open |
| [#149](../issues/149-npc-dm-roll-visibility.md) | NPC / DM roll visibility | open |

This brainstorm will be deleted when #145–#149 are all closed or deferred.
