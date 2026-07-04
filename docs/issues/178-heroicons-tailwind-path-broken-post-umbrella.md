# #178 · Heroicons tailwind plugin path broken after umbrella conversion
**Status:** closed
**Opened:** 2026-07-03
**Closed:** 2026-07-04
**Priority:** low
**Tags:** bug, ui, ops

The dev asset watcher logs on every start:

```
Error: ENOENT: no such file or directory, scandir '/app/apps/gibbering_tales_web/deps/heroicons/optimized/24/outline'
```

`apps/gibbering_tales_web/assets/vendor/heroicons.js:6` resolves the icon directory as
`path.join(__dirname, "../../deps/heroicons/optimized")`, i.e. relative to the app —
but in the umbrella, deps live at the repo root (`/app/deps/heroicons/…`). Heroicon
classes are silently missing from the generated CSS in dev and any fresh build.

**Acceptance criteria**
- [x] `heroicons.js` resolves the umbrella root deps path (e.g. `../../../../deps/heroicons/optimized`)
- [x] Watcher starts without the ENOENT error; a `hero-*` class renders in the browser
- [x] Check `gibbering_tales_admin` for the same vendor plugin pattern and fix if present
- [x] `mix precommit` passes

**Resolution note:** the path fix alone wasn't sufficient to satisfy "a `hero-*` class
renders in the browser" — `apps/gibbering_tales_web/assets/css/app.css` also had a
stale `@source "../../lib/gibbering_web"` (pre-umbrella module name), so Tailwind
wasn't scanning any templates for `hero-*` class usage and emitted zero icon
utilities regardless of the JS fix. Corrected to `../../lib/gibbering_tales_web`.
`gibbering_tales_admin` has no heroicons vendor plugin, so nothing to fix there.
