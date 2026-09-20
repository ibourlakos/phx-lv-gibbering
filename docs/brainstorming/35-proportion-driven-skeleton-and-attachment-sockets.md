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

**Mesh and skeleton are not the same axis, and it's worth being precise about that up front.**
"Mesh" answers a rendering-technology question — what the geometry is made of (vertices/
triangles vs. flat SVG paths). "Skeleton" answers an authoring/attachment question — a named
hierarchy of anchor points that geometry hangs off of and that other things (items) attach to.
A skeleton requires no mesh at all: a hierarchy of named 2D anchor points that SVG shapes and
item templates both key off of is a skeleton with zero 3D content. What's out of scope here is
mesh (see Non-goals); skeleton-as-attachment-hierarchy is squarely in scope and is the actual
subject of this brainstorm. The existing socket map (below) is already a primitive, flat
version of a skeleton — named anchors, but no parent/child hierarchy and no cross-archetype
resolution.

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

## Role-based socket resolution (cross-archetype attachment)

Prompted by a concrete case: a shield usable the normal way by a humanoid (gripped in a hand)
but also mountable on a bear (`quadruped`), on its back or flank — two topologically different
skeletons, different natural mount points, same item. Naively this is
O(items × archetypes) of hand-tuned special cases. The practice that avoids that, drawn from
how existing engine/rig tooling (Unreal socket tags, Source engine attachment points, Unity's
Humanoid avatar retargeting, 2D skeletal tools like Spine) handles this class of problem:

1. **Sockets are named by semantic role, not by a specific bone.** `grip_primary`,
   `mount_dorsal` (back), `mount_lateral` (flank) — not `hand_r` directly. Each skeleton
   publishes its own role → local-bone mapping. A biped exposes `grip_primary → hand_r`; a
   quadruped has no `grip_primary` but exposes `mount_dorsal → torso_top` and
   `mount_lateral → flank_r`.
2. **A socket is a transform, not a point.** Position *and* rotation *and* scale — not just
   `{dx, dy}`. A shield gripped in a hand orients edge-out; mounted on a back it lies flat,
   rotated ~90° from the grip orientation. Without an orientation basis per socket, every new
   mount context needs a hand-tuned rotation hack; with one, the item's geometry stays a single
   asset and the socket supplies the reorientation.
3. **Items declare which roles they support, in fallback preference order** — not the other
   way around. `shield: [grip_primary, mount_dorsal]`. The skeleton/render pipeline has zero
   built-in knowledge of "shield" as a concept, matching how this codebase already keeps styles
   and archetypes content-agnostic (#98/#99/#180). A shield with no valid grip on a bear falls
   through automatically to `mount_dorsal` — no special-casing "shield on bear" anywhere.
4. **Different body plans get different bone vocabularies, unified only at the role layer.**
   `biped_upright` and `quadruped` don't (and shouldn't) share bone names — a bear has no
   `hand_r` to force a shield into. The vocabularies stay separate; roles are the only shared
   surface between them.
5. **This turns an O(items × creatures) authoring problem into O(items) + O(creatures).**
   Adding a new body plan means authoring its role→bone map once; every existing item whose
   role list includes a role that new skeleton supports just works, no per-pair authoring.
6. **Composes with proportion params (see below):** sockets are defined in *normalized* local
   space (e.g. a fraction along a limb or of torso width) and scaled into actual offsets by the
   proportion profile at render time — the same socket definition works for a big-headed gnome
   and a broad-shouldered death knight without per-character tuning.

This section is descriptive of the target practice, not a settled decision yet — see open
questions below for what's still unresolved before this becomes an issue.

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
- **Item attachment: rotation, not just position?** Settled in direction, not in schema: per
  the role-based resolution section above, a socket should carry a full local transform
  (offset + rotation + optional flip/scale), not just `{dx, dy}` — needed both for cross-
  archetype mounting (grip vs. back-mount orientation differ) and for per-facing cant (a sword
  sitting at a perfect 90° reads stiffer than one with a few degrees of cant, per the DeepSeek
  "wobble" note). Still open: does this live as a 3rd/4th tuple element on the existing map, or
  a small struct (`%Socket{offset: {dx,dy}, rotation: deg, flip: bool}`) — struct is likely
  cleaner once role-based fallback and normalized/proportion-scaled coordinates are in play.
- **Role vocabulary and fallback list format:** where do per-archetype role→bone maps and
  per-item role preference lists live — on `AppearanceArchetype` (engine-side, content-
  agnostic per `docs/architecture/engine-decomposition.md`) vs. on `Data.Items` (content-side,
  alongside the existing `modifiers` field from #128)? Likely items own their role preference
  list (content) and each archetype owns its role→bone map (engine, since it's about body-plan
  topology, not any specific item) — mirrors the existing split between `ActorAppearance`
  (engine) and `TemplateStore`/seed data (content) from #180.
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

## Related brainstorms and issues

- **[34-actor-vs-entity-terminology.md](34-actor-vs-entity-terminology.md)** (open) — directly
  overlapping surface: proposes renaming/reframing `AppearanceArchetype` → `ActorAppearance` as
  the engine's game-agnostic composable-visual-layer model. Any skeleton/socket work here lands
  in that same module — settle #34's naming/scope first, or at least in lockstep, so this
  brainstorm's proposals don't get authored against a name that's about to change.
- **[085-content-creation-tools-design.md](../issues/085-content-creation-tools-design.md)**
  (open) — scopes an item editor with "preview rendering (render the content using the live
  SVG pipeline)." A role-based socket model changes what an item editor needs to capture (role
  preference list, per-role transform overrides) — worth a cross-reference once #85's editor
  scoping resumes, so socket/role authoring isn't designed twice.
- **[120-items-data-population.md](../issues/120-items-data-population.md)** (deferred, blocked
  on #80) — populates `Data.Items` with ≥20 SRD items and per-item appearance records. Once
  un-deferred, item records should carry the role preference list this brainstorm proposes
  (`shield: [grip_primary, mount_dorsal]`) from the start rather than retrofitting 20+ items
  later.
- **#98 / #99 / #155 / #180** (all closed) — see "What already exists" above; this brainstorm
  extends that lineage rather than replacing it.
- **#128** (closed) — `RuleModifier` equip mechanics; explicitly *not* the same concern (rules
  vs. visual attachment) but the item-side data shape (`Data.Items` gaining a `modifiers` field)
  is the precedent for where a role preference list would similarly live.

## Status

Open. Not settled — no decisions table yet. Revisit once the open questions above have
answers; expect this to triage into at least one issue covering "proportion parameters +
derived socket map" and possibly a second, smaller one for socket rotation/cant.
