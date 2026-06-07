# #105 · Polytope architecture model — mini-treatise and terminology reference

**Status:** closed
**Opened:** 2026-06-07
**Closed:** 2026-06-07
**Priority:** medium
**Tags:** architecture, discovery

The architectural discussion that emerged from designing the ruleset UI, fog-of-war ownership, and active effect system (#25, #26, #34) surfaced a broader model: a multidimensional generalization of hexagonal architecture we are calling the *bounded context polytope*. The model, its taxonomy, its pattern language, and its relationship to the existing literature need to be documented before the individual design decisions are written.

**Acceptance criteria**
- [x] A prose document is added to `docs/` that explains the polytope model for a reader unfamiliar with the prior discussion
- [x] The document defines the taxonomy: dimension, parallel, context, aspect
- [x] The document names the five dimensions for this system and enumerates their parallels and contexts
- [x] The event bus as meta-hexagon and fractal self-similarity are covered
- [x] Time as a dimension and its architectural consequences are covered
- [x] The biological analogy is included with the DNA/RNA/Published Language mapping
- [x] The design pattern map is included
- [x] The UML vocabulary is included
- [x] A terminology section credits the literature and distinguishes coined terms from established ones
