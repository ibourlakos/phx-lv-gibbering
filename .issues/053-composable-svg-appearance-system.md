# #53 · Composable SVG appearance system
**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** rendering, architecture

Replace the flat `"{race}_{class}"` sprite key convention with a composable appearance system. A character's sprite is assembled from ordered SVG layers at render time, targeting **Don't Starve Together fidelity**: bold outlines, stylised proportions, expressive enough to distinguish race features, hair style, and equipped gear at a glance — not photorealistic, not crude placeholders.

This system is used in three places: the character creation modal preview (#52), the `/characters` roster cards (#51), and the in-game entity sprite on the board.

## Layer stack (bottom to top)

| Layer | Driven by | Notes |
|---|---|---|
| Body silhouette | `body_type` + armour class | Shape changes with light / medium / heavy armour |
| Clothing / armour | equipped armour key | Visual differentiation between armour tiers |
| Arms + weapon | equipped weapon key | Dominant hand holds the weapon; off-hand holds shield if equipped |
| Head base | `head` (race-constrained) | Elven pointed ears, dwarven proportions, etc. |
| Hair | `hair_style` + `hair_color` | Palette-keyed colour fill |
| Face | `skin_tone` + `eye_color` | Minimal features — eyes readable at tile scale |
| Accessories | cloak, hat, misc | Optional overlay items |

## Inputs

The component takes two maps:

```elixir
appearance: %{
  body_type:  "stocky" | "slender" | "large",
  head:       "angular" | "round" | "elven" | "dwarven" | ...,  # race-constrained
  hair_style: "short" | "long" | "braided" | "bald" | ...,
  hair_color: "auburn" | "black" | "blonde" | "white" | "silver" | ...,
  skin_tone:  1..8,       # index into a fixed palette
  eye_color:  "brown" | "blue" | "green" | "silver" | "amber" | ...
}

equipment: %{
  armour_class: "unarmoured" | "light" | "medium" | "heavy",
  weapon:       nil | "dagger" | "sword" | "axe" | "staff" | "bow" | ...,
  shield:       boolean
}
```

`equipment` is derived from the character's equipped items at render time — it is not stored on the appearance map, which stays purely cosmetic.

## Art constraints

- All SVG paths must be original artwork — no raster assets, no third-party art (see `docs/legal.md`)
- Use a fixed, named colour palette for fills; avoid free hex colours to keep art coherent
- Sprites must read clearly at the isometric tile scale (~48×64px viewport)
- Bold outlines (DST-style dark stroke) aid readability at small sizes

**Acceptance criteria**
- [ ] `GibberingWeb.Components.CharacterSprite` function component accepts `appearance` and `equipment` maps and renders a layered SVG
- [ ] All seven layers implemented; each layer is an independent SVG `<g>` composited in order
- [ ] Armour class visibly differentiates the body silhouette (unarmoured vs light vs medium vs heavy)
- [ ] Equipped weapon visible in hand; shield visible on off-hand when equipped
- [ ] Race constrains valid `head` options — invalid combinations fall back gracefully
- [ ] Hair style and colour are visually distinct across options
- [ ] Face layer is readable at tile scale (eyes distinguishable)
- [ ] Component is reusable across character creation preview, roster cards, and game board
- [ ] Existing game board rendering continues to work (migration path from old sprite keys)
- [ ] `mix precommit` passes
