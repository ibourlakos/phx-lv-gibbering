# #3 · Save/load: before or after Ruleset behaviour split

**Status:** open
**Opened:** 2026-06-04
**Priority:** medium
**Tags:** discovery, architecture

From brainstorming `03-the-proving-grounds.md`. Campaign state is not persisted back to Postgres during a session — a server restart loses all mid-game positions. Open question: do we wire up persistence before splitting out the `Gibbering.Ruleset` behaviour, or after?

- **Before:** simpler — no abstraction boundary to cross yet; concrete DnD5e state is easy to serialise.
- **After:** cleaner — persistence speaks to the generic engine layer, not a ruleset-specific shape.

See also #12 (persistence strategy design) — that issue must be resolved before this ordering question becomes meaningful.

**Acceptance criteria**
- [ ] Decision recorded here with rationale
- [ ] Chosen order reflected in the implementation roadmap / next brainstorm
- [ ] Mid-game state survives a `docker compose restart app`
