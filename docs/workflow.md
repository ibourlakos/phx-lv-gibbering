# Dev Workflow

The sequence we follow for every change — from first idea to merged commit.

---

## Overview

Seven paths depending on how well the problem is understood and how large the change is.

```
[A] Discovery:  Brainstorm → Settle → Triage ──────────────────────────────► Issues
[B] Feature:    Issue ──────────────────────► Branch → Red → Green → Refactor → Verify → Commit
[C] Bugfix:     Issue (bug) ────────────────► Branch → Red (reproduce) → Green → Verify → Commit
[D] Hotfix:                                                              Verify → Commit
[E] Work Package: Triage batch ──────────────► work-packages.md → pick next issue → repeat B/C
[F] Escalation: discovery Issue → too broad → open Brainstorm → defer Issue → enter [A]
[G] Docs:       (fix) Verify → Commit   |   (refactor) Branch → Edit → Verify → Commit
```

| Path | When to use |
|---|---|
| **[A] Discovery** | Design space is fuzzy — you cannot write acceptance criteria yet |
| **[B] Feature** | New behaviour; issue exists with acceptance criteria |
| **[C] Bugfix** | Reproducible defect; needs a regression test to prove and prevent recurrence |
| **[D] Hotfix** | Caught at smoke test; ≤ 1 file; no behaviour change; no new test needed |
| **[E] Work Package** | Many issues extracted from brainstorms; need ordering + dependency tracking across phases |
| **[F] Escalation** | A `discovery` issue turns out too broad to produce ACs directly; promote it to a brainstorm |
| **[G] Docs** | Documentation-only change: prose corrections, reorganisation, link updates — no code touched |

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

**Gate before Commit:** No open question without a decision or explicit deferral. No docs need updating.

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

Check all three signals before proceeding:

| Signal | Where to check | Stop if… |
|---|---|---|
| **Session context size** | `/cost` or the token counter in the Claude Code UI | Context window is ≥ 60% full |
| **Per-message token cost** | `/cost` after the last tool-heavy turn | A single turn exceeded ~50k tokens |
| **Account usage** | Anthropic Console → Usage | Monthly spend is near plan limit or a daily spike is visible |

If any signal is elevated:
- **Do not start a new stage unilaterally.**
- Report the current state for each signal.
- Wait for explicit approval before proceeding.

This prevents truncated implementations that span a context boundary and leave the codebase in a half-finished state. A new session starts cold with full context (via MEMORY.md + CLAUDE.md); partial work mid-issue does not.

---

## Decision gates

Apply to paths A, B, C only.

### Legal gate

**Trigger:** Adding any asset, data file, or `mix` dependency.  
**Action:** Verify license against [docs/legal.md](legal.md). Unresolved legal is a blocker.

### Architecture gate

**Trigger:** Modifies a shared interface, spans more than two modules, or affects the SVG pipeline end-to-end.  
**Action:** Discuss and update [docs/architecture.md](architecture.md) before writing any code.

**Event schema sub-gate:** Adding or changing any `Gibbering.Events.*` struct is a Published
Language change — a system-wide API contract, not a local code change. Before implementing:
1. Run the mini-cycle: Event Storming (brainstorm) → envelope spec → versioning policy review
2. Confirm the change is additive-only or justify a new event type
3. Update the Published Language Registry in
   [docs/architecture/bounded-contexts.md](architecture/bounded-contexts.md) and the
   Event Cascade Batch Emission table in
   [docs/architecture/event-cascade.md](architecture/event-cascade.md)

This gate precedes any bus extension, event store implementation, or persistent event log work.
See the [Published Language Registry](architecture/bounded-contexts.md#published-language-registry-cross-cutting--shared-contract)
for the full convention.

### Discovery gate

**Trigger:** A question that requires prototyping, research, or external input to answer.  
**Action:** Open a discovery issue. Do not proceed until the question is answered.

**Escalation (path [F]):** If working a discovery issue reveals it is too broad to produce crisp ACs directly, promote it to a brainstorm (path [A]): open a brainstorm file, defer the original discovery issue with `Deferred because: promoted to brainstorm #N`, and let the brainstorm's extracted issues replace it. The discovery issue may be closed once the brainstorm is settled and its replacement issues are open.

### Up-to-date docs gate

**Trigger:** Any incoming updates that have affected the architecture, the data model, or testing policy.
**Action:** Read `docs/architecture.md`, `docs/architecture/data-model.md`, and `docs/testing.md` and update them.

---

## [E] Work Package subflow

A work package is a temporary planning document (`docs/issues/work-packages.md`) that groups issues by concern and establishes sequencing across phases. It sits *above* the per-issue workflow — it tells you which issue to pick up next and what it depends on.

---

### Creation

**Trigger:** A brainstorm triage batch produces ≥ 3 new issues at once, OR you need to reason about ordering across several unrelated tracks.

**Before grouping:** audit which discovery or gating issues have closed since the last update. Each closed discovery may have derived new implementation issues — those are candidates for new or updated packages.

**Grouping:** cluster open issues into named packages by theme (e.g. "Rendering & Frontend", "Inventory & Loot"). A package is a *concern*, not a sprint.

**Ordering within each package — data layer before presentation:**

1. DB migrations / schema changes
2. Business logic / event handlers
3. LiveView / SVG presentation layer

**Cross-package gates:** if issue X in one package gates issue Y in another, annotate both with the dependency and note the gate in the sequencing diagram at the bottom.

**Cross-cutting threads:** issues with no clear phase home (standalone bugs, deferred discoveries, independent ops items) go in a separate cross-cutting table, not in a numbered package.

**Sequencing diagram:** a short ASCII tree at the bottom showing which packages unlock which and what the current active front is.

---

### Maintenance

**Trigger:** a gating discovery closes, a batch of issues closes, or new issues are derived from a settled discovery.

1. **Mark completed packages** with ✓ and a one-line close note ("all N issues closed as of YYYY-MM-DD"). Do not delete their sections — they serve as a history of what is done.
2. **Disassemble stale assignments.** If a previously gated item carried a "gated by X — do not start" annotation and X is now closed, remove the item from its old stub and assign it to a new package or promote it as the lead item of a new package.
3. **Add new packages for derived issues.** When a closed discovery has produced implementation issues, open a new package entry, reference the discovery it came from, and apply the data-layer-first sequencing rule.
4. **Update the sequencing diagram** to reflect the new active front and any newly unlocked tracks.
5. **Prune cross-cutting threads.** Remove entries whose issues are closed. Add newly deferred or unassigned issues.

---

### Completion

**Trigger:** all issues in a package are closed or explicitly deferred.

1. Mark the package ✓ complete with a close note.
2. Check whether any issues in other packages were gated by this one — remove their gate annotations and promote them to active if applicable.
3. When all packages across the entire file are complete or deferred: delete `work-packages.md`.

---

### Key invariants

| Rule | Why |
|---|---|
| Data layer before presentation within a package | Avoids half-wired features mid-branch |
| Blocking dependencies before dependees across packages | Prevents starting work that immediately stalls |
| Do not resolve discovery issues upfront | Decisions go stale; resolve a gate just before you need it |
| Gated items stay in their old stub until the gate closes | Keeps the active front unambiguous |
| Disassemble and reassign on every maintenance pass | Prevents zombie "gated by X" annotations after X is already closed |

---

## [F] Escalation path

**Trigger:** A `discovery` issue turns out too broad to produce crisp acceptance criteria directly.

1. Open a brainstorm file (path [A]).
2. Defer the original discovery issue: `Deferred because: promoted to brainstorm #N`.
3. Work the brainstorm to settlement; extract replacement issues.
4. Close the original discovery issue once the brainstorm is settled and replacement issues are open.

Full detail is in the [Discovery gate](#discovery-gate) section below.

---

## [G] Docs path

Documentation-only changes: no code is touched, no tests needed, no `mix precommit` required.

Two sub-tracks based on structural impact:

### Docs fix (correction, clarification, minor addition)

**Trigger:** All of the following must be true:
- No file is moved or renamed
- No cross-document links are added or changed
- ≤ a few lines changed

1. Edit in place on the current branch.
2. Read the changed file back and confirm the edit looks right.
3. `git commit -m "docs(scope): description"`

### Docs refactor (reorganisation, moves, new sections)

**Trigger:** Any of the following:
- A file is moved or renamed
- A cross-document link path changes
- A new index/TOC entry is added

1. **Branch:** `git checkout -b docs/<short-name>`
2. **Edit:** Make all structural changes (copy → fix internal links → delete original, or add/restructure sections).
3. **Verify — stale reference check:**
   - For every old path or filename: `grep -r "<old-path>" docs/` — must return zero hits (or only correctly updated occurrences).
   - Spot-check every TOC/index file that links to the changed content (typically `docs/architecture.md`, `CLAUDE.md`, `docs/issues/README.md`).
   - Confirm issue files in `docs/issues/` that referenced the old path now reference the new path.
4. **Commit:**
   ```bash
   git commit -m "docs(scope): description"
   ```
   No issue close step unless the change was specifically requested by an open issue.

**Commit prefix:** `docs(scope): …`  
**No issue required** for routine maintenance. Open one only if the work is large enough to need acceptance criteria tracked separately.

---

## Quick reference

| Path | Entry | Key gate | Commit prefix |
|---|---|---|---|
| Discovery | Brainstorm file | All questions settled or deferred | `chore: brainstorm #N → issues #X–Y` |
| Feature | Issue with acceptance criteria | Legal / Architecture / Discovery | `feat(scope): …` |
| Bugfix | Bug issue with reproduction steps | Failing regression test before fix | `fix(scope): …` |
| Hotfix | Smoke test observation | `mix precommit` exits 0 | `fix(scope): …` |
| Docs fix | Correction in place | Read-back confirms edit | `docs(scope): …` |
| Docs refactor | Structural move or rename | Stale-ref grep returns zero hits | `docs(scope): …` |

| Phase (Feature/Bugfix) | Done when |
|---|---|
| Issue | Acceptance criteria written |
| Branch | Branch exists |
| Red | `mix test` fails for the right reason |
| Green | `mix test` passes, existing tests still pass |
| Refactor | Still passing, code is clean |
| Verify | `mix precommit` exits 0 |
| Commit & Close | Committed, issue closed |
