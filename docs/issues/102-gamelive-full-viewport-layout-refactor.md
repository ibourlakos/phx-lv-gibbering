# #102 · GameLive full-viewport layout refactor

**Status:** open
**Opened:** 2026-06-07
**Priority:** medium
**Tags:** rendering, ui, architecture

Implement the full-viewport layout model resolved in #97. GameLive currently uses a flex-row
layout with an inline SVG sized to map dimensions. This issue refactors it to the spec.

Depends on [#97](097-full-viewport-scene-layout.md) (closed — decisions documented in
`priv/static/art-reference/README.md`).

**Changes required**

1. Create `lib/gibbering_web/components/layouts/game_root.html.heex` — a root layout with no
   navbar and `body { margin: 0; overflow: hidden; background: #111827; }`
2. Add a `:game` live_session in the router that uses the game root layout. GameLive opts into
   this session instead of `:authenticated`.
3. Refactor the SVG element: `position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;`
   with `viewBox` set to the current map dimensions. Remove the fixed `width`/`height` attributes.
4. Add a `PanZoom` JS hook (skeleton only — no actual pan/zoom gestures yet, just preserves
   `viewBox` across LiveView patches so the camera position survives state updates).
5. Move screen-anchored UI panels from inside the flex-row to `position: fixed` HTML overlay divs
   at the z-index values defined in `priv/static/art-reference/README.md`.
6. Verify existing `DiceRoll` hook and all phx-click handlers still work after the refactor.

**Acceptance criteria**
- [ ] GameLive renders in a full-viewport layout (no navbar, no scroll)
- [ ] SVG fills 100vw × 100vh via `position: fixed`; `viewBox` tracks map dimensions
- [ ] Turn order strip, action bar, info panel, DM controls are `position: fixed` overlays
- [ ] HTML overlay containers have `pointer-events: none`; buttons/inputs have `pointer-events: auto`
- [ ] `DiceRoll` hook still works
- [ ] All existing phx-click handlers (select_entity, move, attack, etc.) still fire correctly
- [ ] `mix precommit` exits 0
- [ ] No existing test regressions
