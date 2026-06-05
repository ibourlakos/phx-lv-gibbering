# #45 · Attack roll vs AC (replace bare 1d6 in `Rules.attack/3`)

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** high
**Tags:** rules, gameplay

`Rules.attack/3` rolls a bare `Enum.random(1..6)` — no d20 attack roll, no
attack bonus, no AC comparison, no miss path. This is the most visible rules
gap in the engine. A hit should require `d20 + attack_bonus >= target.armor_class`.

Depends on #38 (`DnD5e.Stats` for `attack_bonus` and `armor_class`).

**Acceptance criteria**
- [ ] `Rules.attack/3` rolls d20, adds attacker's `attack_bonus` (from `DnD5e.Stats`), compares against target's `armor_class`
- [ ] Natural 20 is always a hit (critical) regardless of AC; natural 1 is always a miss
- [ ] Critical hit doubles the number of damage dice rolled
- [ ] On a miss, no damage is applied; function returns `{:miss, roll_details}` 
- [ ] On a hit, correct weapon damage dice rolled (`stats["equipped_weapon"]["damage_dice"]` or unarmed 1d4 fallback)
- [ ] Roll details included in the return: `%{roll: integer, bonus: integer, total: integer, target_ac: integer, hit: boolean, critical: boolean, damage: integer | nil}`
- [ ] Unit tests: guaranteed hit (d20=20), guaranteed miss (d20=1), normal hit, normal miss, critical
- [ ] `mix precommit` passes
