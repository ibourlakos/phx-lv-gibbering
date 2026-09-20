# #35 · Proportion-driven skeleton and attachment sockets

## Context

A DeepSeek chat (transcript: see conversation history, not reproduced here) explored asset
pipelines for a stylised (Don't Starve / Tim Burton-lite / comic-book, "scary death knight,
fun gnome rogue") tactical visualizer, assuming a 3D mesh/rig pipeline (Blender, Blockbench,
Mixamo, procedural primitives, glTF). This repo renders flat 2D inline SVG, not 3D meshes, so
most of that chat's tooling discussion (Blender vs. alternatives, mesh authoring, back-face
outline extrusion, normal-based shading bands) doesn't transfer directly — there is no mesh to
plug those tools into, and pivoting to 3D meshes is not on the table here.

What *does* transfer is the design insight underneath it: stylised character variety is cheap
when it's driven by **parameters** (proportion, palette, silhouette) rather than by authoring
more geometry per character. This project independently arrived at and already shipped a
version of that insight for palette/style (#98, #99, #180 — closed). This brainstorm scopes
the one piece that chat surfaced which is **not** yet covered: a true skeleton with named,
proportion-aware attachment points, so equipment renders attached to a unit correctly instead
of being baked into per-archetype template art.

## What already exists (don't re-solve this)

- **`AppearanceArchetype`** (#155, #180 — closed): archetype (`biped_upright`, `quadruped`,
  `swarm`, `elemental_amorphous`, `structure`) → **socket map**: `%{socket_name =>
  %{north: {dx,dy}, south: {dx,dy}, east: {dx,dy}, west: {dx,dy}}}`. West = East +
  `scaleX(-1)`. Layer order varies per facing (e.g. shield behind body facing north).
  Size category (1×1/2×2/3×3) scales socket offsets proportionally.
- **`silhouette`** dimension (#180 — closed): `:humanoid` / `:goblinoid` / `:undead_gaunt` /
  `:giant` — a **fixed 4-value enum**, each with its own hand-authored `.svg.eex` template
  per style/archetype/facing/layer, falling back to the `dst` style template when a style
  hasn't authored that combination.
- **Style system** (#98/#99 — closed): `styles`/`appearances` tables, palette JSONB per
  style, style = data not code. Two styles shipped (`dst`, `carbot`).
- **Equip mechanics** (#128 — closed): `equipped_weapon`/`equipped_armor` feed
  `RuleModifier`s (AC, attack bonus, etc.) via `collect_modifiers/3`. This is the *rules*
  layer — it has no relationship to where a weapon renders on the sprite.

**The gap:** sockets today are a fixed per-facing anchor point authored once per
archetype/silhouette combination. There is no notion of a posable joint hierarchy, no
continuous proportion parameters (head scale, limb length/thickness, torso width), and no
single source of truth an item template and a body template can both agree on for "where does
a weapon sit in `hand_r`" across arbitrary proportion variation. Adding a 5th silhouette today
means hand-authoring a new template tree per style; there's no way to get a "big-headed gnome"
and a "broad-shouldered death knight" out of the *same* silhouette by turning knobs.

## Open questions

- **Is a jointed skeleton worth it for 2D SVG, or is the existing socket-map-per-facing model
  sufficient once given continuous proportion params?** A full skeleton (rotatable joints,
  forward kinematics) is a 3D-rig concept; in flat SVG, "skeleton" more likely means: a named
  hierarchy of anchor points (`root → torso → shoulder_r → hand_r`) with a *relative* offset
  and a *scale* per node, computed once per (archetype, silhouette, proportion_profile,
  facing) and cached, rather than reposed live per frame.
- **Where do proportion profiles live?** As a new field on `silhouette` (still an enum but
  each variant now carries numeric proportion params), or as a fully separate `proportion_profile`
  dimension orthogonal to silhouette (so silhouette = body-plan topology, proportion = scale
  knobs on that topology)? The DeepSeek chat's examples (gnome rogue: `head_scale: 1.4`,
  death knight: `shoulder_width: 1.8`) suggest the latter — topology and proportion are
  separable concerns.
- **Do attachment sockets need to move under idle animation/wobble, or is a static anchor per
  facing enough for v1?** Current active-effects/animation system (see
  `docs/architecture/features/active-effects.md`) drives some motion via `push_event`; sockets
  that must track a swaying arm are a materially harder problem than sockets that are static
  per facing.
- **Does this replace or extend the existing socket map?** Likely extend: keep
  `%{socket_name => %{facing => {dx,dy}}}` as the *resolved output* for a given proportion
  profile, but compute it from a smaller set of proportion parameters instead of hand-placing
  every socket per silhouette per style. This keeps `.svg.eex` template authoring unchanged
  for artists while making socket placement derivable instead of duplicated per style.
- **Item attachment: rotation, not just position?** A sword in `hand_r` may need a facing-
  dependent rotation/flip in addition to an offset (DeepSeek's "slight rotation offset" wobble
  note applies here too — a weapon sitting at a perfect 90° reads as stiffer than one with a
  few degrees of cant). Current socket map is position-only (`{dx, dy}`); worth deciding if
  rotation belongs in the same tuple or a separate field.
- **Palette/proportion authoring discipline** (secondary, smaller than the skeleton question):
  DeepSeek's "4–6 colors max, one dominant + one accent + skin + outline" and "exaggerate one
  or two proportion features, not all of them" are authoring *guidelines*, not schema changes.
  Worth writing into a style-authoring doc (candidate: a new section in
  `docs/architecture/features/svg-rendering.md` or a dedicated style-authoring guide) once a
  second/third style author besides `dst`/`carbot` is anticipated, but this doesn't need a
  schema or issue on its own — flag as a documentation follow-up, not a design decision.

## Non-goals for this brainstorm

- 3D mesh authoring, Blender/Blockbench/Mixamo tooling, glTF import — not applicable to a 2D
  SVG renderer; out of scope unless a future brainstorm proposes moving to 3D meshes.
- Normal-based toon shading bands — no normals exist in flat SVG; any "banded shading" look
  here would be a gradient/duotone fill technique, a different (smaller) idea than what
  DeepSeek described, not pursued here.
- Procedural geometry generation (primitives-as-code instead of hand-authored `.svg.eex`) —
  current templates are hand-authored per style deliberately (art direction control per #98);
  not proposing to replace that.

## Status

Open. Not settled — no decisions table yet. Revisit once the open questions above have
answers; expect this to triage into at least one issue covering "proportion parameters +
derived socket map" and possibly a second, smaller one for socket rotation/cant.
