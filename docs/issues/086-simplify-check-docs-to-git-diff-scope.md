# #86 · Simplify `mix check.docs` to git-diff scope

**Status:** deferred
**Opened:** 2026-06-06
**Deferred because:** All existing gaps were fixed when the gate was introduced; catching violations at commit time is sufficient for now.
**Priority:** low
**Tags:** ops, architecture

`mix check.docs` currently scans all compiled BEAM modules in the app on every
precommit run. A simpler design would scope the check to staged `.ex` files via
`git diff --cached --name-only`, removing the compile dependency and namespace
filter entirely.

**Gap introduced by the git-diff approach:** pre-existing violations in files
that aren't part of the current commit stay invisible. This is acceptable today
because all known gaps were fixed at gate introduction (2026-06-06), but it
means debt can accumulate silently in untouched files.

**Acceptance criteria**
- [ ] `mix check.docs` reads staged `.ex` files from `git diff --cached --name-only`
- [ ] For each file: fails if `defmodule` is present without `@moduledoc` on a following line; fails if a public `def` is present without a preceding `@doc` or `@doc false`
- [ ] `@moduledoc false` and `@doc false` suppress the check (not reported as violations)
- [ ] docs/ file existence phase unchanged
- [ ] No `mix compile` call required; runs purely on source text
- [ ] A one-time full-codebase scan task (or CI step) exists to catch violations in untouched files, closing the pre-existing-gap issue
- [ ] `mix precommit` passes
