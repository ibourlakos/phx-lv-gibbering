# Dev Workflow

The sequence we follow for every change — from first idea to merged commit.

---

## Overview

The full workflow is a composable chain. **Enter at the earliest stage where you can write a crisp next step.**

```
[A] Brainstorm → Settle → Triage ─┐
[B]                      Issue ───┼──► Branch → Red → Green → Refactor → Verify → Commit
[C]                     Branch ───┘
```

| Entry point | When to use |
|---|---|
| **[A] Brainstorm** | Design space is fuzzy — you cannot write acceptance criteria yet |
| **[B] Issue** | Problem is understood — you can scope it and write acceptance criteria |
| **[C] Branch** | Issue is already open and clearly scoped — just start coding |

Every path converges at **Branch** and follows the same code phases from there. The gates (Legal, Architecture, Discovery) are non-negotiable at any entry point.

---

## Brainstorm phase

> Detail and counter rules: [docs/brainstorming/README.md](../docs/brainstorming/README.md)

Use a brainstorm file when the problem is too wide or ambiguous to scope into an issue. Brainstorming maps trade-offs, domain knowledge, and design space before committing to a direction.

### Lifecycle

| Step | Action | Commit |
|---|---|---|
| **Open** | Create `docs/brainstorming/<NN>-<slug>.md`, increment counter, add row to CLAUDE.md | `chore: open brainstorm #N` |
| **Explore** | Discussion sessions — populate the doc; accumulate open questions | *(no commit required per session)* |
| **Settle** | Work through each open question; every question resolves to a **decision** (documented) or an **explicit deferral** (noted with reason) | *(no commit required)* |
| **Triage** | Each settled decision becomes one or more issues in `.issues/`; update the doc to reference them | *(bundle with next step)* |
| **Commit** | Brainstorm doc (updated) + all new issue files in one atomic commit | `chore: brainstorm #N → issues #X–Y` |
| **Close** | Once the brainstorm's issues are all closed or deferred, delete the file, remove from CLAUDE.md | `chore: close brainstorm #N` |

**Gate before Commit:** No open question may remain without either a decision or an explicit deferral with reason. A partially triage brainstorm is not committed.

**Gate before Close:** All issues extracted from this brainstorm are closed or deferred in `.issues/`.

---

## Issue phase

**What:** Open or update a `.issues/` entry with acceptance criteria that can become test cases.

**Rules:**
- Every non-trivial change gets an issue. Trivial = one file, no behaviour change.
- Acceptance criteria drive the tests. Write them as checkboxes before touching code.
- Use tag `discovery` for design unknowns/epics, `ops` for infra/tooling.
- Follow the format in [CLAUDE.md](../CLAUDE.md#issue-tracker) exactly — counter, status, priority.

**Output:** An open issue with `**Acceptance criteria**` checkboxes.

---

## Branch phase

**What:** Create a branch that matches the change type.

```bash
git checkout -b feat/<short-name>
git checkout -b fix/<short-name>
git checkout -b chore/<short-name>
git checkout -b docs/<short-name>
```

Branch naming is in [docs/git-policy.md](git-policy.md). Never commit directly to `main`.

---

## Red phase — write tests first

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

Name tests in terms of behaviour, not implementation:

```elixir
# Good — describes what the game does
test "active hero cannot move to a tile occupied by another hero"

# Weaker — describes internals
test "occupied_by_hero? returns true for same coordinates"
```

The acceptance criteria from the Issue phase should map 1-to-1 to test descriptions.

### New integration test file?

Create a new test file when the combination being tested doesn't fit any existing file:
- New entity type interacting with an existing system
- New LiveView page
- New pipeline module

Copy the `use` + `import` header from the nearest similar file.

**Output:** One or more test files with failing tests. `mix test` is red.

---

## Green phase — implement

**What:** Write the minimum production code to make the failing tests pass.

**Rules:**
- No gold-plating. If the tests don't require it, don't write it.
- No cleanup of surrounding code. That's the Refactor phase.
- If you need a new DB migration, write it before the code it supports.
- If you add a dependency, check the legal gate first.

**Output:** `mix test` is green. All existing tests still pass.

---

## Refactor phase

**What:** Improve the code without changing behaviour.

- Rename for clarity, extract a well-named helper, remove duplication.
- Tests must stay green throughout. Run `mix test` after each change.
- Keep commits clean: don't bundle refactor with feature. If a significant refactor is needed, it gets its own commit (or its own branch).

**Output:** `mix test` is still green. Code is clean.

---

## Verify phase

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

## Commit & Close phase

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
2. Move the row from Open to Closed in `.issues/README.md`.
3. Commit as `chore: close issue #N`.

**Output:** Branch is ahead of `main` with clean commits. Issue is closed.

---

## Decision gates

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

## Quick reference

| Phase | Artifact / command | Done when |
|---|---|---|
| Brainstorm → Settle | `docs/brainstorming/<NN>-<slug>.md` | All questions decided or explicitly deferred |
| Triage → Commit | `.issues/<N>-<slug>.md` files + brainstorm doc | One atomic commit; no dangling open questions |
| Issue | `.issues/<N>-<slug>.md` + `counter` | Acceptance criteria written |
| Branch | `git checkout -b <type>/<name>` | Branch exists |
| Red | `mix test` | Tests fail for the right reason |
| Green | `mix test` | All tests pass |
| Refactor | `mix test` | Still passing, code is clean |
| Verify | `mix precommit` | Exits 0 |
| Commit & Close | `git commit` + issue closed | Committed, issue status updated |
