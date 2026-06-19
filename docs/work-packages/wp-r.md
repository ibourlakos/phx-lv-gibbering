# WP-R · Display Testing & Testability

**Status:** active
**Source:** brainstorm #20 (display testing strategy)

Establish the Floki-based SVG assertion layer so that role-gated rendering and
fog-of-war correctness can be verified automatically rather than via visual review.

---

## Issues

| # | Title | Depends on |
|---|---|---|
| [#153](../issues/153-svg-testability-data-attributes-floki.md) | SVG testability — data attributes and Floki assertion layer | — |

---

## Active Front

```
#153  (no dependencies)
```

---

## Out of scope for this WP

- Playwright/Wallaby browser automation (deferred — overkill for server-rendered SVG)
- Snapshot golden file testing (follow-on after #153 ships)
- CI visual diff tooling (deferred)
