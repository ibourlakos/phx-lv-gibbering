# Testing Guide

This document explains the testing strategy for the Gibbering Engine: what to test, how to write each kind of test, and when to use which layer.

---

## The mental model

The hardest part of testing a game engine isn't the code — it's knowing *what* to prove. The rule: **test behavior, not implementation**. Don't test that a particular line ran; test that the game did the right thing.

For this project the boundary is especially clear: the engine (`Rules`, `State`) is pure Elixir data — no I/O, no processes — which means it can be tested like arithmetic. Only the outer layers (`GameServer`, `GameLive`) touch the DB or start processes.

---

## The three layers

```
Layer 1 · Pure logic   ──  Rules, State, Parser, LegalGuard
Layer 2 · GenServer    ──  GameServer (DB-backed, process lifecycle)
Layer 3 · LiveView     ──  GameLive (full HTTP + WebSocket stack)
```

Start every new feature at Layer 1. Only add Layer 2/3 tests when you specifically need to prove that processes or the web layer behave correctly.

---

## Layer 1: Pure logic

**Files:** `test/engine/rules_test.exs`, `test/engine/state_test.exs`

No DB. No process. No setup. Just call functions.

```elixir
use ExUnit.Case, async: true   # safe to parallelize
import Gibbering.GameFixtures  # build_state/1, with_entity/3, with_tile/3
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

### What to test here

- Every branching condition in `Rules` — reachability, adjacency, obstruction, destruction.
- Every `State` transform — `advance_turn/1`, `from_campaign/1`, `active_hero_id/1`.
- Edge cases: empty turn order, single-tile map, zero hp, no valid moves.

### What NOT to test here

- That the DB saved something.
- That the GenServer sent a PubSub message.
- Rendering output.

---

## Layer 2: GenServer (GameServer)

**File:** `test/engine/game_server_test.exs`

Tests that prove the `GameServer` API behaves correctly end-to-end, including DB load on init and PubSub broadcasting.

```elixir
use Gibbering.DataCase, async: false   # shared sandbox — other processes can use the connection
```

### Setup pattern

```elixir
defp start_server do
  game_id = insert_campaign()           # insert Campaign + tiles + entities into sandbox DB
  start_supervised!({GameServer, game_id})  # supervised by the test; cleaned up automatically
  game_id
end
```

`insert_campaign/1` (from `GameFixtures`) inserts a minimal campaign with the same layout as `build_state/1`. Use `System.unique_integer` names to keep tests independent.

### Why `async: false`?

`GameServer.init/1` runs in a spawned process that needs to query the DB. With `async: false` the sandbox runs in *shared mode*, which lets any spawned process use the same checkout without explicit `allow/3` calls.

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

**File:** `test/gibbering_web/live/game_live_test.exs`

Tests that the browser-facing layer renders correctly and wires events to the game.

```elixir
use GibberingWeb.ConnCase, async: false
import Phoenix.LiveViewTest
```

### Setup pattern

```elixir
{:ok, view, _html} = live(conn, "/game/#{game_id}")
```

You drive the view with `element/2` + `render_click/1`:

```elixir
view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
html = render(view)
assert html =~ "phx-click=\"move\""
```

### What to test here

- That the SVG renders (sanity check on mount).
- That clicking an entity triggers a visible state change (move overlay appears/disappears).
- That the event log updates after an attack.

### What NOT to test here

- Pixel-perfect SVG layout — that's visual review.
- Game logic — already tested in Layers 1 and 2.

---

## Running tests

All commands go through Docker:

```bash
# Run the full suite
docker compose exec app mix test

# Run a single file
docker compose exec app mix test test/engine/rules_test.exs

# Run a single test by line number
docker compose exec app mix test test/engine/rules_test.exs:42

# Run only tagged tests (e.g. @tag :slow)
docker compose exec app mix test --only slow

# Run the pre-commit check (compile + format + tests)
docker compose exec app mix precommit
```

---

## TDD workflow (recommended)

1. **Branch** from `main`: `feat/<name>` or `fix/<name>`.
2. **Write the test first.** Start at Layer 1 if you're adding game logic. Start at Layer 2 if it's a GameServer flow change. Layer 3 last.
3. **Watch it fail.** `mix test test/engine/rules_test.exs` should show a red failure.
4. **Make it pass.** Write the minimum production code.
5. **Refactor.** Clean up without breaking the test.
6. **Run `mix precommit`** before pushing. It runs `compile --warnings-as-errors`, `format`, and the full test suite.

---

## Decision guide: which layer?

| Question | Layer |
|---|---|
| "Does the movement algorithm respect walls?" | 1 (Rules) |
| "Does advance_turn clear selected_id?" | 1 (State) |
| "Does the LegalGuard filter block 'Beholder'?" | 1 (Pipeline) |
| "Does attacking via the API remove a 0-HP monster?" | 2 (GameServer) |
| "Does a PubSub message reach a subscribed LiveView?" | 2 (GameServer) |
| "Does clicking the hero show the move overlay?" | 3 (LiveView) |
| "Does the end-turn button clear the move overlay?" | 3 (LiveView) |

When in doubt, go one layer lower. Layer 1 tests are the cheapest, fastest, and most precise.

---

## Fixtures reference

| Helper | What it does |
|---|---|
| `build_state(opts)` | In-memory `%State{}` — 5×5 map, hero at (2,2), monster at (3,3) |
| `hero_id()` | The default hero id used by `build_state/1` |
| `monster_id()` | The default monster id used by `build_state/1` |
| `with_entity(state, id, attrs)` | Merge atom attrs into an entity map |
| `with_tile(state, {x,y}, attrs)` | Merge attrs into a grid tile |
| `insert_campaign(attrs)` | Insert a Campaign + tiles + entities into the sandbox DB |
