# #149 · NPC / DM roll visibility
**Status:** open
**Opened:** 2026-06-19
**Priority:** low
**Tags:** gameplay, ui, architecture

DM-controlled entity rolls (NPC attacks, NPC saving throws) are currently silent —
they resolve server-side and players only see the outcome. This issue tracks a
"DM roll reveal" feature: the DM can choose (per roll or globally) to show the
NPC's roll result to the table, for dramatic effect.

This is a pure presentation layer concern. The roll results already exist in the
engine; the feature is about controlling their visibility in the event feed and
possibly triggering the same die animation used by the player roll prompt (#146).

**Depends on:** #136 (event visibility taxonomy — which rolls are visible to which roles)

**Acceptance criteria**
- [ ] NPC/DM roll events carry a `visible_to` field consistent with the taxonomy from #136
- [ ] DM has a per-session toggle: "reveal NPC rolls to players" (default: off)
- [ ] When reveal is on, player event feeds show the NPC roll result with die notation
- [ ] Die animation (from #146 infrastructure) fires on player screens when reveal is on
- [ ] DM always sees all rolls regardless of the reveal toggle
