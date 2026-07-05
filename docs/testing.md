# Testing Guide

This document explains the testing strategy for the Gibbering Engine: what to test, how to write each kind of test, and when to use which layer.

---

## The mental model

The hardest part of testing a game engine isn't the code — it's knowing *what to prove*. The rule: **test behavior, not implementation**. Don't test that a particular line ran; test that the game did the right thing.

The boundary is especially clear: the engine (`Rules`, `State`) is pure Elixir data — no I/O, no processes — which means it can be tested like arithmetic. Only the outer layers (`SceneServer`, `GameLive`) touch the DB or start processes.

---

## Umbrella layout

Tests live in the app they belong to:

| App | Test root | What lives here |
|---|---|---|
| `apps/gibbering_engine/` | `test/` | Layer 1: pure `Rules`, `State`, `Pipeline` logic |
| `apps/gibbering_tales/` | `test/` | Domain context tests: Accounts, Campaigns, Catalogue, Inventory |
| `apps/gibbering_tales_web/` | `test/` | Layer 2: `SceneServer`; Layer 3: LiveView, controller, SVG |
| `apps/gibbering_tales_admin/` | `test/` | Admin controllers, plugs, admin context |

Run all apps from the umbrella root:

```bash
docker compose exec app mix test
```

Run a single app:

```bash
docker compose exec app mix test --app gibbering_engine
docker compose exec app mix test --app gibbering_tales_web
```

Run a specific file or line:

```bash
docker compose exec app mix test apps/gibbering_tales_web/test/engine/scene_server_test.exs
docker compose exec app mix test apps/gibbering_tales_web/test/engine/scene_server_test.exs:42
```

---

## The three layers

```
Layer 1 · Pure logic   ──  Rules, State, Parser, LegalGuard       (gibbering_engine)
Layer 2 · GenServer    ──  SceneServer (DB-backed, process)        (gibbering_tales_web)
Layer 3 · LiveView     ──  GameLive, admin controllers             (gibbering_tales_web / gibbering_tales_admin)
```

Start every new feature at Layer 1. Only add Layer 2/3 tests when you specifically need to prove processes or the web layer behave correctly.

---

## Layer 1: Pure logic

**App:** `gibbering_engine`  
**Files:** `apps/gibbering_engine/test/engine/rules_test.exs`, `state_test.exs`

No DB. No process. No setup. Just call functions.

```elixir
use ExUnit.Case, async: true   # always safe to parallelize at this layer
import GibberingTalesWeb.EngineFixtures  # build_state/1, with_entity/3, with_tile/3
```

### How to build test state

`build_state/1` gives you a ready 5×5 map with a hero and a monster:

```elixir
state = build_state()
# Override a specific field:
state = build_state(map_width: 10, map_height: 10)
# Modify an entity after the fact:
state = with_entity(state, monster_id(), hp: 1, tags: ["destructible"])
# Replace a tile:
state = with_tile(state, {2, 1}, walkable: false)
```

These helpers live in `apps/gibbering_tales_web/test/support/engine_fixtures.ex` (`GibberingTalesWeb.EngineFixtures`). They are in `gibbering_tales_web` rather than `gibbering_engine` because they depend on `GibberingTalesWeb.Engine.State` and `GibberingTales.Rulesets.*`, which belong to higher-level apps.

### What to test here

- Every branching condition in `Rules` — reachability, adjacency, obstruction, destruction.
- Every `State` transform — `advance_turn/1`, `from_campaign/2`, `active_hero_id/1`.
- Edge cases: empty turn order, single-tile map, zero hp, no valid moves.

### What NOT to test here

- That the DB saved something.
- That the GenServer sent a PubSub message.
- Rendering output.

---

## Layer 2: GenServer (SceneServer)

**App:** `gibbering_tales_web`  
**File:** `apps/gibbering_tales_web/test/engine/scene_server_test.exs`

Tests that prove the `SceneServer` API behaves correctly end-to-end, including DB load on init and PubSub broadcasting.

```elixir
use GibberingTalesWeb.DataCase, async: false   # shared sandbox — SceneServer process needs DB access
import GibberingTalesWeb.EngineFixtures
```

### Setup pattern

```elixir
defp start_server do
  game_id = insert_campaign()                   # inserts Campaign + tiles + entities into sandbox DB
  start_supervised!({SceneServer, game_id})     # supervised by the test; stopped automatically
  game_id
end
```

### Why `async: false`?

`SceneServer.init/1` runs in a spawned process that needs to query the DB. With `async: false` the sandbox runs in *shared mode*, which lets any spawned process use the same checkout without explicit `allow/3` calls.

### What to test here

- That `get_state/1` returns a properly populated `%State{}`.
- That `select_entity/2` / `move_entity/3` / `attack_entity/2` / `end_turn/1` mutate state correctly.
- That PubSub broadcasts `{:state_updated, state}` after each mutation.
- Guard conditions: moving to an invalid tile does nothing, selecting a non-active entity does nothing.

### What NOT to test here

- Pure logic already covered by Layer 1.
- HTML/SVG rendering.

---

## Layer 3: LiveView

**App:** `gibbering_tales_web`  
**File:** `apps/gibbering_tales_web/test/gibbering_tales_web/live/game_live_test.exs`

Tests that the browser-facing layer renders correctly and wires events to the game.

```elixir
use GibberingTalesWeb.ConnCase, async: false
import Phoenix.LiveViewTest
```

### Setup pattern

```elixir
{:ok, view, _html} = live(conn, "/game/#{game_id}")
```

Drive the view with `element/2` + `render_click/1`:

```elixir
view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
html = render(view)
assert_move_overlay(html)
```

### SVG assertion conventions

Import `GibberingTalesWeb.SVGAssertions` (built on [Floki](https://github.com/philss/floki)) to assert SVG structure via `data-*` attributes rather than fill/stroke colour strings. Colour-based assertions are brittle: a palette tweak breaks every test that matches `fill="#ef4444"`. Data attribute assertions survive visual changes.

```elixir
import GibberingTalesWeb.SVGAssertions

# Entity presence / fog of war
assert_entity_visible(html, entity_id)
refute_entity_visible(html, entity_id)

# HP bar — role-gated (DM sees exact values; player sees bucket label)
assert_hp_exact(html, entity_id, 15, 20)     # DM only
refute_hp_exact(html, entity_id)              # player: no data-hp attribute
assert_hp_bucket(html, entity_id, "Bloodied") # player: 25–50% health

# Tiles
assert_tile_at(html, 3, 2)

# Move overlay
assert_move_overlay(html)
refute_move_overlay(html)

# Selection ring (SpriteCompositor active-turn ellipse)
assert_selection_ring(html)
refute_selection_ring(html)

# Decorations
assert_decoration(html, "bones")
refute_decoration(html, "bones")

# Condition badges
assert_condition_badge(html, "poisoned")
```

Use `=~` only for text content (entity names, log messages, UI labels).

#### HP bucket labels

| Fraction | Label |
|---|---|
| > 75% | Unscathed |
| 50–75% | Hurt |
| 25–50% | Bloodied |
| ≤ 25% | Critical |

#### Data attribute catalogue

| Attribute | Element | Notes |
|---|---|---|
| `data-entity-id` | entity `<g>` | entity UUID |
| `data-entity-type` | entity `<g>` | `"hero"`, `"monster"`, `"object"` |
| `data-layer` | SpriteCompositor child | `"body"`, `"selection-ring"`, `"hp-bar"`, `"condition-badges"` |
| `data-hp` / `data-max-hp` | hp-bar `<g>` | DM role only |
| `data-hp-bucket` | hp-bar `<g>` | player role only |
| `data-condition` | condition badge circle | condition key, e.g. `"poisoned"` |
| `data-grid-x` / `data-grid-y` | tile `<polygon>` | grid coordinates |
| `data-tile-texture` | tile `<polygon>` | texture key, e.g. `"grass"` |
| `data-move-overlay` | overlay `<polygon>` | present when overlay is active |
| `data-move-cost` | overlay `<polygon>` | cost tier string |
| `data-highlight-type` | active-turn ring | `"active-turn"` |
| `data-movement-badge` | movement badge circle | present when movement exhausted |
| `data-decoration` | decoration `<g>` | decoration key, e.g. `"bones"`, `"dead_tree"` |

### Two-session pattern (role-gating and fog of war)

Mount two separate connections — DM and player — on the same `game_id`:

```elixir
dm_conn = log_in_user(build_conn(), dm_user)
player_conn = log_in_user(conn, player_user)

{:ok, dm_view, _} = live(dm_conn, "/game/#{game_id}")
{:ok, player_view, _} = live(player_conn, "/game/#{game_id}")

assert_hp_exact(render(dm_view), hero_id, 20, 20)
refute_hp_exact(render(player_view), hero_id)
```

Both views share the same `SceneServer` process. State changes made via one view are reflected in the other on the next `render/1` call.

### What to test here

- That the SVG renders (sanity check on mount).
- That clicking an entity triggers a visible state change (move overlay appears/disappears).
- That the event log updates after an attack.
- Role-gated rendering: DM vs player see different data attributes on the same entity.
- Fog of war: hidden entities absent from player DOM, present in DM DOM.

### What NOT to test here

- Pixel-perfect SVG layout — that's visual review.
- Game logic — already tested in Layers 1 and 2.

---

## Test support modules

| Module | Location | What it provides |
|---|---|---|
| `GibberingTalesWeb.EngineFixtures` | `apps/gibbering_tales_web/test/support/engine_fixtures.ex` | `build_state/1`, `hero_id/0`, `monster_id/0`, `with_entity/3`, `with_tile/3`, `insert_campaign/0` |
| `GibberingTalesWeb.ConnCase` | `apps/gibbering_tales_web/test/support/conn_case.ex` | `@endpoint`, `log_in_user/2`, sandbox setup |
| `GibberingTalesWeb.DataCase` | `apps/gibbering_tales_web/test/support/data_case.ex` | Repo sandbox for `GibberingTales.Repo` |
| `GibberingTalesWeb.SVGAssertions` | `apps/gibbering_tales_web/test/support/svg_assertions.ex` | Floki-based SVG helpers |
| `GibberingTales.DataCase` | `apps/gibbering_tales/test/support/data_case.ex` | Repo sandbox for domain schemas |
| `GibberingTales.AccountsFixtures` | `apps/gibbering_tales/test/support/accounts_fixtures.ex` | `register_user/0`, `user_fixture/1` |
| `GibberingTales.GameFixtures` | `apps/gibbering_tales/test/support/game_fixtures.ex` | `insert_campaign/1` for domain-layer tests |
| `GibberingTalesAdmin.ConnCase` | `apps/gibbering_tales_admin/test/support/conn_case.ex` | Admin endpoint, `log_in_support_user/2` |
| `GibberingTalesAdmin.DataCase` | `apps/gibbering_tales_admin/test/support/data_case.ex` | Sandbox for both `GibberingTalesAdmin.Repo` and `GibberingTales.Repo` |

---

## Running tests

All commands go through Docker:

```bash
# Run the full suite
docker compose exec app mix test

# Run a single app
docker compose exec app mix test --app gibbering_engine

# Run a specific file
docker compose exec app mix test apps/gibbering_tales_web/test/engine/scene_server_test.exs

# Run a specific test by line number
docker compose exec app mix test apps/gibbering_tales_web/test/engine/scene_server_test.exs:42

# Run only tagged tests (e.g. @tag :slow)
docker compose exec app mix test --only slow

# Run the pre-commit check (compile + format + tests)
docker compose exec app mix precommit
```

---

## TDD workflow (recommended)

1. **Branch** from `main`: `feat/<name>` or `fix/<name>`.
2. **Write the test first.** Start at Layer 1 if you're adding game logic. Start at Layer 2 if it's a SceneServer flow change. Layer 3 last.
3. **Watch it fail.** Run the test file directly — fast feedback.
4. **Make it pass.** Write the minimum production code.
5. **Refactor.** Clean up without breaking the test.
6. **Run `mix precommit`** before pushing. It runs `compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `check.docs`, and the full test suite.

---

## Decision guide: which layer?

| Question | Layer | App |
|---|---|---|
| "Does the movement algorithm respect walls?" | 1 (Rules) | `gibbering_engine` |
| "Does advance_turn clear selected_id?" | 1 (State) | `gibbering_engine` |
| "Does the LegalGuard filter block 'Beholder'?" | 1 (Pipeline) | `gibbering_engine` |
| "Does attacking via the API remove a 0-HP monster?" | 2 (SceneServer) | `gibbering_tales_web` |
| "Does a PubSub message reach a subscribed LiveView?" | 2 (SceneServer) | `gibbering_tales_web` |
| "Does clicking the hero show the move overlay?" | 3 (LiveView) | `gibbering_tales_web` |
| "Does the end-turn button clear the move overlay?" | 3 (LiveView) | `gibbering_tales_web` |
| "Does the admin suspend endpoint work?" | 3 (Controller) | `gibbering_tales_admin` |

When in doubt, go one layer lower. Layer 1 tests are the cheapest, fastest, and most precise.
