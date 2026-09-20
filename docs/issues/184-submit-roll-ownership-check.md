# #184 · `submit_roll` does not check who the pending roll belongs to

**Status:** open
**Opened:** 2026-09-20
**Priority:** medium
**Tags:** bug, security, architecture

`SceneServer` `{:submit_roll, entity_id, value}` uses the caller-supplied
`entity_id` directly as the attacker/caster for the pending roll, with no
check that the submitting client actually owns/controls that entity.
`State.pending_roll/1` stores only `{:attack, target_id}` /
`{:cast_spell, spell_key, target_id}` — the original roller's identity
isn't retained anywhere to check against.

Practically: any connected campaign member can submit
`{:submit_roll, any_entity_id, value}` while `awaiting_roll?` is true and
it will be accepted as that entity's roll.

Low-stakes at current scale (co-op friends game, everyone already trusts
each other), but the fix is a small, well-contained equality check and
closing it now avoids the design debt compounding as more roll types are
added (#148 AoE saving throw prompts touches the same pending-roll state).

**Acceptance criteria**
- [ ] Pending roll state retains the entity/player identity it was opened
      for
- [ ] `submit_roll` rejects a mismatched submitter with `{:error, ...}`
      (no crash, no silent no-op)
- [ ] Regression test: entity A's roll pending, submit as entity B, assert
      rejected and A's roll remains pending
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified against
code before filing.
