# #61 · Catalogue entry versioning

**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Catalogue is static reference data for now and is fully under platform control. Versioning catalogue entries adds meaningful complexity and is only worth it when editors are actively changing live data that campaigns depend on.
**Priority:** low
**Tags:** discovery, architecture

When support editors update catalogue entries (items, races, classes, spells, etc.) on a live platform, existing characters and campaigns were built against the old values. This issue covers deciding how to handle that divergence.

Candidate approaches:

- **Integer version bump per entry** — each entry carries a `version` integer; characters store the version they resolved against; a mismatch triggers auto-upgrade, a review flag, or is silently ignored (policy TBD).
- **Full audit trail with rollback** — edits create new records; old records are never deleted; characters always resolve against the exact version they reference. Clean but heavier.
- **Coordinated edit policy (no versioning)** — catalogue edits are treated as breaking changes; support editors coordinate with active campaigns before modifying live entries. Simple but requires ops discipline.

**Acceptance criteria**
- [ ] A concrete policy for mismatch handling is chosen
- [ ] The chosen approach is reflected in the catalogue schema and the import/export pipeline
- [ ] Active campaign resolution behaviour on catalogue change is tested
