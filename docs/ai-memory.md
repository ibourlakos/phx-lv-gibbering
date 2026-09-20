# AI Memory

How AI-facing docs are tiered by how eagerly they load into an agent's context, and how CLAUDE.md's size is kept in check.

Adopted from `ploi-reacher`'s `.ai/rules/context-budget-tiers.md` (see [brainstorm #36](brainstorming/36-ai-memory-hygiene-from-ploi-reacher.md)), stripped of Laravel/Boost specifics.

---

## The three tiers

- **push-full** — loads every session, verbatim. `CLAUDE.md` itself is the only push-full document. Byte-capped, enforced by a test (see below).
- **push-head** — only a short description or pointer loads every session; the full body loads on demand. CLAUDE.md's `## Docs` section (one-line links to each sub-doc) is push-head: the pointer is always visible, the target doc isn't.
- **pull** — unbounded; loaded only when an agent recognizes the need. `docs/architecture/`, `docs/brainstorming/README.md`, `docs/issues/README.md`, and every other sub-doc are pull-tier.

The trade-off is explicit: push-full guarantees the content fires every session but taxes every session with it, relevant or not. Pull saves budget but risks a silent miss if nothing in the always-loaded content points an agent toward it. CLAUDE.md's `## Docs` TOC exists precisely to bridge that gap — a push-head pointer for every pull-tier doc.

## What belongs in push-full (CLAUDE.md)

Content earns push-full status only if it's needed in essentially every session regardless of task: the project pitch, the stack, the Legal hard-gate reminder, the Docs TOC pointers, and short behavioral instructions specific to how this user wants the agent to work.

Content that's only needed when actually touching a specific subsystem (the full brainstorming log, the full issue-tracker command reference) belongs in that subsystem's own pull-tier doc, with a one-line pointer left behind in CLAUDE.md.

## Byte cap

CLAUDE.md's size is enforced by an ExUnit test (see `docs/testing.md` for its layer and location) asserting the file stays under a fixed byte threshold. The cap is set from the file's actual size after a push-full/pull-tier split, plus headroom — not from an arbitrary round number.

## Escalation order when the cap is hit

When the byte-cap test fails, resolve it in this order:

1. **Prune stale rows or sections** — closed/deleted references, superseded content, anything no longer true.
2. **Move a section to pull-tier** — if it's push-full content that doesn't actually need to load every session, demote it to a sub-doc with a pointer left behind.
3. **Raise the cap** — last resort. Must be justified in the commit message (why the new content genuinely needs push-full status and pruning/demotion won't work), never a silent norm-bend.

## What's pull-tier today

| Content | Lives in |
|---|---|
| Brainstorming log (full table) | [docs/brainstorming/README.md](brainstorming/README.md) |
| Issue tracker commands (add/close/defer/block/cancel) | [docs/issues/README.md](issues/README.md) |
| Architecture detail | [docs/architecture.md](architecture.md) and `docs/architecture/` |
| Dev environment detail | [docs/dev-setup.md](dev-setup.md) |
| Testing strategy detail | [docs/testing.md](testing.md) |
| Workflow paths detail | [docs/workflow.md](workflow.md) |
| Legal detail | [docs/legal.md](legal.md) |
| Git conventions detail | [docs/git-policy.md](git-policy.md) |

An agent-behavior charter (writing style, judgment, confirm-before-acting gates) is planned as a future pull-tier doc — tracked by [#196](issues/196-agent-behavior-charter.md), not yet written.
