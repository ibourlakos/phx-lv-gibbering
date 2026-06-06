# #57 · DM character adjustment UI
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-06
**Priority:** medium
**Tags:** gameplay, rendering

A campaign preparation screen where the DM can review and adjust each `CampaignCharacter` before the campaign starts. The DM works on the override fields — the original character template is never shown as editable.

**DM-adjustable fields**
- Level (override)
- Ability scores (override)
- Background (override)
- Starting items (add, remove, replace)
- Bonus proficiencies (append)
- Life events (add DM-authored events)
- Controller assignment (reassign to another campaign member)
- Active flag (which characters are in play)

**Read-only fields (shown for reference)**
- Race, class, appearance — owner's territory

The screen also shows the current `campaign_relations` for each character and allows the DM to add/edit relations between characters in this campaign.

**Acceptance criteria**
- [ ] DM-only UI surface (gated by role) within the campaign context
- [ ] All override fields editable; changes persist to `CampaignCharacter`
- [ ] Original `Character` template shown as read-only reference alongside overrides
- [ ] Controller assignment dropdown lists current campaign members
- [ ] Active flag toggle per character
- [ ] `mix precommit` passes
