# #178 · Heroicons tailwind plugin path broken after umbrella conversion
**Status:** open
**Opened:** 2026-07-03
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
- [ ] `heroicons.js` resolves the umbrella root deps path (e.g. `../../../../deps/heroicons/optimized`)
- [ ] Watcher starts without the ENOENT error; a `hero-*` class renders in the browser
- [ ] Check `gibbering_tales_admin` for the same vendor plugin pattern and fix if present
- [ ] `mix precommit` passes
