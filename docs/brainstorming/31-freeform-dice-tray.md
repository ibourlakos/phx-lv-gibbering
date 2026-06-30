# #31 · Freeform Dice Tray

## Context

All dice rolls today are triggered by the engine — attack, damage, initiative, saving throws.
Players have no way to roll dice outside of a game-demanded prompt: no "roll for fun", no
DM-requested ability check that isn't yet wired into the rules engine, no rolling multiple
dice just to see what happens.

A freeform dice tray gives players a persistent panel to assemble and throw any combination
of standard dice at any time. Results are visible to the table (event feed). This covers:

- Social / exploration checks the DM calls out verbally ("roll Perception")
- Group rolls where all players roll the same die at once
- Rolling for fun / tension ("I roll a d20 just to vibe")
- Playtesting and DM stress-testing the animation system

This is distinct from brainstorm #28 (engine-demanded roll prompts with pending-roll state
and auto-roll preference). The freeform tray has no awaiting-roll server state — it's a
pure player-initiated action that always resolves immediately.

---

## Dice set

Standard D&D set: **d4, d6, d8, d10, d12, d20, d100**.

No custom die faces for v1. d100 renders as `1d10 × 10` (the "tens" die convention) but
the roll event just reports the final 1–100 value.

---

## Multi-dice assembly model

Players build a roll by clicking die buttons to increment that die's count. The tray shows
the current expression (e.g., `2d6 + 1d20`) and a **Roll** button.

```
[ d4 ] [ d6 ] [ d8 ] [ d10 ] [ d12 ] [ d20 ] [ d100 ]
  ×0     ×2     ×0     ×0      ×0      ×1      ×0
                                                 [Clear] [Roll]
Expression: 2d6 + 1d20
```

- Each die button click increments that die's count (up to a reasonable cap, e.g. 10 per type).
- Right-click or Shift-click decrements. A "×N" badge appears when N > 0.
- **Clear** resets all counts.
- **Roll** submits the roll to the server.

No freeform text expression input for v1 — the click-to-increment model is simpler and
avoids parsing a dice notation grammar.

---

## Modifier support

Deferred for v1. Adding a `+N` flat modifier requires an input field and validation, and
most freeform rolls don't need it. Revisit if players request it.

---

## UI placement

The tray lives in the **player panel**, below the existing character info / action bar,
always visible when a player is in-session. It does not occupy screen space when you're
the DM (DM already has a roll panel elsewhere if needed).

Alternative considered: floating action button in the corner. Rejected — adds an extra
click and hides the die set behind a modal, making it slower for the common case.

---

## Server-side handling

`handle_event("freeform_roll", %{"dice" => dice_map}, socket)` in `GameLive`:

1. Validate that the player is a participant in the scene (not a spectator).
2. For each die type with count > 0, generate `count` random results server-side.
3. Broadcast a `%Events.FreeformRoll{player_id, dice_map, results, total}` to the scene
   PubSub topic.
4. Push `roll_dice` animation event back to the rolling player's socket for each die
   (or one representative die for the dominant die type).
5. Append to the event feed as `"<name> rolled 2d6 + 1d20 → [3, 5] + [17] = 25"`.

No SceneServer involvement — GameLive handles it directly. Freeform rolls don't affect
game state (no HP, no to-hit, no conditions). They are pure events.

---

## Animation for multiple dice

For a multi-die roll, animate the dice **sequentially with a short stagger** (~150 ms
between throws). Each die uses the existing `roll_dice` push_event. The event feed line
appears after the last die lands.

Simultaneous animation (all dice flying at once) risks visual chaos and z-index collisions
on the overlay. Sequential stagger is simpler and preserves the drama of each result.

Cap the animation at **3 dice** to avoid a 10-die cascade taking ~2 s. If the total die
count exceeds 3, animate 3 and append `"(+ N more)"` to the label. All results still
appear in the event feed line.

---

## Visibility model

Freeform rolls are **always public** — they appear in all players' event feeds and the DM
sees them. There is no private mode for v1.

Rationale: in a real tabletop game, picking up dice is a visible act. If a player wants to
roll secretly they should ask the DM to roll for them (not in scope for v1).

---

## Decisions

| Q | Decision |
|---|---|
| **D1 — Dice set** | Standard D&D 7 dice. No custom. |
| **D2 — Multi-dice** | Yes, via click-to-increment per die type. Cap 10 per type. |
| **D3 — Modifiers** | Deferred. |
| **D4 — UI placement** | Player panel, always visible. |
| **D5 — Animation** | Sequential stagger, cap 3 animations. |
| **D6 — Visibility** | Always public (event feed + DM). |
| **D7 — Server state** | GameLive only; no SceneServer involvement. |

---

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#161](../issues/161-freeform-dice-tray.md) | Freeform dice tray — player-initiated multi-die roll | open |

This brainstorm will be deleted when #161 is closed or deferred.
