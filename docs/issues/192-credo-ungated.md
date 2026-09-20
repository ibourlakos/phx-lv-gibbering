# #192 · Credo configured but not gated — findings rot silently

**Status:** open
**Opened:** 2026-09-20
**Priority:** low
**Tags:** ops

Credo is a declared dependency (`{:credo, "~> 1.7", only: [:dev, :test],
runtime: false}` in both `gibbering_tales_admin` and `gibbering_tales_web`
`mix.exs`) with a real `.credo.exs` config at repo root, but the root
`precommit` alias (`compile --warnings-as-errors`, `deps.unlock --unused`,
`format`, `check.docs`, `test`) does not run it. Currently ~26 findings
(complexity/nesting in `scene_server.ex`, `game_live.ex`, `state.ex`,
`characters_live.ex`), nothing security-shaped, but ungated means it can
only grow.

**Acceptance criteria**
- [ ] Decide: add `credo` to the `precommit` alias with a baseline/ignore
      file covering the current ~26 findings (so only new issues fail the
      gate), or remove `.credo.exs`/the dependency if it's not going to be
      enforced
- [ ] If gating: `mix precommit` passes with the baseline in place
- [ ] `mix precommit` passes

**Source:** identified via external code review (GLM/ZAI), verified
against code before filing.
