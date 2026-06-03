# Legal Reference

> Any unresolved legal issue is a blocker. Do not ship content, assets, or integrations until the applicable category below is checked.

---

## 1. Game Rules & Content (D&D / SRD)

**Status: Covered.**

Uses D&D 5e SRD 5.1 under CC-BY-4.0 (irrevocable). See `.claude/brainstorming/initial-gemini.md` for the full breakdown of what is and is not safe.

`Gibbering.Pipeline.LegalGuard` filters WotC Product Identity at ingestion time.

**Watch for:**
- Adding content from non-SRD sourcebooks (Xanathar's, Tasha's, etc.) — not covered by CC-BY-4.0
- Adding other RPG systems (Pathfinder, Cyberpunk RED, etc.) — each has its own license; check before implementing
  - Pathfinder: ORC License (permissive, but read the terms)
  - Cyberpunk RED: proprietary — no free use without a publishing agreement

---

## 2. Art Assets (Sprites, Tilesets, Fonts)

**Status: Open — must be resolved before any asset is committed.**

Every image, sprite sheet, tileset, icon, and font file must have a verified license. Acceptable licenses:

| License | Usable | Attribution required |
|---|---|---|
| CC0 (Public Domain) | Yes | No |
| CC-BY 4.0 | Yes | Yes — credit in README/about screen |
| CC-BY-SA 4.0 | Yes (with care) | Yes — derivatives must stay SA |
| MIT / Apache 2.0 (code-bundled assets) | Yes | Yes |
| Royalty-free (purchased) | Yes | Per terms |
| CC-BY-NC | **No** — prohibits commercial use |  |
| All Rights Reserved | **No** |  |

**Do not** use assets from Google Image Search, Pinterest, itch.io asset packs, or game rips without verifying the license explicitly.

Good sources for legally clean pixel art: [OpenGameArt.org](https://opengameart.org) (filter by CC0/CC-BY), [Kenney.nl](https://kenney.nl) (CC0).

Fonts: check [Google Fonts](https://fonts.google.com) (OFL — permissive) or [Font Squirrel](https://www.fontsquirrel.com) (filter "100% free").

---

## 3. Data Sources

**Status: Verify before each integration.**

| Source | License / Terms | Notes |
|---|---|---|
| Open5e API | CC-BY-4.0 (mirrors SRD data) | Verify their ToS; do not cache in a way that re-distributes their infrastructure |
| 5e-database (GitHub) | CC-BY-4.0 | Safe for local ingestion |
| D&D Beyond / Roll20 / Foundry data exports | Proprietary | **Never ingest** |
| Homebrew wikis (Fandom, etc.) | Mixed — often All Rights Reserved | **Do not ingest without per-item verification** |

---

## 4. Software Dependencies

**Status: Automated — review on major dependency additions.**

Hex packages must be compatible with the project's intended license. GPL-licensed libraries force the whole project to be GPL — avoid unless intentional.

Safe dependency licenses: MIT, Apache 2.0, ISC, BSD, MPL 2.0.

Run `mix licenses` (via the `licensir` package) to audit dependency licenses. Add it to the CI pipeline.

---

## 5. User Data & Privacy

**Status: Deferred — required before any public deployment.**

If the game stores user accounts or session data:
- **GDPR** applies if any EU users are served — requires a privacy policy, data deletion mechanism, and lawful basis for processing.
- **COPPA** applies if users under 13 are possible — requires parental consent flows.
- Minimum: no analytics, no third-party trackers, no persistent cookies beyond session auth until a privacy policy is in place.

---

## 6. Multiplayer & User-Generated Content

**Status: Deferred — required before opening public lobbies.**

If players can upload homebrew content (maps, custom monsters, art):
- The platform must have a ToS that prohibits infringing uploads and includes a DMCA takedown process.
- Do not train AI models on user-uploaded content without explicit consent.

---

## 7. The `LegalGuard` Module — Scope

`Gibbering.Pipeline.LegalGuard` is currently scoped to WotC Product Identity. Its scope should expand to:

1. WotC PI blacklist (current)
2. A per-source license tag — every ingested entity should carry `source_license: "CC-BY-4.0"` so downstream code can assert it
3. A flag for `requires_attribution: true` so the UI can surface credits where needed