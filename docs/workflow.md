# Dev Workflow

The sequence we follow for every change — from first idea to merged commit.

---

## Overview

Four paths depending on how well the problem is understood and how large the fix is.

```
[A] Discovery:  Brainstorm → Settle → Triage ──────────────────────────────► Issues
[B] Feature:    Issue ──────────────────────► Branch → Red → Green → Refactor → Verify → Commit
[C] Bugfix:     Issue (bug) ────────────────► Branch → Red (reproduce) → Green → Verify → Commit
[D] Hotfix:                                                              Verify → Commit
[E] Work Package: Triage batch ──────────────► work-packages.md → pick next issue → repeat B/C
```

| Path | When to use |
|---|---|
| **[A] Discovery** | Design space is fuzzy — you cannot write acceptance criteria yet |
| **[B] Feature** | New behaviour; issue exists with acceptance criteria |
| **[C] Bugfix** | Reproducible defect; needs a regression test to prove and prevent recurrence |
| **[D] Hotfix** | Caught at smoke test; ≤ 1 file; no behaviour change; no new test needed |
| **[E] Work Package** | Many issues extracted from brainstorms; need ordering + dependency tracking across phases |

**The gate between Bugfix and Hotfix is the regression test.** If you need a test to prove the fix holds — Bugfix. If the only proof is "the app boots and the action works" — Hotfix.

The decision gates (Legal, Architecture, Discovery) apply to paths A, B, and C. A Hotfix is by definition too small to trigger them.

---

## [A] Discovery path

> Detail and counter rules: [docs/brainstorming/README.md](../docs/brainstorming/README.md)

Use a brainstorm file when the problem is too wide or ambiguous to scope into an issue.

| Step | Action | Commit |
|---|---|---|
| **Open** | Create `docs/brainstorming/<NN>-<slug>.md`, increment counter, add row to CLAUDE.md | `chore: open brainstorm #N` |
| **Explore** | Populate the doc; accumulate open questions | *(no commit required per session)* |
| **Settle** | Every question resolves to a **decision** or an **explicit deferral** (with reason) | *(no commit required)* |
| **Triage** | Each decision becomes one or more issues; update the doc to reference them | *(bundle with next step)* |
| **Commit** | Brainstorm doc + all new issue files | `chore: brainstorm #N → issues #X–Y` |
| **Close** | Once all extracted issues are closed or deferred, delete the file, remove from CLAUDE.md | `chore: close brainstorm #N` |

**Gate before Commit:** No open question without a decision or explicit deferral. No [docs](./docs) need updating.

**Gate before Close:** All extracted issues are closed or deferred in `docs/issues/`.

---

## [B] Feature path

### Issue phase

Open a `docs/issues/` entry. Write acceptance criteria as checkboxes — these drive the tests. Follow the format in [CLAUDE.md](../CLAUDE.md#issue-tracker) exactly.

### Branch phase

```bash
git checkout -b feat/<short-name>
```

Never commit directly to `main`. Branch naming in [docs/git-policy.md](git-policy.md).

### Red phase — write tests first

Write failing tests *before* any production code. Start at the lowest applicable layer:

| Change touches… | Start at |
|---|---|
| Pure function in `Rules`, `State`, `Parser`, `LegalGuard` | Layer 1 — `test/engine/` or `test/pipeline/` |
| `GameServer` API, PubSub, DB persistence | Layer 2 — `test/engine/game_server_test.exs` |
| LiveView events, SVG rendering, UI wiring | Layer 3 — `test/gibbering_web/live/` |

Name tests by behaviour, not implementation. Acceptance criteria should map 1-to-1 to test descriptions.

**Output:** `mix test` is red.

### Green phase — implement

Write the minimum code to make the failing tests pass. No gold-plating, no surrounding cleanup. New DB migrations go before the code that needs them. New dependencies go through the legal gate first.

**Output:** `mix test` is green. All existing tests still pass.

### Refactor phase

Improve the code without changing behaviour. Tests stay green throughout. Significant refactors get their own commit.

### Verify & Commit phase

```bash
docker compose exec app mix precommit
```

Runs `compile --warnings-as-errors`, `deps.unlock --unused`, `format`, `test`. Fix every failure before committing.

```bash
git add lib/... test/...
git commit -m "feat(scope): description

Closes #N."
```

Close the issue: set `**Status:** closed`, add `**Closed:** YYYY-MM-DD`, move its row in `docs/issues/README.md`, commit as `chore: close issue #N`.

---

## [C] Bugfix path

Identical to Feature with two differences:

1. **Issue:** Tag the issue `bug`. Acceptance criteria must include reproduction steps.
2. **Red phase:** Write a test that *reproduces the bug* before touching fix code. A test that passes before the fix is not a regression test — keep digging.

**Branch:** `fix/<short-name>`. **Commit prefix:** `fix(scope): …  Fixes #N.`

---

## [D] Hotfix path

**Trigger:** All of the following must be true:
- ≤ 1 file changed
- No behaviour change to game logic
- No new test needed — proof is "the app works"

If any criterion fails, use Bugfix instead.

1. Fix in place on the current branch (or `main` if between features).
2. `docker compose exec app mix precommit` — hard stop if red.
3. `git commit -m "fix(scope): description"`
4. *Optional:* If the root cause could recur, open a `bug` issue after the commit to track a durable prevention measure.

---

## Context usage gate

**When:** Before starting any new flow stage (picking a new issue, opening a new brainstorm, or beginning a new work package cycle).

Check Claude Code's session token usage. If usage is approaching the session limit:
- **Do not start a new stage unilaterally.**
- Report the current usage state to the user.
- Wait for explicit approval before proceeding.

This prevents truncated implementations that span a context boundary and leave the codebase in a half-finished state. A new session has full context (via MEMORY.md + CLAUDE.md); partial work mid-issue does not.

---

## Decision gates

Apply to paths A, B, C only.

### Legal gate

**Trigger:** Adding any asset, data file, or `mix` dependency.  
**Action:** Verify license against [docs/legal.md](legal.md). Unresolved legal is a blocker.

### Architecture gate

**Trigger:** Modifies a shared interface, spans more than two modules, or affects the SVG pipeline end-to-end.  
**Action:** Discuss and update [docs/architecture.md](architecture.md) before writing any code.

### Discovery gate

**Trigger:** A question that requires prototyping, research, or external input to answer.  
**Action:** Open a discovery issue. Do not proceed until the question is answered.

### Up-to-date docs gate

**Trigger:** Any incoming updates that have affected the architecture, the data model, or testing policy.
**Action:** Read `docs/{architecture,data-model,testing}.md` and update them.

---

## [E] Work Package subflow

A work package is a temporary planning document (`docs/issues/work-packages.md`) that groups issues by concern and establishes sequencing across phases. It sits *above* the per-issue workflow — it tells you which issue to pick up next and what it depends on.

### When to use a work package

Open or update `work-packages.md` after a brainstorm triage batch produces many issues at once, or when you need to reason about ordering across several unrelated tracks. It is not an issue file and does not go in the issue tracker.

### Work package lifecycle

| Step | Action |
|---|---|
| **Create / update** | After triage (path A Commit step), rewrite `work-packages.md` with all open issues grouped by phase, with sequencing notes and a critical path. |
| **Pick next issue** | Read `work-packages.md`. Follow the critical path. Before starting a concrete task, check whether any discovery issue blocks it — if yes, resolve the discovery first (path A or B). |
| **Discovery issue handling** | Do not resolve all discovery issues upfront. Resolve one *just before* you need to implement the thing it scopes. This avoids stale decisions. |
| **Delete** | When all issues in all packages are closed or deferred. |

### Interaction with discovery issues

A discovery issue has tag `discovery` and no implementation work — its acceptance criteria are design decisions, not code. The trigger to resolve it is *"I am about to start the implementation it gates."* If no concrete issue is blocked by it right now, leave it in the backlog.

### Critical path rule

The work package defines a critical path. Always work the critical path first unless a parallel track is explicitly marked as unblocked and higher priority. The critical path ends when WP-D is complete (full campaign lifecycle + live DM session toolset operational).

---

## Quick reference

| Path | Entry | Key gate | Commit prefix |
|---|---|---|---|
| Discovery | Brainstorm file | All questions settled or deferred | `chore: brainstorm #N → issues #X–Y` |
| Feature | Issue with acceptance criteria | Legal / Architecture / Discovery | `feat(scope): …` |
| Bugfix | Bug issue with reproduction steps | Failing regression test before fix | `fix(scope): …` |
| Hotfix | Smoke test observation | `mix precommit` exits 0 | `fix(scope): …` |

| Phase (Feature/Bugfix) | Done when |
|---|---|
| Issue | Acceptance criteria written |
| Branch | Branch exists |
| Red | `mix test` fails for the right reason |
| Green | `mix test` passes, existing tests still pass |
| Refactor | Still passing, code is clean |
| Verify | `mix precommit` exits 0 |
| Commit & Close | Committed, issue closed |
