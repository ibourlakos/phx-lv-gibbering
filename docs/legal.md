# Legal Reference

> Any unresolved legal issue is a blocker. Do not ship content, assets, or integrations until the applicable category below is checked.

---

## 1. Game Rules & Content (D&D / SRD)

**Status: Covered.**

Uses D&D 5e SRD 5.1 under CC-BY-4.0 (irrevocable). The full breakdown of what is and is not safe is covered in the SRD itself and summarised in the LegalGuard module.

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
| CC-BY-SA 3.0 / 4.0 | Yes | Yes — see ShareAlike rules below |
| MIT / Apache 2.0 (code-bundled assets) | Yes | Yes |
| Royalty-free (purchased) | Yes | Per terms |
| GPL 2.0 (as asset license) | **No** — see LPC ruling below |
| CC-BY-NC | **No** — prohibits commercial use |  |
| All Rights Reserved | **No** |  |

**Do not** use assets from Google Image Search, Pinterest, itch.io asset packs, or game rips without verifying the license explicitly.

Good sources for legally clean pixel art: [OpenGameArt.org](https://opengameart.org) (filter by CC0/CC-BY), [Kenney.nl](https://kenney.nl) (CC0).

Fonts: check [Google Fonts](https://fonts.google.com) (OFL — permissive) or [Font Squirrel](https://www.fontsquirrel.com) (filter "100% free").

### CC-BY-SA ShareAlike rules

ShareAlike applies to the **creative work itself and its derivatives** — not to the code that displays it. Concretely:

- Game engine code, DB schema, and rendering modules are not derivatives of a sprite. They are not required to be CC-BY-SA.
- Any **modified sprite** derived from a CC-BY-SA original must also be released under CC-BY-SA.
- When sprites are distributed (served to players), they must carry attribution and remain under CC-BY-SA — DRM that prevents access to the sprite files is prohibited.

### LPC (Liberated Pixel Cup) ruling — **CC-BY-SA only; GPL 2.0 option prohibited**

LPC assets are dual-licensed: CC-BY-SA 3.0 **or** GPL 2.0. The two licenses are independent options — contributors chose which to apply per asset.

**Decision (issue #16):** LPC assets are permissible **only when the specific asset is available under CC-BY-SA 3.0** and is committed under that license. The GPL 2.0 option is prohibited for this project regardless of the asset.

**Rationale:** GPL 2.0 was designed for software. When used as an asset license, a conservative reading requires distributing the entire application under GPL 2.0. The risk is not speculative — it has been litigated. CC-BY-SA 3.0 carries no such risk to the codebase (see ShareAlike rules above).

**Compliance checklist for any LPC asset committed:**
- [ ] The specific asset's OpenGameArt page (or source) explicitly lists CC-BY-SA 3.0
- [ ] Attribution credited in `docs/license-inventory.md` with artist name and source URL
- [ ] No DRM applied to the sprite files in `priv/static/`

See `docs/license-inventory.md` for the full record of assets in use.

---

## 3. Data Sources

**Status: Verify before each integration.**

| Source | License / Terms | Notes |
|---|---|---|
| Open5e API | CC-BY-4.0 (mirrors SRD data) — **Verified ✓** | `mix gibbering.ingest` fetches monsters from `https://api.open5e.com`. Data is SRD 5.1 content re-served under CC-BY-4.0. Open5e is an open-source project (https://github.com/open5e/open5e-api). Attribution: "Data sourced from Open5e (open5e.com), licensed CC-BY-4.0." |
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

## 7. Project License

**Decision: AGPL-3.0** (pending confirmation — not yet applied to repo).

AGPL-3.0 was chosen over MIT because the network-use clause matters for a hosted multiplayer game: anyone running a modified version as a service must publish their source. MIT would allow a competing hosted fork with no obligation to give back.

**Can/should the license be changed later?**

- **You can relicense** as long as you are the sole copyright holder. Once contributors submit code under AGPL-3.0, you need written consent from every contributor to move to a more permissive license (e.g. MIT). The earlier you decide, the easier relicensing becomes.
- **Tightening** (e.g. moving from MIT → AGPL) is fine for new code but cannot retroactively cover prior contributions under the old license.
- **Practical advice:** If there is any chance you want to commercialise with a dual-license model (open-source AGPL + paid commercial), decide that *before* accepting external contributions. A Contributor License Agreement (CLA) at that point lets you relicense later without chasing consent.
- **Dependencies:** Confirm no dependency is GPL-2.0-only (without "or later") before publishing under AGPL-3.0 — that combination is incompatible. Apache 2.0, MIT, LGPL, MPL 2.0, and AGPL-3.0 itself are all fine.

**Action required before publishing the repo:** Add a `LICENSE` file (AGPL-3.0 full text) and a SPDX header to key source files.

---

## 8. The `LegalGuard` Module — Scope

`Gibbering.Pipeline.LegalGuard` is currently scoped to WotC Product Identity. Its scope should expand to:

1. WotC PI blacklist (current)
2. A per-source license tag — every ingested entity should carry `source_license: "CC-BY-4.0"` so downstream code can assert it
3. A flag for `requires_attribution: true` so the UI can surface credits where needed