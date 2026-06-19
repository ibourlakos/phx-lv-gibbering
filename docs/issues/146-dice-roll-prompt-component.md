# #146 · Dice roll prompt component + SceneServer pending-roll state

**Status:** open
**Opened:** 2026-06-19
**Priority:** medium
**Tags:** ui, gameplay, architecture, rules

## Context

Derived from brainstorm #28 (player dice roll prompt + auto-roll preference).
Depends on #145 (auto-roll preference schema).

When a player's `auto_roll` is `false` and the engine needs a roll from them
(attack roll, damage roll, saving throw), execution must pause until the player
submits a value. This issue implements the server-side pending state and the
client-side prompt component.

## What needs to happen

### Server side

1. Define `%Events.RollRequired{}` struct:
   `{entity_id, roll_type, dice_expression, context_label}` where
   `roll_type :: :attack | :damage | :saving_throw | :ability_check`.
2. Add `:awaiting_roll` flag to `Engine.State` (boolean, not a new top-level phase).
   While `true`, SceneServer rejects all action events except `submit_roll`.
3. Modify the resolution pipeline: at any point a roll is needed for the active
   player, check `auto_roll`. If `false`, emit `%Events.RollRequired{}`, set
   `:awaiting_roll`, and return without completing the action. If `true`, generate
   the roll and continue (existing behaviour).
4. Add `submit_roll(scene_id, entity_id, value)` command. SceneServer validates
   the value is in range for the dice expression, clears `:awaiting_roll`, and
   resumes the interrupted pipeline with the submitted value.
5. Server-side timeout: if no `submit_roll` arrives within 60 s, auto-roll and
   continue. Implemented as a `Process.send_after/3` message that fires auto-roll.

### Client side

6. `GameLive` handles `%Events.RollRequired{}` and shows a roll prompt overlay:
   - Heading: roll type label (e.g. "Attack Roll")
   - Dice expression and any modifier (e.g. "1d20 + 4")
   - "Roll" button → client-generates a random result, shows die animation via
     existing `push_event("roll_dice", …)`, then sends `submit_roll` with result.
   - Manual entry field → player types their physical dice result; validated to
     integer in [1, die_faces].
   - Countdown timer (60 s) shown in the overlay.
7. Overlay is dismissed on `submit_roll` acknowledgement from server.

## Out of scope

- Multi-owner saving throws for AoE (brainstorm #28 open question 2 — deferred).
- DM roll prompts for NPC saving throws (always auto-roll).

**Acceptance criteria**
- [ ] `%Events.RollRequired{}` struct defined in `Gibbering.Events`
- [ ] SceneServer sets `:awaiting_roll` and emits the event when active player has `auto_roll: false`
- [ ] SceneServer rejects non-`submit_roll` action events while `:awaiting_roll`
- [ ] 60 s timeout auto-rolls and resumes if player does not respond
- [ ] Roll prompt overlay renders in `GameLive` with correct dice expression and type label
- [ ] Roll button plays die animation and submits result
- [ ] Manual entry field validates range and submits on confirm
- [ ] Overlay hidden after submission; game continues
- [ ] `mix precommit` passes
