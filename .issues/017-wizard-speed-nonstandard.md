# #17 · Wizard speed is non-standard (25 ft instead of 30 ft)

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-05
**Priority:** low
**Tags:** bug, rules

The Proving Grounds seed sets Wizard speed to `"speed" => 25` (5 tiles). Standard D&D 5e Wizards have a 30 ft base walking speed (6 tiles), identical to most other classes. The 25 ft value was set without comment and makes the prototype inaccurate as an SRD rules demo.

If there is a deliberate game-balance reason to give Wizard a shorter range (e.g. to differentiate it from Warrior before the Wizard gets spells), that reason should be recorded here. Otherwise, correct the seed to 30 ft.

**Acceptance criteria**
- [x] Seeds now derive speed from `Gibbering.Data.Races.base_speed/1`; elf speed = 30 ft. The old hardcoded 25 ft value is gone.
