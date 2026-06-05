# Brainstorming

Raw exploration sessions — open-ended discovery before a problem is scoped enough to become an issue.

## How brainstorming fits the workflow

```
Brainstorm → Explore → Issue → Branch → Red → Green → Refactor → Verify → Commit
```

Use a brainstorm file when a topic is too wide or ambiguous to write a crisp acceptance criterion. Brainstorming maps trade-offs, domain knowledge, or design space before committing to a direction.

A brainstorm file is done when all of its open questions have been translated into issues. At that point the file is deleted — the issues are the durable record, not the transcript.

## Counter rule

- Next number is in `counter` (plain integer)
- Filenames: `<NN>-<slug>.md` zero-padded to two digits (e.g. `07-fog-of-war.md`)
- Increment `counter` after creating a new file
- Never reuse a number, even for deleted files
