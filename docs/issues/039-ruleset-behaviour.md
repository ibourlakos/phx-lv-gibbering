# #39 · `Gibbering.Ruleset` behaviour + `DnD5e` implementation shell

**Status:** open
**Opened:** 2026-06-05
**Priority:** high
**Tags:** architecture

Closes #14. The engine currently has no ruleset abstraction — all rules are
hardcoded in `Gibbering.Engine.Rules`. Adding a `Gibbering.Ruleset` behaviour
makes the engine ruleset-swappable and gives all `DnD5e.*` modules a single
governed entry point.

**Acceptance criteria**
- [ ] `Gibbering.Ruleset` behaviour defined with callbacks: `collect_modifiers/3`, `initial_resources/1`, `initial_action_economy/1`, `advance_turn/1`
- [ ] `Gibbering.Rulesets.DnD5e` module created implementing the behaviour (shell — callbacks may be minimal stubs initially)
- [ ] `Engine.State` gains a `ruleset` field (default `Gibbering.Rulesets.DnD5e`); `SceneServer` delegates to it for all rule calls
- [ ] All `DnD5e.*` submodules (`Stats`, `Spell`, `RuleModifier`, `Condition`) live under `Gibbering.Rulesets.DnD5e.*`
- [ ] Issue #14 closed
- [ ] `mix precommit` passes
