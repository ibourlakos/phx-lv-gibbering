# Brainstorm #36 — AI memory hygiene: budget tiers, agent-behavior charter, brainstorm/issue lifecycle discipline

**Status:** settled — ready for triage
**Date:** 2026-09-20

---

## Context

`ploi-reacher` (yoltlabs, Laravel + Filament + Laravel Boost) inherited and adjusted its AI/guideline/workflow docs from this project, then matured them well beyond what we have. A survey of its `.ai/`, `.claude/`, and `docs/` tooling turned up several patterns that are **language-agnostic** — not Laravel/Boost/Filament-specific — and worth re-adopting here.

This brainstorm scopes a mini epic around the three highest-leverage, lowest-risk patterns:

1. **Context-budget tiers** for CLAUDE.md and related docs (push-full / push-head / pull), with an enforced size cap.
2. **Agent-behavior charter** — a dedicated doc for writing style, judgment, calibration, scope discipline, and confirm-before-acting rules.
3. **Brainstorm/issue lifecycle discipline** — explicit ending states, a "settlement evacuates the memory" rule, and "comments carry no authority."

Everything else surfaced in the survey (subagent memory-scoping hooks, per-role agent-memory note style, `env-drift`-style skills, `infer-conventions` methodology) is parked as open questions / future brainstorm material — not in scope for this epic.

---

## Target 1 — Context-budget tiers

### The problem

CLAUDE.md has no size discipline. It already carries a 17-row brainstorming log plus issue-tracker conventions plus dev-setup shorthand plus Claude Instructions, and it grows every time a brainstorm or issue-system change lands. Nothing stops it from becoming the kind of unbounded, always-loaded file that taxes every session regardless of relevance.

ploi-reacher's `.ai/rules/context-budget-tiers.md` formalizes three tiers:

- **push-full** — loads every session verbatim (CLAUDE.md itself). Byte-capped, enforced by a test.
- **push-head** — only a short description/pointer loads every session; the full body loads on demand (their skill descriptions vs. skill bodies).
- **pull** — unbounded; loaded only when an agent recognizes the need (rule files, `docs/`, architecture sub-docs).

They enforce the push-full cap with `tests/Feature/Guidelines/ContextBudgetTest.php`, which asserts CLAUDE.md stays under a fixed byte budget.

### Design options

- **Where does the tier taxonomy live?** A new `docs/ai-memory.md` (or similar) vs. a section inside `docs/workflow.md` vs. a note at the top of CLAUDE.md itself.
- **What's push-full vs. pull today?** CLAUDE.md is push-full. The brainstorming log table and issue-tracker instructions inside CLAUDE.md are candidates to demote to pull (a pointer + `docs/brainstorming/README.md` / `docs/issues/README.md` already exist and are pull-tier). The full "Docs" TOC section is arguably push-head already (one-line links).
- **How to enforce the cap?** Elixir/ExUnit equivalent of their PHPUnit test — a test reading `CLAUDE.md`, asserting byte size under some threshold. Needs a concrete number (their cap: 33,900 bytes) — ours would need its own baseline measured from current size plus headroom.
- **What triggers a trim?** When the cap test fails, is the fix "prune stale rows," "move a section to pull-tier," or "raise the cap with justification"? Needs an explicit escalation rule so hitting the cap doesn't become a silent norm-bend.

### Decisions

| Question | Decision |
|---|---|
| Where does the tier taxonomy live? | New `docs/ai-memory.md`, linked from CLAUDE.md's Docs TOC — consistent with the existing sub-doc pattern. |
| What demotes to pull-tier? | Both the brainstorming log table and the issue-tracker instructions move out of CLAUDE.md. The brainstorming log table moves into `docs/brainstorming/README.md` (or a pointer-only line remains); the issue-tracker's add/close/defer/block/cancel instructions move into `docs/issues/README.md`. CLAUDE.md keeps one-line pointers to each. |
| How is the cap enforced? | An ExUnit test asserting `CLAUDE.md`'s byte size stays under a fixed threshold, failing loudly (in `mix precommit`/CI) if exceeded. |
| What's the byte target? | Current CLAUDE.md is 9,650 bytes *before* the demotions above (which will shrink it further). Set the cap at current post-demotion size + ~20% headroom — exact number determined when the demotion is implemented, since it depends on final post-move size. |
| What triggers a trim when the cap is hit? | Prune stale rows or move a section to pull-tier first; raising the cap is a last resort and must be justified in the commit message, not a silent norm-bend. State this escalation order in `docs/ai-memory.md`. |
| Where does the ExUnit test live, and does Path [D] (docs-only) still skip `mix precommit`? | Test lives at `test/gibbering/docs_test.exs` (or similar). A CLAUDE.md edit is a docs-only change under Path [D], but since this specific test exists precisely to guard CLAUDE.md, the cap test itself should still run on any CLAUDE.md edit even under Path [D] — call this out explicitly as a Path [D] exception in `docs/workflow.md` when implemented. |

---

## Target 3 — Agent-behavior charter

### The problem

CLAUDE.md's "Claude Instructions" section today is two bullet points ("be concise," "keep me checked if feedback gets out of hand") plus process pointers. ploi-reacher's `.ai/guidelines/40-agent-behavior.md` is a much fuller charter covering writing style, judgment, calibration, scope discipline, and a concrete confirm-before-acting gate list — and it's almost entirely portable prose, framework-agnostic.

### Design options

- **New doc vs. expanded section.** A dedicated `docs/agent-behavior.md` (linked from CLAUDE.md's docs TOC, matching the existing sub-doc pattern) vs. growing the "Claude Instructions" section in place. Given target 1's budget-tier push, a separate pull/push-head doc is more consistent — CLAUDE.md keeps a short pointer + maybe the two lines that most need to be push-full (concise, keep-me-checked).
- **Sections to adapt from ploi-reacher, minus Laravel specifics:**
  - Writing style rules (no em-dashes, no rule-of-three padding, no opening flattery, lead with the answer)
  - Judgment section (flag problems noticed outside current task scope — security holes, races, architectural issues — rather than silently ignoring or silently fixing)
  - Calibration section (distinguish verified / believed / guessed explicitly in wording)
  - Scope section ("no drive-by cleanup" — report noticed fixes, don't bundle them in)
  - Confirm-before-acting gate list — needs a **Gibbering-specific** version of their gate list (their list: git commit/push, GitHub issue/board writes, destructive Docker, spawning a peer on an expensive model, widening agent write scope). Ours already has fragments of this in git-policy.md (never `git add -A`, commit policy) and CLAUDE.md (OTP process handling) — this charter would be the place to consolidate and extend it, not duplicate it.
- **Overlap with existing docs.** `docs/git-policy.md` already covers commit/branch conventions; `docs/workflow.md` already covers path selection and gates. The charter should point at those rather than restate them (ploi-reacher's own stated principle: "point at guidelines, don't restate them").

### Decisions

| Question | Decision |
|---|---|
| Doc vs. expanded section? | New `docs/agent-behavior.md`, linked from CLAUDE.md's Docs TOC. CLAUDE.md keeps a short pointer; "be concise" and "keep me checked" stay as-is in CLAUDE.md's own short instructions block rather than moving, since they're compact and specific to this user's working style. |
| What's Gibbering's confirm-before-acting gate list? | Adopt the full candidate list as a *starting point*, not a rigid rule: git commit/push (pointer to `docs/git-policy.md`), destructive OTP process actions (stopping/killing a live `SceneServer` etc.), deleting brainstorm/issue files, Docker volume/container prune, editing `compose.yaml` env vars, widening any future subagent's write scope. To avoid the list becoming overly strict or a source of friction, phrase each item around *irreversible or outward-facing* actions specifically (matching the existing system-level guidance already in play), not routine reads or edits — and note in the charter that the list is expected to evolve, with removal/loosening as legitimate an outcome as tightening if an item proves to just add noise without preventing real mistakes. |
| Tension with Path-based workflow's standing authorizations (e.g. Path D skipping `mix precommit`)? | No real tension: the gate list covers actions, not process steps. `docs/workflow.md`'s path-based skips (like Path D not requiring `mix precommit`) are about *which verification steps apply*, not about bypassing confirmation before an irreversible action. The charter should explicitly say it defers to `docs/workflow.md` for process/path selection and only adds the action-level confirmation layer on top. |

---

## Target 4 — Brainstorm/issue lifecycle discipline

### The problem

Our brainstorm lifecycle (`docs/brainstorming/README.md`) already has Open → Explore → Settle → Triage → Commit → Close, which is more structured than ploi-reacher's issue-label system in some ways (we require full triage before commit; they allow an issue to sit in discovery/brainstorm state longer). But we're missing two things they have and we don't:

1. **Explicit ending states** beyond "settled" — they distinguish *Superseded* (a newer discovery/brainstorm replaces this one outright), *Revamped* (significantly reworked mid-flight), and *Settled-with-decisions* (the normal path). Ours only really has "settled → triaged → closed" with no vocabulary for a brainstorm that gets abandoned or superseded rather than resolved.
2. **"Settlement evacuates the memory"** — their rule that no durable decision may live only in a closed issue; it must graduate into a living doc (their `docs/decisions/` ADRs) or a spawned issue description. Our brainstorm files *self-delete* on close (step 6), and the durable record is supposed to be the issues filed — but there's no explicit check that a decision actually made it out of the brainstorm file and into an issue's acceptance criteria before the file is deleted. It's implied by the Triage step but not stated as a gate.
3. **"Comments carry no authority"** — only the file/issue body counts as the record; a discussion comment (in our case, presumably conversational turns during "Explore") must get folded back into the document. We don't have a directly analogous artifact (no GitHub issue comment threads referenced in our workflow docs). Settled below: authority here is indirect, not a rule that needs stating on its own.

### Design options

- **Add ending states to `docs/brainstorming/README.md` step 3 (Settle):** alongside "Decision" and "Explicit deferral," add **Superseded** (references the brainstorm number that replaces it, closes without triage) and **Revamped** (documented restart within the same file/number, noted with a timestamp or marker).
- **Add an explicit graduation gate to step 4 (Triage) or step 6 (Close):** before deleting a brainstorm file, verify every Decision in its Decisions table is reflected in at least one filed issue's acceptance criteria or a living architecture doc. Could be a literal checklist line in the Close section: "Confirm each Decisions-table row appears in a filed issue or docs/architecture/ before deleting this file."
- **Make "comments carry no authority" explicit** as a one-line rule near the Explore section: discussion during exploration is not durable; only content written into the file (Decisions table, Open Questions list) counts, matching the existing "no commit required per session" language but stating the inverse (nothing outside the file is binding).
- **Does this apply to `docs/issues/` too, or only brainstorming?** ploi-reacher's version is entirely issue-centric (their brainstorm *is* a GitHub issue with a label). Ours splits brainstorm-files vs. issue-files as two separate systems. The ending-state vocabulary (Superseded/Revamped) may fit better on brainstorm files; the "evacuates the memory" gate fits the brainstorm→issue boundary; "comments carry no authority" could apply to both but matters most wherever informal discussion risks being the only record.

### Decisions

| Question | Decision |
|---|---|
| Superseded/Revamped as literal `**Status:**` values, or handled structurally? | Add them as literal `**Status:** ` values in the brainstorm file header, alongside `open`/`settled`. Document all values in `docs/brainstorming/README.md`'s lifecycle section. A `Superseded` file also gets a "Superseded by #N" line pointing at the replacing brainstorm. |
| Manual checklist or enforced script for the graduation ("evacuation") gate? | Enforced by script: before a brainstorm file is deleted at Close, a script checks that the brainstorm number is referenced somewhere in `docs/issues/` (or `docs/architecture/`), refusing deletion otherwise. Scoped to `docs/brainstorming/` only for now — see below. |
| Does the evacuation gate extend to `docs/issues/` close/defer/cancel too? | Not in this epic. Scope the script to brainstorm-file deletion only. Extending equivalent enforcement to issue lifecycle actions is left as an open question for a future brainstorm. |
| Is a `docs/decisions/` (ADR) layer needed, or does `docs/architecture/` already cover "evacuates to a living doc"? | `docs/architecture/` is sufficient for now — no new ADR system in this epic. The evacuation gate accepts either a filed issue or a `docs/architecture/` doc as the destination. Revisit only if decisions start getting lost inside `docs/architecture/`'s living-doc edit-in-place style (no ADR-style immutable trail) in practice. |
| Does "comments carry no authority" need its own explicit rule? | No — authority here is indirect, not something that needs a standalone rule. If a conversational comment causes an issue description or brainstorm Decisions table to be updated, *that update* is what carries authority, not the comment itself. This is already implicit in the existing lifecycle language ("the document is a working draft"); no new rule text needed in `docs/brainstorming/README.md`. |

---

## Open questions parked from the wider survey (not in scope for targets 1/3/4)

These surfaced in the ploi-reacher survey but are deliberately left out of this epic — candidates for a future brainstorm if we want them:

- **`.ai/` single-source → generated CLAUDE.md pattern.** Splitting CLAUDE.md into editable source sections concatenated by a script, with a hook blocking direct edits to the generated file. Bigger structural change than targets 1/3/4; worth its own brainstorm once/if CLAUDE.md's size actually becomes unmanageable even with budget tiers in place.
- **Subagent memory-scoping hook** (`.claude/hooks/scope-writes-to-own-memory.sh` equivalent) — only relevant once/if we adopt a `.claude/agents/` multi-role subagent setup. Not applicable today; no such roster exists in this project.
- **Per-role agent-memory note style** (small dated linked topic files instead of one growing MEMORY.md, explicit "re-verify before trusting" framing) — same dependency as above; needs a multi-agent-memory system to exist first.
- **`env-drift`-style skill** (diff gitignored env vars against a tracked example). Low current value since dev env vars are hardcoded in `compose.yaml` (no `.env` file per CLAUDE.md's Dev Setup section) — revisit if that changes.
- **`infer-conventions` skill methodology** (sweep codebase, classify Pattern/Default/Conflict/No-signal, record only real patterns with 3+ examples) — a good template for bootstrapping an Elixir/Phoenix "house conventions" doc, but a separate, larger effort from this epic.
- **`kanban-drift`-style board sync check** — not applicable; no GitHub Project board in use currently for this repo, as far as this brainstorm's context shows.

---

## Issues Opened

- **Target 1** → [#195](../issues/195-context-budget-tiers-claude-md.md) — context-budget tiers: `docs/ai-memory.md` (tier taxonomy + escalation order), CLAUDE.md demotions (brainstorming log → `docs/brainstorming/README.md`, issue-tracker instructions → `docs/issues/README.md`), ExUnit byte-cap test, Path [G] exception note in `docs/workflow.md`.
- **Target 3** → [#196](../issues/196-agent-behavior-charter.md) — agent-behavior charter: `docs/agent-behavior.md` (writing style, judgment, calibration, scope, confirm-before-acting gate list with explicit "expected to evolve" framing), CLAUDE.md pointer.
- **Target 4** → [#197](../issues/197-brainstorm-lifecycle-ending-states-and-evacuation-gate.md) — brainstorm lifecycle discipline: `Superseded`/`Revamped` status values + evacuation-gate script + documentation updates in `docs/brainstorming/README.md`.

**Cross-reference:** [#179](../issues/179-ai-workflow-docs-subtree-extraction.md) (extracting AI workflow docs into a reusable subtree) is adjacent but distinct — that issue is about a distribution mechanism for the existing docs, not new content. No overlap; worth sequencing #179 after #195–197 land, so the subtree extraction captures the updated structure rather than needing a second pass.

This brainstorm is fully triaged. Ready to Close once #195, #196, and #197 are closed or deferred (per `docs/brainstorming/README.md` step 6).

**Renumbering note:** originally triaged as issues #183–185; renumbered to #195–197 during a rebase onto `main` after a concurrent session's PR claimed #182–194 first. No content changed, only the numbers and filenames.
