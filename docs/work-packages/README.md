# Work Packages

One file per work package: `docs/work-packages/wp-<letter>.md`. This file is the index only.

A work package groups related issues by concern and establishes sequencing within that concern. See [docs/workflow.md](../workflow.md) ([E] subflow) for creation, maintenance, and completion rules.

**Next letter:** Q

---

## Active

| WP | Title | Open Issues |
|---|---|---|
| [WP-O](wp-o.md) | Inspection Panel & Player Event Feed | #134, #135, #136, #137, #132 |
| [WP-P](wp-p.md) | Minimum Playable Campaign Loop | #139, #142, #143, #144, #145, #146, #147 |
| [WP-A](wp-a.md) | Infrastructure & Data Plumbing | #24 |
| [WP-B](wp-b.md) | Core Engine Architecture | #15 |
| [WP-F](wp-f.md) | Rendering & Frontend | #125, #21, #84 |
| [WP-K](wp-k.md) | Spectator Implementation | #121 → #122 |
| [WP-L](wp-l.md) | DM Projection & Top-Down Viewport | #123 → #124 |

---

## Parked

| WP | Title | Reason |
|---|---|---|
| [WP-I](wp-i.md) | Monitoring | Deferred until core game loop is stable |

---

## Complete

| WP | Title | Completed |
|---|---|---|
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
| [#19](../issues/019-lobby-edits-stale-gameserver.md) | Lobby edits don't propagate to running GameServer | Bug — no WP home yet |
| [#32](../issues/032-dm-override-event-schema.md) | DM override event schema and god-mode mechanics | Discovery — deferred; revisit when DM intervention scope expands |
| [#33](../issues/033-templates-governance-model.md) | Templates governance model | Discovery — deferred |
| [#63](../issues/063-playwright-smoke-tests.md) | Playwright smoke tests + smoke Docker env | Ops — deferred |
| [#85](../issues/085-content-creation-tools-design.md) | Content creation tools — design and scope | Discovery — open; promote to brainstorm before implementation |
| [#120](../issues/120-items-data-population.md) | Items data module population | Deferred — blocked on content pipeline decisions |

---

## Active Front

```
WP-F:  #125 → (#21, #84)                   — tile decoration first, then polish items
WP-K:  #121 → #122                         — spectator membership model first, then session view
WP-L:  #123 → #124                         — Projection behaviour first, then DM top-down viewport
WP-O:  #134 → #135                         — rename first, then left panel
       #136 → #137                         — visibility taxonomy first, then right panel
       #132 (parallel, feeds both panels)
WP-P:  #139                                — DM orphaned PC fix (prerequisite for solo-play)
       #142 → #143                         — outcome phases then outcome screen
       #144 (after WP-F #125)              — movement confirmation UI
       #145 → #146 → #147                  — auto-roll preference, dice prompt, then initiative prompt
```

WP-P has one cross-package dependency: `#144` should follow WP-F `#125`. All other WP-P chains are independent.
