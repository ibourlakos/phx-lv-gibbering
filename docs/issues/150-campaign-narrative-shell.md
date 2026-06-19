# #150 · Campaign narrative shell
**Status:** deferred
**Opened:** 2026-06-19
**Deferred because:** Aesthetic, not functional. The minimum campaign loop (WP-P) runs without it. Revisit after WP-P ships.
**Priority:** low
**Tags:** gameplay, ui

DM-editable flavour text attached to a campaign: an intro blurb shown before the
first session, an encounter title displayed in the outcome screen (#143), and a
custom win-condition label (e.g. "Defeat the Necromancer"). Currently the outcome
screen uses static strings ("Victory" / "Defeat").

**Acceptance criteria**
- [ ] `campaigns` table gains optional `intro_text`, `encounter_title`, `victory_label`, `defeat_label` fields
- [ ] DM can edit these fields from the campaign overview / lobby
- [ ] Outcome screen (#143) renders `victory_label` / `defeat_label` when set, falling back to static strings
- [ ] Intro text is shown as a dismissible modal on first session join
