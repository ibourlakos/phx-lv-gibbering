# #16 · LPC sprite copyleft risk understated in brainstorm

**Status:** open
**Opened:** 2026-06-04
**Priority:** medium
**Tags:** legal

`04-dst-aesthetic-sprites.md` flags LPC (Liberated Pixel Cup) sprites as "CC-BY-SA, check share-alike implications" without spelling out the consequence.

**The actual risk:** CC-BY-SA is a copyleft license. Any derivative work that incorporates SA-licensed art must itself be released under CC-BY-SA. If the game is ever kept closed-source, sold commercially without a separate license agreement, or the source is not published, using LPC sprites is prohibited — not just risky.

This must be resolved before LPC assets are evaluated in #6, so `docs/legal.md` does not inadvertently greenlight a problematic asset class.

**Acceptance criteria**
- [ ] `docs/legal.md` explicitly states the CC-BY-SA share-alike consequence for LPC sprites
- [ ] A decision is recorded: either commit to open-sourcing under a compatible license, or rule out LPC entirely and remove it from the candidate list
- [ ] `06-raster-sprite-pipeline.md` evaluation criteria updated to reflect this verdict
