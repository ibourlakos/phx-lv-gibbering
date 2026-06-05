# #59 · Character export/import with versioned serialization
**Status:** deferred
**Opened:** 2026-06-05
**Deferred because:** Needs a stable `Character` schema (#50) before the serialization format can be locked. Export format versioning must be designed once the shape is settled to avoid breaking changes on import.
**Priority:** low
**Tags:** architecture, gameplay

Allow players to export a character as a JSON file and import a previously exported character into their roster.

**Export**
- Produces a self-contained JSON document with an embedded `schema_version` field
- Resolves all catalogue references (race, class, background, spells) to their full data at export time so the file is portable — no dependency on the server's current catalogue version
- Excludes campaign-specific data (`CampaignCharacter` overrides, relations)

**Import**
- Reads `schema_version` and runs any necessary migration before creating the `Character` record
- Validates that referenced catalogue keys (race, class, spells) exist in the current catalogue, or maps them to the closest equivalent
- Treats unknown fields permissively (ignores rather than rejects) for forward compatibility

**Versioning contract**
- `schema_version` is a monotonic integer bumped on every breaking schema change
- A migration module per version handles upgrading old exports
- The current version is the authoritative source for new exports

**Acceptance criteria**
- [ ] "Export" button on a character card downloads a JSON file
- [ ] JSON includes `schema_version` and full resolved character data
- [ ] "Import" button on `/characters` accepts a JSON file
- [ ] Import runs version migration if `schema_version` is older than current
- [ ] Import validates content and shows errors for unresolvable fields
- [ ] Round-trip test: export then import produces an equivalent character
- [ ] `mix precommit` passes
