# Brainstorming

Raw exploration sessions — open-ended discovery before a problem is scoped enough to become an issue.

## Where brainstorming fits

The full workflow has three entry points (see [docs/workflow.md](../docs/workflow.md)):

```
[A] Brainstorm → Settle → Triage ─┐
[B]                      Issue ───┼──► Branch → Red → Green → Refactor → Verify → Commit
[C]                     Branch ───┘

[F] discovery Issue → too broad → Brainstorm (enter [A]) → defer original Issue
```

Enter at **Brainstorm** when a topic is too wide or ambiguous to write a crisp acceptance criterion. Brainstorming maps trade-offs, domain knowledge, or design space before committing to a direction. Once the questions are settled and issues are triaged, the brainstorm feeds into the Issue phase and the rest of the standard flow proceeds unchanged.

A `discovery` issue can also **escalate** into a brainstorm (path [F]) when working it reveals the problem is larger than an issue's scope. In that case: open a brainstorm file, defer the discovery issue referencing the new brainstorm number, and let the brainstorm's extracted issues replace it.

---

## Brainstorm lifecycle

### 1. Open

Create `<NN>-<slug>.md` in this directory (see counter rules below), increment the counter, add a row to the brainstorming log in [CLAUDE.md](../../CLAUDE.md), and commit:

```
chore: open brainstorm #N
```

### 2. Explore

Discussion sessions populate the document. Accumulate open questions, design options, and trade-offs. No commit required per session — the document is a working draft.

### 3. Settle

Work through each open question. Every question must resolve to one of:

- **Decision** — the chosen direction, documented in a Decisions table in the file
- **Explicit deferral** — noted with a reason; becomes a deferred issue or a note for a future brainstorm

A question left neither decided nor deferred is not settled. Do not proceed to Triage until all questions are settled.

### 4. Triage

Translate each settled decision into one or more issues in `docs/issues/`. Each issue gets acceptance criteria. Update the brainstorm document to reference the opened issue numbers and note that issues have been filed.

### 5. Commit

Commit the updated brainstorm document and all new issue files in **one atomic commit**:

```
chore: brainstorm #N → issues #X–Y
```

**Gate:** No open question without a decision or explicit deferral. A partially triaged brainstorm is not committed.

### 6. Close

Once all issues extracted from this brainstorm are closed or deferred in `docs/issues/`, the brainstorm has served its purpose:

1. Delete the `<NN>-<slug>.md` file
2. Remove its row from the brainstorming log in [CLAUDE.md](../../CLAUDE.md)
3. Commit:

```
chore: close brainstorm #N
```

The issues are the durable record. The brainstorm transcript is not.

---

## Counter rules

- Next number is in `counter` (plain integer)
- Filenames: `<NN>-<slug>.md` zero-padded to two digits (e.g. `07-fog-of-war.md`)
- Increment `counter` after creating a new file
- Never reuse a number, even for deleted files

---

## Brainstorm file structure

No rigid template — content is exploratory. Conventions that have worked well:

- Lead with a **Context** or framing section explaining why this brainstorm exists
- Use `##` sections per topic area
- Accumulate open questions as a bulleted list during exploration
- Replace the open questions list with a **Decisions** table once settled
- End with an **Issues Opened** section (or **Issues to Open** before triage) that links to the filed issues
- Note any cross-brainstorm dependencies with a pointer to the other file
