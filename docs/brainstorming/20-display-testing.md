# #20 · Display Testing — Verifying What Users See

## Context

The current three-layer testing strategy covers pure game logic (Layer 1), GenServer behavior (Layer 2), and basic LiveView event wiring (Layer 3). However Layer 3 explicitly defers "pixel-perfect SVG layout" to visual review and relies on raw string matching (`html =~ "..."`) for everything else.

This leaves a real gap: there is no systematic way to verify **what a given user role sees under a given game state**. This is especially relevant for:

- Role-gated rendering (DM sees exact HP; player sees bucketed bar)
- Fog-of-war correctness (hidden entities must not appear in player SVG)
- Selection overlays, HP bars, and other state-dependent visual elements
- SVG structural integrity across feature changes

This brainstorm maps the available approaches before committing to any changes in `docs/testing.md`.

---

## Current state

- Layer 3 tests use `Phoenix.LiveViewTest` with `render(view)` + raw `=~` string assertions.
- SVG is built as pure Elixir strings inside render functions — no JS-side rendering.
- Role gating exists in `GameLive` assigns but has no dedicated test layer.
- `docs/testing.md` explicitly states: "Pixel-perfect SVG layout — that's visual review."

---

## Approaches

### 1. Render unit tests — pure function layer

**What it is:** If SVG-building helpers (e.g. `render_tile/2`, `render_entity/2`, `build_panel_content/2`) are pure functions, they can be called directly in Layer 1 tests with no process or DB cost.

**How it works:**

```elixir
html = MyModule.render_entity(entity, role: :player)
{:ok, doc} = Floki.parse_fragment(html)
assert Floki.find(doc, "rect.entity[data-id='#{entity.id}']") != []
```

**Strengths:**
- Cheapest and fastest of all options — no LiveView stack, no DB, no process
- Tests role-gating logic directly in the function that produces the output
- Composable with Floki (see approach #2)

**Weaknesses:**
- Only works if render helpers are extracted into testable pure functions; currently they may be inlined in HEEx templates
- Does not test the socket/assign wiring that feeds the render functions

**Verdict:** High value. Should be the default approach for any new render logic. Requires progressive extraction of render helpers out of templates.

---

### 2. Floki-based DOM assertions

**What it is:** Parse the HTML/SVG string returned by `render(view)` into a DOM tree using [Floki](https://hex.pm/packages/floki) and assert on element attributes and structure using CSS selectors.

**How it works:**

```elixir
html = render(view)
{:ok, doc} = Floki.parse_document(html)

# Assert a specific tile exists with correct attributes
assert Floki.find(doc, "rect.tile[data-x='2'][data-y='2'][data-walkable='true']") != []

# Assert an entity is not visible to a player (fog of war)
assert Floki.find(doc, "g.entity[data-id='#{hidden_monster_id}']") == []
```

**Strengths:**
- Already available (`floki` is a Phoenix test dependency by default)
- Much more robust than `=~` — survives attribute reordering and whitespace changes
- Works at Layer 3 with the existing `live/2` setup pattern
- Directly expressible: "the player's view has no SVG node for this hidden entity"

**Weaknesses:**
- Requires data attributes (`data-x`, `data-walkable`, `data-id`) on SVG elements — these may not exist yet and must be added intentionally
- Does not verify visual appearance (color, size, position) — only structural presence

**Verdict:** Immediate upgrade from raw `=~`. Low adoption cost. Should replace string assertions in `game_live_test.exs` incrementally.

---

### 3. Snapshot / golden file testing

**What it is:** Render the full SVG (or a component subtree) to a known-good baseline file. Future test runs diff the current output against the baseline and fail on divergence.

**How it works:**

```elixir
# On first run: write the file
# On subsequent runs: compare
assert_matches_snapshot("fog_of_war_player_view", render(view))
```

A `mix test --update-snapshots` flag regenerates baselines. The implementation is ~30 lines of custom ExUnit assertion.

**Strengths:**
- Catches regressions that are hard to enumerate — a refactor that accidentally reveals a hidden entity shows up immediately
- Works well for SVG since the output is deterministic text
- Documents expected output as a readable file in version control

**Weaknesses:**
- Snapshots become stale on any intentional SVG change and must be regenerated deliberately — easy to rubber-stamp without inspecting
- Snapshot files in the repo grow the codebase and need maintenance discipline
- Brittle to non-visual changes (whitespace, attribute order) unless normalized before comparison

**Verdict:** Good complement to Floki assertions for regression prevention. Worth adding once the data-attribute layer (approach #2) is stable. Rolling our own helper is low cost.

---

### 4. Wallaby — browser automation (Elixir-native)

**What it is:** [Wallaby](https://hex.pm/packages/wallaby) is an Elixir integration testing library that drives a real browser (ChromeDriver) and can assert on the live-rendered DOM, take screenshots, and compare visual output.

**How it works:**

```elixir
use Wallaby.Feature

feature "player cannot see hidden entity", %{session: session} do
  session
  |> visit("/game/#{game_id}")
  |> assert_has(Query.css("g.entity[data-id='#{hero_id}']"))
  |> refute_has(Query.css("g.entity[data-id='#{hidden_monster_id}']"))
end
```

**Strengths:**
- Tests in a real browser — catches any client-side rendering issues (currently minimal, but future JS interop)
- Can take screenshots and do pixel-level visual comparison
- Elixir-native — integrates with `DataCase`, sandbox, and `start_supervised!`

**Weaknesses:**
- Requires ChromeDriver (or equivalent) in Docker — adds infra complexity
- Tests are slow compared to LiveViewTest — seconds per test vs. milliseconds
- Overkill for the current architecture where all rendering is server-side SVG

**Verdict:** Not the right first step. Defer until there is a concrete need (JS interop, visual pixel testing, accessibility checks). Worth a follow-up brainstorm if the rendering model changes.

---

### 5. Playwright / Cypress E2E

**What it is:** External test runners (Node-based) that drive a real browser against the running Phoenix server. Playwright has built-in screenshot diffing (`toMatchSnapshot()`); Cypress has similar plugins.

**How it works:**

```js
// Playwright
await page.goto(`/game/${gameId}`);
await expect(page.locator('g.entity[data-id="hero-1"]')).toBeVisible();
await expect(page).toMatchSnapshot('player-view.png');
```

**Strengths:**
- Mature visual regression ecosystem with rich tooling (Percy, Chromatic for hosted diffing)
- Cross-browser testing possible
- Most realistic test of what the user actually sees

**Weaknesses:**
- Requires a separate Node toolchain alongside the Docker Elixir setup
- E2E tests are the slowest and most fragile layer — network, timing, test isolation all become concerns
- Visual diffs need a CI service to store and compare screenshots
- Significant setup cost vs. marginal gain over Wallaby for a server-rendered SVG app

**Verdict:** Too heavy for the current project stage. Re-evaluate if the UI complexity grows significantly or if there is a need for cross-browser validation. Not in scope for the near term.

---

## Role-gating test considerations

Role gating is a specific subproblem worth calling out across all approaches. The key assertions are:

| Scenario | Assertion |
|---|---|
| Player cannot see hidden entity SVG node | `Floki.find(doc, "g.entity[data-id='#{id}']") == []` |
| Player sees HP bucket label, not exact value | `Floki.find(doc, ".hp-label") \|> Floki.text() == "Bloodied"` |
| DM sees exact HP number | `Floki.find(doc, ".hp-exact") \|> Floki.text() == "14/28"` |
| Player sees fog overlay on unrevealed tile | `Floki.find(doc, "rect.fog[data-x='3'][data-y='3']") != []` |

These assertions require:
1. Consistent `data-*` attributes on SVG elements (a prerequisite across approaches)
2. Two LiveView sessions in a single test — one with `role: :dm`, one with `role: :player` — to assert diverging output from the same game state

The two-session pattern is supported by `Phoenix.LiveViewTest` — you open two `live/2` connections and compare their `render/1` output.

---

## Decisions

| Q | Decision |
|---|---|
| **Q1** | SVG render helpers are inlined in HEEx templates — not yet pure functions. Issue #153 includes extracting key render helpers (entity, tile, overlay) as testable pure functions as a prerequisite to Approach #1 unit tests. |
| **Q2** | SVG elements do not have systematic `data-*` attributes yet. Issue #153 adds them as part of the Floki layer work. |
| **Q3** | Snapshot baselines in `test/snapshots/` committed to version control. `--update-snapshots` mix flag regenerates them. Snapshot testing is a follow-on after #153 ships. |
| **Q4** | Two-session role-gating pattern not yet used. Issue #153 establishes it as the canonical pattern for role-gated render tests. |
| **Q5** | Use semantic `data-*` attributes only (`data-entity-id`, `data-x`, `data-y`, `data-walkable`) — no separate `data-testid` namespace. Semantic attributes serve both test targeting and debugging. |

## Issues Opened

| Issue | Title | Status |
|---|---|---|
| [#153](../issues/153-svg-testability-data-attributes-floki.md) | SVG testability — data attributes and Floki assertion layer | open |

This brainstorm will be deleted when #153 is closed.
