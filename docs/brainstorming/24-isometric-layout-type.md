# Brainstorm #24 — Isometric layout type

**Status:** open

## Context

The current engine renders an isometric map in the **rhombus layout**: the grid
is a floating diamond shape on a dark canvas. An alternative is the **chessboard
(diamond-grid) layout**: the grid is rotated 45° relative to the monitor edge,
filling the viewport as a rectangle.

The choice is load-bearing — it affects SVG coordinate math, pan/scroll UX,
map border feel, and how the HUD and side panels interact with the game area.

## Rhombus layout (current)

- Map appears as a diamond floating in a dark surround
- Grid axes run diagonally to the monitor edges
- Sorting (painter's algorithm) is straightforward: back-to-front = increasing X+Y
- Large triangular dead zones in screen corners
- Scrolling large maps feels diagonal relative to the monitor
- Strong "diorama" or "encounter mat" aesthetic — bounded, scene-like

## Chessboard layout

- Map fills a rectangle aligned to monitor edges
- Grid axes still run diagonally, but map boundary is rectangular
- Better use of widescreen real estate
- Zig-zag boundary at map edges complicates border rendering
- Feels more like an open world or scrollable dungeon
- Standard for games like Diablo, Age of Empires

## Factors specific to this engine

- **Encounter scope**: maps are bounded tactical scenes, not open worlds.
  The rhombus layout's diorama feel suits this better than a sprawling rectangle.
- **HUD integration**: side panels and turn tracker border the game area.
  Rhombus leaves natural dark space beside the diamond for panels to sit.
  Chessboard would require panels to overlap or push the map.
- **Backend rendering**: coordinate math changes across the entire rendering
  pipeline if we switch. This decision should be locked in before significant
  rendering work is done.
- **Viewport rotation**: if we ever support 90° camera rotation (per-player),
  the rhombus rotates cleanly as a diamond; the chessboard would shift
  where the zig-zag boundaries fall.

## Open questions

- Is the dark surround in the rhombus layout a feature (scene boundary) or
  a waste of screen space?
- Can a chessboard layout still achieve a bounded "encounter mat" feel with
  an explicit border or vignette treatment?
- If maps can vary in aspect ratio (long corridor vs. square room), does the
  rhombus layout become awkward for non-square maps?
- Does the choice affect how we render the map edge itself (cliff edge, void,
  dungeon wall)?

## Cross-references

- Related: brainstorm #23 (entity proportions depend on tile diamond height)
- Related: brainstorm #25 (elevation render sort interacts with coordinate axes)
