# WP-P · Minimum Playable Campaign Loop

**Status:** active
**Source:** brainstorm #28 (dice roll prompt); brainstorm #21 (movement gate); brainstorm #17 (campaign structure — campaign outcome slice)

The minimum set of engine and UI work required to run a complete small encounter:
a player moves, attacks or casts a spell, rolls dice interactively (or auto-rolls),
defeats an opponent, loots them, and sees a victory/defeat outcome.

**Note on loot:** The inventory and item pickup loop is already shipped (WP-M). The
loot side of the campaign loop is covered. This WP closes the remaining three gaps:
outcome state, movement confirmation UX, and interactive dice rolling.

---

## Issues

| # | Title | Depends on |
|---|---|---|
| [#19](../issues/019-lobby-edits-stale-gameserver.md) | Lobby character edits don't propagate to a running GameServer | — |
| [#139](../issues/139-dm-cannot-control-orphaned-pc.md) | DM cannot control orphaned PC — no action bar shown | — |
| [#142](../issues/142-victory-defeat-scene-phases.md) | Victory and defeat scene phases + auto-trigger | — |
| [#143](../issues/143-campaign-outcome-screen.md) | Campaign outcome screen | #142 |
| [#144](../issues/144-movement-confirmation-ui-gate.md) | Movement confirmation UI gate | WP-F #125 (overlay pipeline), WP-F #159 (condition badge — movement-exhausted indicator) |
| [#145](../issues/145-player-auto-roll-preference.md) | Player auto-roll preference | — |
| [#146](../issues/146-dice-roll-prompt-component.md) | Dice roll prompt component + SceneServer pending-roll state | #145 |
| [#147](../issues/147-initiative-roll-prompt.md) | Initiative roll prompt | #146 |

---

## Sequencing

```
#139 (DM orphaned PC control)  ← prerequisite for solo-play scenario

#142 (victory/defeat phases)
  └─→ #143 (outcome screen)

#144 (movement gate UI)        ← can run in parallel; light WP-F dependency (see below)

#145 (auto-roll preference)
  └─→ #146 (roll prompt + server pending state)
        └─→ #147 (initiative roll prompt)
```

`#142 → #143` and `#145 → #146` can run fully in parallel with each other.
`#144` can run in parallel with both chains. Its only external dependency is that
`WP-F #125` (tile decoration field) ships first — `#125` finalises the overlay
rendering pipeline that `#144` hooks into for the cost-colour layer. If WP-F is
behind, `#144` can be stubbed without decoration colours and polished later.

---

## Active Front

All issues closed. WP-P is complete.

---

## Known gaps raised during planning

The following gaps were identified during design of this WP. They are **not** blocking
the minimum loop but should be tracked:

1. **AoE saving throw prompts** — Brainstorm #28 open question 2. When multiple
   entities are caught in an AoE, each owning player should be prompted for their
   saving throw if auto-roll is off. Multi-owner concurrent prompts are deferred
   post-minimum. File a follow-on issue when the single-owner path (‌#146) is shipped.

2. **NPC/DM rolls visible to table** — Currently DM entity rolls are silent. A
   future "DM roll reveal" feature (show NPC attack roll to players dramatically)
   aligns with brainstorm #28's DM-roll open question. Defer post-minimum.

3. **Campaign narrative shell** — Intro/outro text, a named encounter title, and
   per-campaign win condition text are not in scope. The minimum campaign is
   DM-operated: DM places entities, starts session, players play, engine detects
   outcome. Narrative wrapper can be filed as a separate issue after WP-P ships.

4. **Initiative roll prompt** — Tracked as #147 in this WP (depends on #146).

---

## Out of scope for this WP

- Multi-session campaign persistence beyond the existing session archive (end session
  → archived in DB, introduced by #93).
- Character levelling / XP awards post-encounter.
- Loot system (WP-M ✓).
- Spectator view during combat (WP-K).
