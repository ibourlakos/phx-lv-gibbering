# #8 · `String.to_existing_atom` crash in data pipeline parser

**Status:** closed
**Opened:** 2026-06-04
**Closed:** 2026-06-05
**Priority:** medium
**Tags:** bug

`parse_action_damage` in the pipeline brainstorm (`01-initial-gemini.md`) converts damage type strings with `String.to_existing_atom(t)`. This raises `ArgumentError` if the atom has not been loaded into the VM yet — which is guaranteed on a fresh boot before any game data is compiled in. Every SRD damage type (`:slashing`, `:piercing`, `:fire`, etc.) would crash the first pipeline run.

Fix: use a pattern-matched safe conversion against a known allow-list, or a `Map.fetch/2` from a module attribute that declares all valid damage types at compile time.

**Acceptance criteria**
- [x] Damage type conversion never raises on valid SRD damage type strings
- [x] Unknown damage type strings produce a tagged error tuple, not a crash
- [x] Unit tests cover all SRD core damage types and at least one unknown string
