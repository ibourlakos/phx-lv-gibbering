# #52 · Character creation multi-step modal
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** gameplay, rendering

A multi-step modal overlaid on the `/characters` roster page (no separate route). The player steps through character creation and the result is saved as a new `Character` record on completion. No navigation away from the roster.

**Steps**

1. **Appearance** — body type, head features, hair style, hair colour, skin tone, eye colour. Live SVG preview updates as choices are made (uses composable appearance system — #53).
2. **Identity** — name, race, class, background, alignment. Race selection constrains appearance options in step 1 (user may be sent back with a note, or constrained choices update live).
3. **Ability scores** — assign the standard array (15, 14, 13, 12, 10, 8) to the six abilities. Race bonuses shown as a preview (applied at campaign instantiation, not stored on template).
4. **Proficiencies** — shows auto-granted proficiencies from class + background; player makes any free-choice picks (e.g. skill selections, background language slots, duplicate replacements).
5. **Personality** — traits, ideals, bonds, flaws. Background suggestions shown as a starting point; player edits freely.
6. **Review** — full character sheet summary. Confirm to save.

**Acceptance criteria**
- [ ] Modal opens from the "New Character" button on `/characters`; roster remains visible behind it
- [ ] Step navigation: forward, back, and step indicator
- [ ] Appearance preview renders live as options change
- [ ] Race selection in step 2 constrains appearance options
- [ ] Standard array assignment validates all six scores are assigned before proceeding
- [ ] Proficiency conflicts (class + background duplicate) resolved with a free replacement pick
- [ ] Review step shows a complete summary before save
- [ ] On save, character appears in the roster and modal closes
- [ ] Partial state is not persisted if the user cancels
- [ ] `mix precommit` passes
