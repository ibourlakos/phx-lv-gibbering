# Brainstorming

Raw exploration sessions — open-ended discovery before a problem is scoped enough to become an issue.

## Where brainstorming fits

The full workflow has three entry points (see [docs/workflow.md](../docs/workflow.md)):

```
[A] Brainstorm → Settle → Triage ─┐
[B]                      Issue ───┼──► Branch → Red → Green → Refactor → Verify → Commit
[C]                     Branch ───┘

[F] discovery Issue → too broad → Brainstorm (enter [A]) → defer original Issue
```

Enter at **Brainstorm** when a topic is too wide or ambiguous to write a crisp acceptance criterion. Brainstorming maps trade-offs, domain knowledge, or design space before committing to a direction. Once the questions are settled and issues are triaged, the brainstorm feeds into the Issue phase and the rest of the standard flow proceeds unchanged.

A `discovery` issue can also **escalate** into a brainstorm (path [F]) when working it reveals the problem is larger than an issue's scope. In that case: open a brainstorm file, defer the discovery issue referencing the new brainstorm number, and let the brainstorm's extracted issues replace it.

---

## Brainstorm lifecycle

### 1. Open

Create `<NN>-<slug>.md` in this directory (see counter rules below), increment the counter, add a row to the [Active log](#active-log) above, and commit:

```
chore: open brainstorm #N
```

### 2. Explore

Discussion sessions populate the document. Accumulate open questions, design options, and trade-offs. No commit required per session — the document is a working draft.

### 3. Settle

Work through each open question. Every question must resolve to one of:

- **Decision** — the chosen direction, documented in a Decisions table in the file
- **Explicit deferral** — noted with a reason; becomes a deferred issue or a note for a future brainstorm

A question left neither decided nor deferred is not settled. Do not proceed to Triage until all questions are settled.

### 4. Triage

Translate each settled decision into one or more issues in `docs/issues/`. Each issue gets acceptance criteria. Update the brainstorm document to reference the opened issue numbers and note that issues have been filed.

### 5. Commit

Commit the updated brainstorm document and all new issue files in **one atomic commit**:

```
chore: brainstorm #N → issues #X–Y
```

**Gate:** No open question without a decision or explicit deferral. A partially triaged brainstorm is not committed.

### 6. Close

Once all issues extracted from this brainstorm are closed or deferred in `docs/issues/`, the brainstorm has served its purpose:

1. Delete the `<NN>-<slug>.md` file
2. Remove its row from the [Active log](#active-log) above
3. Commit:

```
chore: close brainstorm #N
```

The issues are the durable record. The brainstorm transcript is not.

---

## Active log

| # | File | Topic | Status |
|---|---|---|---|
| 18 | [18-inspection-panel.md](18-inspection-panel.md) | Inspection / Detail Panel — click-to-inspect map elements, selection model, role gating | open |
| 19 | [19-unified-action-model.md](19-unified-action-model.md) | Unified Action Model — general Action struct covering spells, attacks, improvised, social | open |
| 20 | [20-display-testing.md](20-display-testing.md) | Display Testing — verifying role-gated and state-dependent SVG output | open |
| 21 | [21-movement-action-gate-and-cost-overlay.md](21-movement-action-gate-and-cost-overlay.md) | Movement action gate + cost-coloured overlay — on-demand overlay, terrain cost feedback | open |
| 22 | [22-dm-entity-panel-redesign.md](22-dm-entity-panel-redesign.md) | DM entity panel redesign — right panel as catalog, adjustments in left panel DM tab | open |
| 25 | [25-elevation.md](25-elevation.md) | Elevation — logical Z, SVG render sort, structure interiors, line of sight | open |
| 26 | [26-tile-occupancy-and-traversability.md](26-tile-occupancy-and-traversability.md) | Tile occupancy and traversability — 5-category taxonomy, effects layer, computed traversability, ice slip test case | open |
| 27 | [27-coordinate-model-and-spatial-addressing.md](27-coordinate-model-and-spatial-addressing.md) | Coordinate model and spatial addressing — tile grain, elevated surfaces, interior spaces, teleportation destinations | open |
| 28 | [28-player-dice-roll-prompt-and-auto-roll.md](28-player-dice-roll-prompt-and-auto-roll.md) | Player dice roll prompt + auto-roll preference — pending-roll state, prompt UI, per-player toggle | open |
| 29 | [29-spinoff-plans-1-6.md](29-spinoff-plans-1-6.md) | Spinoff game mode concepts — Plans 1–6 (Autobattler, Darkest Dungeon, Deckbuilder, Terrain Wrangling, Co-op Raid, Roguelike Tower) | open |
| 30 | [30-spinoff-plan-7-expedition-chronicle.md](30-spinoff-plan-7-expedition-chronicle.md) | Spinoff Plan 7 — The Expedition Chronicle: structured objective-based adventure mode with Rift Stability, Leader role, Paragon Ranks, Chronicle narration | open |
| 31 | [31-freeform-dice-tray.md](31-freeform-dice-tray.md) | Freeform dice tray — player-initiated multi-die roll, die picker UI, sequential stagger animation, always-public event feed | open |
| 32 | [32-gibbering-duels-concept.md](32-gibbering-duels-concept.md) | GibberingDuels concept game — engine decomposition proof, minimal 2-player card-placement game implementing GibberingEngine.Ruleset with zero D&D imports | open |
| 33 | [33-visual-regression-testing.md](33-visual-regression-testing.md) | Visual regression testing strategy — Playwright screenshots, SVG-to-PNG pixel diffing, property-based geometric invariants; trade-off comparison for five approaches | open |
| 34 | [34-actor-vs-entity-terminology.md](34-actor-vs-entity-terminology.md) | Actor vs Entity terminology — runtime scene participant vs persistent domain object; engine concern update; OTP naming caveat | open |
| 35 | [35-proportion-driven-skeleton-and-attachment-sockets.md](35-proportion-driven-skeleton-and-attachment-sockets.md) | Proportion-driven skeleton and attachment sockets — continuous proportion params, derived socket map, item attachment rotation | open |
| 36 | [36-ai-memory-hygiene-from-ploi-reacher.md](36-ai-memory-hygiene-from-ploi-reacher.md) | AI memory hygiene — context-budget tiers, agent-behavior charter, brainstorm/issue lifecycle discipline (mini epic, adopted from ploi-reacher) | settled — ready for triage |

Next brainstorm number: see `counter`.

---

## Counter rules

- Next number is in `counter` (plain integer)
- Filenames: `<NN>-<slug>.md` zero-padded to two digits (e.g. `07-fog-of-war.md`)
- Increment `counter` after creating a new file
- Never reuse a number, even for deleted files

---

## Brainstorm file structure

No rigid template — content is exploratory. Conventions that have worked well:

- Lead with a **Context** or framing section explaining why this brainstorm exists
- Use `##` sections per topic area
- Accumulate open questions as a bulleted list during exploration
- Replace the open questions list with a **Decisions** table once settled
- End with an **Issues Opened** section (or **Issues to Open** before triage) that links to the filed issues
- Note any cross-brainstorm dependencies with a pointer to the other file
