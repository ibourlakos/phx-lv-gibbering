defmodule GibberingTales.Docs.ClaudeMdBudgetTest do
  @moduledoc """
  Meta/repo-hygiene test — asserts a property of a repo doc, not game behaviour.

  See `docs/ai-memory.md` for the context-budget tier taxonomy this enforces.
  `CLAUDE.md` is the project's only push-full document: it loads into every
  agent session verbatim, so its size is capped to keep that cost bounded.

  Lives here (not a game-domain test file) because this umbrella has no
  root-level `test/` and no other app is a better fit for a repo-wide meta
  concern — `gibbering_tales` is the domain app closest to root-level
  process/docs concerns, with no game-engine or web-rendering ties.
  """

  use ExUnit.Case, async: true

  # Measured post-demotion size (docs/ai-memory.md, docs/issues/README.md
  # split) plus ~20% headroom. See the escalation order in docs/ai-memory.md
  # before raising this: prune stale content, then move a section to
  # pull-tier, then — only as a last resort, justified in the commit
  # message — raise the cap.
  @claude_md_byte_cap 5_000

  test "CLAUDE.md stays within the push-full budget" do
    path = Path.join(umbrella_root(), "CLAUDE.md")
    bytes = File.stat!(path).size

    assert bytes <= @claude_md_byte_cap, """
    CLAUDE.md is #{bytes} bytes, over the push-full budget of \
    #{@claude_md_byte_cap} bytes.

    See docs/ai-memory.md for the escalation order:
      1. Prune stale rows or sections.
      2. Move a section to a pull-tier sub-doc, leaving a one-line pointer.
      3. Raise this cap — last resort, justify why in the commit message.
    """
  end

  defp umbrella_root do
    # mix test always runs from the umbrella root, but resolve explicitly
    # rather than assume cwd, since this test asserts on a root-level file.
    Path.expand("../../../../..", __DIR__)
  end
end
