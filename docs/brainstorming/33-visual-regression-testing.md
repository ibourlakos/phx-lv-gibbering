# Brainstorm #33 — Visual regression testing strategy

**Status:** open

## Context

The game renders everything as SVG streamed from the server. Current SVG tests use string matching (`assert result =~ "fill=\"red\""`), which is brittle and doesn't catch visual regressions — a sprite shifting 5px, a layer rendering in the wrong order, or an HP bar overflowing its bounds all pass string-matching tests.

This brainstorm compares the available approaches before committing to one. Related issues: #153 (SVG data attributes + Floki, in-progress), #63 (Playwright smoke tests, low priority), #165 (SVG snapshot tests, open).

Brainstorm #20 (display testing) covers role-gated and state-dependent correctness. This brainstorm is specifically about **pixel-level or structural regression** — catching unintended visual changes between code changes.

## Approach A — SVG data attributes + Floki (structural, no pixels)

Add semantic `data-*` attributes to every rendered SVG element. Assert in ExUnit with Floki. Already tracked as #153.

- **Cost:** low — pure Elixir, no external tools, no stored images
- **Fidelity:** medium — catches wrong element/layer presence but not coordinate drift
- **Verdict:** do this regardless; prerequisite for the others

## Approach B — SVG snapshot approval tests (exact string diff)

Render `SpriteCompositor.compose(entity, appearances)` for fixed reference inputs; store expected SVG as fixture files; assert exact match. Already tracked as #165.

- **Cost:** low — no external tools; fixtures stored in git
- **Fidelity:** high for compositor output; doesn't test the full LiveView render
- **Verdict:** good regression protection for the compositor layer; do after #153

## Approach C — Property-based testing with StreamData (geometric invariants)

Generate random valid inputs to `IsoProjection` and `SpriteCompositor`; assert invariants rather than exact output: tile always within canvas bounds, entity always has ≥ 1 layer, HP bar within coordinate limits.

- **Cost:** low-medium — StreamData is already available; write generators once
- **Fidelity:** catches edge cases (zero-size maps, corners) that snapshot tests miss
- **Verdict:** strong complement to snapshots for pure math modules; do for `IsoProjection` as a first target

## Approach D — Playwright screenshot comparison (pixel-level, full browser)

Screenshot specific game states after every push; compare against stored baselines. Tools: Playwright's `toHaveScreenshot()` or Percy/Chromatic for hosted diffing. Infrastructure tracked in #63.

- **Cost:** high — needs running Docker in CI, baseline PNGs in Git LFS, human approval for intentional changes
- **Fidelity:** highest — catches CSS regressions, LiveView rendering glitches, layout breakage
- **Verdict:** worth doing once the appearance pipeline stabilizes post-#155; extend #63

## Approach E — SVG-to-PNG pixel comparison (server-side rendering)

Use `librsvg` (Elixir NIF) or headless Chromium to render SVG to PNG in ExUnit tests; compare pixel buffers with a tolerance threshold.

- **Cost:** high — external native dependency (`librsvg`) or Docker-in-tests (headless Chrome); tolerance tuning is non-trivial
- **Fidelity:** catches sub-pixel drift; overkill until appearance pipeline is feature-complete
- **Verdict:** defer until post-GibberingDuels proof; evaluate after Approach D is in place

## Open questions

- [ ] Which canonical game states should Playwright screenshot? (Suggestions: lobby, combat-start, entity-selected, condition-active, fog-of-war-active, dead entity)
- [ ] Percy/Chromatic vs raw Playwright `toHaveScreenshot()`? (Percy has a free tier; raw Playwright requires baseline images in the repo)
- [ ] Should SVG snapshot fixtures be committed to the repo or generated on-demand and compared against a stored checksum?
- [ ] Is `librsvg` the right SVG renderer, or is headless Chrome better for fidelity (CSS support, fonts)?
- [ ] StreamData generators: should they live in `test/support/` or alongside the test files?

## Decisions

*(to be filled as questions settle)*

## Issues to open

*(to be filled after settling)*
