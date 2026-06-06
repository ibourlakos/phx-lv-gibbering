# #46 · Equipped weapon/armor in `stats` JSONB + seed data

**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** low
**Tags:** rules, gameplay

`DnD5e.Stats.armor_class/1` and `Rules.attack/3` (after #45) both need
equipped item data. Currently `stats` JSONB has no weapon or armor keys.
Seed data must be updated so test scenarios have equipped gear.

Depends on #45 (attack roll vs AC needs weapon data).

**Acceptance criteria**
- [x] `stats` JSONB for seeded hero entities includes `"equipped_weapon"` with `key`, `damage_dice`, `damage_type`, `attack_ability`, `properties` (list of weapon property atoms)
- [x] `stats` JSONB for seeded hero entities includes `"equipped_armor"` with `key`, `base_ac`, `armor_category`, `stealth_disadvantage`
- [x] Monster entities have appropriate weapon/armor seeds
- [x] `DnD5e.Stats.armor_class/1` reads equipped armor and falls back to `10 + dex_modifier` when absent
- [x] Lobby character setup preserves existing `stats` keys when saving a slot
- [x] `mix precommit` passes
