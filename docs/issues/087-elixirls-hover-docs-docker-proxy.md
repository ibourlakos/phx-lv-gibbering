# #87 · ElixirLS hover documentation not working via Docker proxy

**Status:** deferred
**Opened:** 2026-06-06
**Deferred because:** Non-blocking quality-of-life gap; syntax highlighting and the language server connection work. Hover docs may require deeper investigation into how ElixirLS resolves project context through the Docker exec pipe.
**Priority:** low
**Tags:** ops

ElixirLS connects via the Docker proxy (`elixir-ls-release/language_server.sh`) but hover documentation does not appear on code element hover. Syntax highlighting and server launch work correctly.

Possible causes:
- ElixirLS inside the container may not be building the project (autoBuild needs a running mix project with access to source)
- The LSP workspace root path sent by VS Code may not match the container's `/app` path, causing ElixirLS to fail silently on indexing
- The `elixirLS.projectDir` or working directory may need explicit configuration

**Acceptance criteria**
- [ ] Hovering over a module, function, or built-in produces the expected documentation popup in VS Code
- [ ] No path mismatch warnings in the ElixirLS output panel
