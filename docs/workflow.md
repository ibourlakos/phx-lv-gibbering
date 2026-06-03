# Dev Workflow

The sequence we follow for every change — from first idea to merged commit.

---

## Overview

```
Explore → Issue → Branch → Red → Green → Refactor → Verify → Commit
```

Not every change needs every phase. A typo fix skips Explore and Issue. A new mechanic
runs all eight. Use judgement; the gates are the non-negotiables.

---

## Phase 0 — Explore

**What:** Talk through the idea. Identify unknowns, risks, and legal exposure before writing a line.

**Prompts:**
- Does this touch any licensed asset, data source, or dependency? → Legal gate (see below).
- Does this cross more than two modules or change a shared interface? → Architecture discussion first.
- Is this well-understood enough to write acceptance criteria? → If not, open a discovery issue and stop.

**Output:** Either "ready to implement" or a discovery issue in `.issues/discovery.md`.

---

## Phase 1 — Issue

**What:** Open or update a `.issues/` entry with acceptance criteria that can become test cases.

**Rules:**
- Every non-trivial change gets an issue. Trivial = one file, no behaviour change.
- Acceptance criteria drive the tests. Write them as checkboxes before touching code.
- Pick the right aspect file: `ops.md` for infra/tooling, `discovery.md` for design unknowns/epics.
- Follow the format in [CLAUDE.md](../CLAUDE.md#issue-tracker) exactly — counter, status, priority.

**Output:** An open issue with `**Acceptance criteria**` checkboxes.

---

## Phase 2 — Branch

**What:** Create a branch that matches the change type.

```bash
git checkout -b feat/<short-name>
git checkout -b fix/<short-name>
git checkout -b chore/<short-name>
git checkout -b docs/<short-name>
```

Branch naming is in [docs/git-policy.md](git-policy.md). Never commit directly to `main`.

---

## Phase 3 — Red (Write tests first)

**What:** Write failing tests *before* any production code. This phase ends when `mix test` shows red.

### Which layer to start at

Always start at the lowest applicable layer:

| Change touches… | Start at |
|---|---|
| A pure function in `Rules`, `State`, `Parser`, `LegalGuard` | Layer 1 — `test/engine/` or `test/pipeline/` |
| `GameServer` API, PubSub, DB persistence | Layer 2 — `test/engine/game_server_test.exs` |
| LiveView events, SVG rendering, UI wiring | Layer 3 — `test/gibbering_web/live/` |

It's fine to add tests at multiple layers for the same change. Start low, add higher only when the lower layer can't cover it.

### BDD framing

Name tests in terms of behavior, not implementation:

```elixir
# Good — describes what the game does
test "active hero cannot move to a tile occupied by another hero"

# Weaker — describes internals
test "occupied_by_hero? returns true for same coordinates"
```

The acceptance criteria from Phase 1 should map 1-to-1 to test descriptions.

### New integration test file?

Create a new test file when the combination being tested doesn't fit any existing file:
- New entity type interacting with an existing system
- New LiveView page
- New pipeline module

Copy the `use` + `import` header from the nearest similar file.

**Output:** One or more test files with failing tests. `mix test` is red.

---

## Phase 4 — Green (Implement)

**What:** Write the minimum production code to make the failing tests pass.

**Rules:**
- No gold-plating. If the tests don't require it, don't write it.
- No cleanup of surrounding code. That's Phase 5.
- If you need a new DB migration, write it before the code it supports.
- If you add a dependency, check the legal gate first.

**Output:** `mix test` is green. All existing tests still pass.

---

## Phase 5 — Refactor

**What:** Improve the code without changing behavior.

- Rename for clarity, extract a well-named helper, remove duplication.
- Tests must stay green throughout. Run `mix test` after each change.
- Keep commits clean: don't bundle refactor with feature. If a significant refactor is needed, it gets its own commit (or its own branch).

**Output:** `mix test` is still green. Code is clean.

---

## Phase 6 — Verify

**What:** Run the pre-commit gate. This must pass before any commit.

```bash
docker compose exec app mix precommit
```

The `precommit` alias runs, in order:
1. `compile --warnings-as-errors` — no compiler warnings allowed
2. `deps.unlock --unused` — no unused dependency locks
3. `format` — code is formatted
4. `test` — all tests pass

Fix every failure before moving on. A red precommit is a hard stop.

**Output:** `mix precommit` exits 0.

---

## Phase 7 — Commit & Close

**What:** Commit the work and close the issue.

```bash
# Stage specific files (never `git add .`)
git add lib/... test/...

# Commit with conventional format
git commit -m "feat(engine): add ranged attack action to Rules

Closes #4."
```

Commit rules are in [docs/git-policy.md](git-policy.md).

After the commit:
1. Update the issue: change `**Status:** open` → `**Status:** closed`, add `**Closed:** YYYY-MM-DD`.
2. Remove the row from the open issues table in `.issues/README.md`.
3. Commit as `chore: close issue #N`.

**Output:** Branch is ahead of `main` with clean commits. Issue is closed.

---

## Decision Gates

These are non-negotiable checkpoints that can pause any phase.

### Legal gate

**Trigger:** Adding any asset (image, font, audio), data file, or new `mix` dependency.

**Action:** Verify license against [docs/legal.md](legal.md) before proceeding. Unresolved legal is a blocker — do not commit and flag the question explicitly.

### Architecture gate

**Trigger:** A change that modifies a shared interface (e.g., `Gibbering.Ruleset` behaviour callbacks), spans more than two modules, or affects the SVG rendering pipeline end-to-end.

**Action:** Discuss and update [docs/architecture.md](architecture.md) *before* writing any code.

### Discovery gate

**Trigger:** A question that can't be answered in the current conversation — requires prototyping, research, or external input.

**Action:** Open a discovery issue. Do not proceed with implementation until the question is answered.

---

## Quick Reference

| Phase | Command / artifact | Done when |
|---|---|---|
| Explore | Conversation | Decision made |
| Issue | `.issues/*.md` + `counter` | Acceptance criteria written |
| Branch | `git checkout -b <type>/<name>` | Branch exists |
| Red | `mix test` | Tests fail for the right reason |
| Green | `mix test` | All tests pass |
| Refactor | `mix test` | Still passing, code is clean |
| Verify | `mix precommit` | Exits 0 |
| Commit | `git commit` + close issue | Committed, issue closed |
