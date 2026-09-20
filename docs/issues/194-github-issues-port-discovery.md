# #194 · GitHub Issues port — discovery

**Status:** open
**Opened:** 2026-09-20
**Priority:** low
**Tags:** discovery, ops

Captures an external labeling/porting commentary evaluating a move from the
file-based `docs/issues/` tracker to GitHub Issues. Not a commitment to
port — filed to preserve the analysis for a later decision.

**Label set proposed:** port the 11 existing tags ~1:1 (they're already
label-sized). Two taxonomy notes from the data:
1. `architecture` appears on 130/181 issues (72%) — a label on nearly
   everything discriminates nothing. If porting, consider reserving it for
   issues that actually trip the Architecture gate (shared interface, >2
   modules, SVG pipeline) rather than "this is thoughtful work" in general.
2. Kind (bug/discovery/docs) vs area (architecture/gameplay/rendering/...)
   is currently a flat, conflated namespace. GitHub labels are flat too, so
   it still works, but a `kind:`/`area:` prefix convention would keep the
   label dropdown sane past ~15 labels. Flat matches today's docs; this is
   a style call, not a blocker.

**What doesn't map cleanly to labels (the real design decisions):**
- **Status** (open/deferred/blocked/in-progress) — GitHub is binary
  open/closed. Recommendation: Projects v2 Status field, not `status:*`
  labels — keeps labels semantic, board carries lifecycle. Matters because
  15 deferred issues are parked, not dead, and must cleanly return to open.
- **Cancelled** → GitHub's native "close as not planned" (1 current usage,
  #82).
- **Work packages** → concern groupings with sequencing, not time-boxes.
  Milestones' "complete when all issues closed" semantic is close but
  Milestones have no "parked" state (an active WP can be parked). A
  Projects v2 board with a "Work Package" single-select field handles
  active/parked/complete + per-issue status in one place. Only 9/181 issue
  files currently reference their WP back — a Project field would enforce
  the assignment porting is a chance to fix.
- **Cross-package gates** ("gated by #X — do not start") — GitHub has no
  native issue dependency. Convention needed: a "Dependencies" section in
  the body, checked by `gh` CLI or a blocked-by Project field.
- **Brainstorms** (workflow Path A) → GitHub Discussions, category
  "Brainstorms." Settle gate = marking answers resolved; triage = extracted
  issues cross-linked from the discussion. The counter file and numbered
  files would go away.
- **Path F** (discovery → brainstorm promotion) → label swap: remove
  `discovery`, link the new Discussion, close the issue.

**Gains:** ~50% of recent git history is issue-admin commits
(`chore: add/close issue #N`) — these disappear; cross-references
auto-link; ad hoc "which state does X assume" becomes searchable instead of
a file to remember to update.

**Costs — the real blocker:** renumbering. 181 issue files
cross-reference each other by number, and WP files reference roughly 40
issue numbers each. A `gh` CLI script could create issues in original
order and build an old→new number map, but every referencing body needs a
rewrite pass, plus something like an "Origin: docs/issues/N.md" footer so
old brainstorm/doc links keep resolving. `workflow.md`, the CLAUDE.md
issue-tracker section, and both counter files (`docs/issues/counter`,
`docs/brainstorming/counter`) would all need a Path [G] docs-refactor
pass, including a stale-reference grep.

**Decision:** not committed to porting. Sizing (likely its own Work
Package given the cross-reference rewrite scope) and the port/no-port call
itself are deferred to a later, separate decision.

**Acceptance criteria**
- [ ] Decide whether to port to GitHub Issues at all
- [ ] If porting: size the renumbering/rewrite effort as a Work Package
- [ ] If porting: decide labels-vs-Projects-v2 split for status and WP tracking
- [ ] If not porting: close as won't-do with rationale
