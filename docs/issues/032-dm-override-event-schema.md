# #32 · DM override event schema and god-mode mechanics

**Status:** open
**Opened:** 2026-06-05
**Priority:** medium
**Tags:** discovery, architecture, gameplay

The DM needs the ability to override essentially anything in a running scene: undo a condition, adjust a stat, restore HP, skip a death save, force a roll result, or rewrite narrative facts. The design constraint is that the event log is **append-only** — a DM "undo" is a compensating event, not a deletion.

## What needs to be decided

**Event type taxonomy for DM actions:** what discrete override types does the DM UI need to expose? Candidates include: `:remove_condition`, `:set_stat`, `:set_hp`, `:grant_resource`, `:consume_resource`, `:force_save_result`, `:skip_death_saves`, `:add_active_effect`, `:remove_active_effect`, `:reorder_initiative`.

**Payload schema:** each override type needs a defined payload. Do all DM override events share a common envelope (`%Event{type: :dm_override, actor: :dm, payload: {type, ...}}`) or are they first-class event types at the same level as `:attack_rolled`, `:damage_applied`?

**Authorisation:** should the DM override event carry an audit trail (dm_user_id, reason string)? The `reason` field is useful for post-session review and resolves ambiguity when the event log is replayed.

**Interaction with predicates:** DM overrides must be expressible as events that the predicate evaluator respects. For example, a DM manually granting Advantage to an entity for narrative reasons — this should be modelled as an `ActiveEffect` applied by a `:dm` source, not a special flag. This keeps the rules pipeline uniform.

**God-mode scope:** is there anything the DM cannot override? (Probably not — but the UI might want to warn on certain high-impact actions.)

**Relation to player-visible state:** when a DM overrides something, should players see the event in the combat log? As a narrative note? Or is it silent?

## Relation to other issues

- The append-only event log is a prerequisite (see #12 persistence strategy)
- DM override events must compose with the `RuleModifier` predicate system (#31) rather than bypassing it
- Scene-level `ActiveEffect` registry (#30) is the mechanism for most DM overrides

**Acceptance criteria**
- [ ] DM override event taxonomy documented
- [ ] Payload schema for each override type defined
- [ ] Authorisation / audit trail approach decided
- [ ] Interaction with predicate evaluation documented (DM overrides go through the same pipeline, not around it)
