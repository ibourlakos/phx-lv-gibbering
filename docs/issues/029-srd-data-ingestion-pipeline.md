# #29 · SRD data ingestion pipeline
**Status:** closed
**Opened:** 2026-06-05
**Closed:** 2026-06-05
**Priority:** medium
**Tags:** architecture, ops

The Gibbering Engine's rules engine needs structured reference data for monsters, spells, classes, and races. Currently everything is hand-coded in seeds. We need a repeatable ETL pipeline that ingests SRD 5.1 data into the DB.

Candidate data source: Open5e API / open5e-api JSON dumps (CC-BY-4.0, SRD-only subset).

Key design questions:
- Which tables hold static reference data (monsters, spells, classes, races, conditions)?
- How does the LegalGuard filter run at ingestion time to block Product Identity terms?
- Do we ingest once at deploy time (seeds) or build a re-runnable Mix task?
- How do ingested monster stat blocks link to live `game_sessions.live_entities`?

**Acceptance criteria**
- [x] Static reference tables designed (or JSONB blobs decided) and migrated
- [x] Mix task `mix gibbering.ingest` fetches/parses Open5e SRD data and seeds the DB
- [x] LegalGuard validation runs at ingest time and logs/skips Product Identity entries
- [x] At least monsters and spells are queryable from the engine at runtime
- [x] License of Open5e data source verified and recorded in `docs/legal.md`
