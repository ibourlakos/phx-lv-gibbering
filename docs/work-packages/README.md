# Work Packages

One file per work package: `docs/work-packages/wp-<letter>.md`. This file is the index only.

A work package groups related issues by concern and establishes sequencing within that concern. See [docs/workflow.md](../workflow.md) ([E] subflow) for creation, maintenance, and completion rules.

**Next letter:** U

---

## Active

Ordered by priority — work at the top before starting work below it.

| WP | Title | Open Issues |
|---|---|---|
| [WP-Q](wp-q.md) | Spatial Model Foundation | #156, #157, #158 |
| [WP-B](wp-b.md) | Core Engine Architecture | #15, #152 |
| [WP-K](wp-k.md) | Spectator Implementation | #121 → #122 |
| [WP-L](wp-l.md) | DM Projection & Top-Down Viewport | #124 |
| [WP-F](wp-f.md) | Rendering & Frontend | #84 |
| [WP-A](wp-a.md) | Infrastructure & Data Plumbing | #24 |

---

## Parked

| WP | Title | Reason |
|---|---|---|
| [WP-I](wp-i.md) | Monitoring | Deferred until core game loop is stable |

---

## Complete

| WP | Title | Completed |
|---|---|---|
| [WP-R](wp-r.md) | Display Testing & Testability | 2026-07-03 |
| [WP-S](wp-s.md) | Engine Decomposition Phase 2 — Umbrella Conversion | 2026-07-03 |
| [WP-T](wp-t.md) | Post-Phase 2 HUD Extraction | 2026-07-03 |
| [WP-P](wp-p.md) | Minimum Playable Campaign Loop | 2026-06-20 |
| [WP-O](wp-o.md) | Inspection Panel & Player Event Feed | 2026-06-20 |
| [WP-M](wp-m.md) | Inventory & Loot System | 2026-06-19 |
| [WP-N](wp-n.md) | Campaign / Map Restructure Phase 1 | 2026-06-17 |
| [WP-J](wp-j.md) | Architecture Operationalization | 2026-06-13 |
| [WP-H](wp-h.md) | Game Content | 2026-06-07 |
| [WP-E](wp-e.md) | Admin App | 2026-06-07 |
| [WP-G](wp-g.md) | Integration Test Coverage | 2026-06-06 |
| [WP-C](wp-c.md) | Rules Engine | 2026-06-06 |
| [WP-D](wp-d.md) | Campaign & Character Lifecycle + DM Session Toolset | 2026-06-14 |

---

## Cross-cutting Threads

Issues with no WP home — standalone bugs, deferred discoveries, independent ops items.

| # | Title | Notes |
|---|---|---|
| [#16](../issues/016-lpc-sprite-license-risk.md) | LPC sprite copyleft risk | Legal — blocks #6 |
| [#6](../issues/006-raster-sprite-pipeline.md) | Raster sprite asset pipeline | Blocked on #16 |
| [#85](../issues/085-content-creation-tools-design.md) | Content creation tools — design and scope | Discovery — open; promote to brainstorm before implementation |
| [#141](../issues/141-seeds-decomposition.md) | Decompose seeds.exs into per-concern sub-files | Ops — independent; pick up any time |
| [#148](../issues/148-aoe-saving-throw-prompts.md) | AoE saving throw prompts — multi-owner concurrent rolls | Post-WP-P; depends on #146 |
| [#149](../issues/149-npc-dm-roll-visibility.md) | NPC / DM roll visibility | Post-WP-O; depends on #136 |
| [#160](../issues/160-ui-layer-audit-and-layout-review.md) | UI layer audit — z-index stack and panel layout review | Medium priority — schedule after WP-Q/WP-B front clears |
| [#165](../issues/165-svg-snapshot-test-suite.md) | SVG snapshot test suite for SpriteCompositor | Follow-on to WP-R's #153 (complete) |
| [#63](../issues/063-playwright-smoke-tests.md) | Playwright smoke test suite + smoke Docker environment | Ops — optional fourth test layer, independent |
| [#174](../issues/174-retire-legacy-gibbering-shell-app.md) | Retire the legacy `apps/gibbering` shell app | Medium — Phase 2 leftover; coordinate with #141 (seeds) and #63 (smoke env) |
| [#175](../issues/175-campaign-join-endpoint-robustness.md) | Campaign join endpoint robustness | Standalone bug; pick up any time |
| [#176](../issues/176-damage-type-cast-atom-safety.md) | `DamageType.cast/1` atom safety | Standalone bug; pick up any time |
| [#177](../issues/177-test-compile-warnings-cleanup.md) | Test-compile warnings cleanup | Ops — trivial; includes precommit-gate decision |
| [#178](../issues/178-heroicons-tailwind-path-broken-post-umbrella.md) | Heroicons tailwind plugin path broken post-umbrella | Standalone bug; pick up any time |

---

## Active Front

```
WP-Q:  #156 → (#157, #158)               — coordinate model first, then occupancy + elevation
WP-B:  #152                              — Action struct refactor (no dependencies)
WP-K:  #121 → #122
WP-L:  #124                              — DM top-down viewport (unblocked; WP-S complete)
WP-F:  #84                               — polish, low priority
WP-A:  #24                               — JSONB grid consolidation, low priority
```
