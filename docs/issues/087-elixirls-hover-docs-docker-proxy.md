# #87 · ElixirLS hover documentation not working via Docker proxy

**Status:** closed
**Opened:** 2026-06-06
**Closed:** 2026-06-06
**Priority:** low
**Tags:** ops

ElixirLS connects via the Docker proxy (`elixir-ls-release/language_server.sh`) but hover documentation does not appear on code element hover. Syntax highlighting and server launch work correctly.

Root cause: `deps_cache` and `build_cache` Docker volumes were only mounted at `/app`, not at the host path that VS Code sends as `rootUri`. ElixirLS ran `mix deps.check` at the host path and found no compiled deps, causing the build to fail before indexing.

Fix: `compose.override.yaml` now mounts both volumes at the host path as well.

**Acceptance criteria**
- [x] Hovering over a module, function, or built-in produces the expected documentation popup in VS Code
- [x] No path mismatch warnings in the ElixirLS output panel
