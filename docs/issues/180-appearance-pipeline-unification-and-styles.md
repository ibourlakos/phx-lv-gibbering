# #180 · Unify entity appearance rendering, specialize biped silhouettes, add style-templated Carbot look

**Status:** closed
**Opened:** 2026-07-05
**Closed:** 2026-07-05
**Priority:** medium
**Tags:** rendering, architecture

Brainstorm #23 was implemented by issue #155 (closed 2026-06-21) but the doc itself was
never retired, and the resulting archetype system (`GibberingEngine.ActorAppearance`) only
runs as a fallback alongside 13 hand-authored, style-blind, south-only legacy sprite clauses
in `game_live.ex`. Separately, `biped_upright` is the only humanoid silhouette — goblin,
skeleton, zombie, orc, ogre, and troll all render identically to a human PC, just recolored.
Multi-style plumbing (`styles`/`appearances` tables, issue #99) exists end-to-end but only one
style ("dst") is ever seeded and there is no way to switch styles even in dev.

This issue unifies rendering onto the archetype pipeline, adds a `silhouette` dimension to
`biped_upright`, and makes per-layer SVG geometry style-templated (`.svg.eex` files per
style/archetype/silhouette/facing/layer, with graceful fallback to the `dst` template when a
style hasn't authored a given layer) so a second style ships as new template files + seed
data, not a new renderer module. The second style is an original, Carbot Animations–inspired
look (bold outlines, chibi proportions, flat colors) — not a trace or copy of any specific
Carbot artwork.

**Scope:**
- Delete the 13 legacy `entity_sprite/1` heex clauses in `game_live.ex`; extract sprite
  dispatch into `GibberingTalesWeb.Components.EntitySprites` (closes the long-parked TODO in
  `docs/architecture/features/svg-rendering.md`, issue #19)
- Add a `silhouette` dimension to `ActorAppearance` (`:humanoid`, `:goblinoid`,
  `:undead_gaunt`, `:giant`), resolved the same way `archetype_for/2` works today (static map
  + `"silhouette"` data override, default `:humanoid`)
- Add `GibberingTales.Catalogue.TemplateStore` (lives in `gibbering_tales`, not
  `gibbering_engine` — see `docs/architecture/engine-decomposition.md`): compiles `.svg.eex`
  files under `apps/gibbering_tales/priv/appearance_templates/<style>/<archetype>/
  <silhouette>/<facing>/<layer>.svg.eex` into functions at build time, with fallback to the
  `dst` template when a combination has no template
- Move current DST geometry out of `actor_appearance.ex` into `dst/` template files;
  `ActorAppearance.render_body/4` takes `(entity, appearances, style_slug, render_layer_fun)` —
  content-agnostic, the injected callback supplies actual markup (`TemplateStore.render/6`)
- Seed a second `"carbot"` style in `apps/gibbering/priv/repo/seeds.exs` (tile + entity
  appearance rows) and author Carbot templates for `biped_upright` (all four silhouettes),
  `quadruped`, `swarm`, `elemental_amorphous`, `structure`
- Tag goblin/kobold/orc/bugbear as `goblinoid`, skeleton/zombie as `undead_gaunt`, ogre/troll
  as `giant` in seed appearance data
- Dev-only style switch: `game_live.ex` mount accepts an optional `style` query param,
  validated against known slugs, falling back to `Catalogue.default_style_slug/0`
- Delete `docs/brainstorming/23-composable-entity-appearances.md` (per its own closing note)
  and its row in CLAUDE.md; update `docs/architecture/features/svg-rendering.md` to describe
  the unified pipeline; update `docs/architecture/engine-decomposition.md` (file-based content
  placement convention) and `docs/architecture/bounded-contexts.md` (add `TemplateStore` to
  the Content Catalogue module list)

**Out of scope:** socket-offset/layer-order variation per style (kept style-agnostic for
now — flagged as a likely fast-follow once Carbot templates are visually compared); raster/
pixel-art sprites (separate, still-open, legal-gated effort — issues #6/#16); unifying with
the character-sheet portrait system (`character_sprite.ex`, deliberately separate).

**Acceptance criteria**
- [x] Legacy `entity_sprite/1` clauses removed from `game_live.ex`; all entity sprites render
      via `GibberingTalesWeb.Components.EntitySprites` → `ActorAppearance.render_body/4`
- [x] `silhouette_for/3` resolves goblin/kobold/orc/bugbear → `:goblinoid`, skeleton/zombie →
      `:undead_gaunt`, ogre/troll → `:giant`, everything else → `:humanoid`, with data override
- [x] `TemplateStore` renders the correct template for a given style/archetype/silhouette/
      facing/layer, and falls back to the `dst` template when the active style has none
- [x] A `"carbot"` style is seeded with tile + entity appearance rows covering the same
      content keys as `"dst"`
- [x] Carbot templates exist for `biped_upright` (all 4 silhouettes), `quadruped`, `swarm`,
      `elemental_amorphous`, `structure`
- [x] `?style=carbot` on the game LiveView query string renders the Carbot look for the same
      scene that renders DST by default, with no crashes on any seeded sprite key
- [x] `docs/brainstorming/23-composable-entity-appearances.md` deleted; references removed
- [x] `docs/architecture/features/svg-rendering.md` updated to describe the unified pipeline
- [x] `mix ecto.reset` exits 0 with the new seed data
- [x] `mix precommit` passes
