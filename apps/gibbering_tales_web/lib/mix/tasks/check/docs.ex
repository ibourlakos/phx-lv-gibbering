defmodule Mix.Tasks.Check.Docs do
  use Mix.Task

  @shortdoc "Verify docs/ files exist and core modules have @moduledoc + @doc coverage"

  @moduledoc """
  Two-phase documentation gate run as part of `mix precommit`.

  Phase 1 — docs/ file existence: verifies that required Markdown files under
  `docs/` exist and are at least 100 bytes (guards against accidental truncation).

  Phase 2 — inline doc coverage: after compiling the app, scans all modules
  under the `Gibbering.Engine`, `GibberingTales.Data`, and `GibberingTales.Rulesets`
  namespaces and fails if any module is missing `@moduledoc` or any public
  function is missing `@doc`. Use `@moduledoc false` / `@doc false` to
  explicitly suppress docs for internal modules and functions.
  """

  @required_docs [
    "docs/architecture.md",
    "docs/architecture/data-model.md",
    "docs/dev-setup.md",
    "docs/testing.md",
    "docs/workflow.md"
  ]

  @core_prefixes [
    "Elixir.GibberingTalesWeb.Engine.",
    "Elixir.GibberingTales.Data.",
    "Elixir.GibberingTales.Rulesets."
  ]

  # Standard OTP/Ecto callbacks that never need @doc.
  @callback_names ~w(
    init handle_call handle_cast handle_info handle_continue
    terminate code_change format_status child_spec
    changeset __struct__ __schema__ __changeset__
  )

  def run(_args) do
    errors = check_docs_files() ++ check_module_docs()

    if errors != [] do
      IO.puts(:stderr, "\ncheck.docs failed:\n")
      Enum.each(errors, &IO.puts(:stderr, "  #{&1}"))
      IO.puts(:stderr, "")
      Mix.raise("check.docs: #{length(errors)} error(s)")
    end

    :ok
  end

  defp check_docs_files do
    root = File.cwd!()

    for path <- @required_docs, reduce: [] do
      acc ->
        full = Path.join(root, path)

        cond do
          not File.exists?(full) ->
            ["Missing docs file: #{path}" | acc]

          File.stat!(full).size < 100 ->
            ["Docs file too small (<100 bytes): #{path}" | acc]

          true ->
            acc
        end
    end
    |> Enum.reverse()
  end

  defp check_module_docs do
    Mix.Task.run("compile", [])

    env = Mix.env()
    build_root = Path.join(File.cwd!(), "_build/#{env}/lib")

    beam_dirs =
      case File.ls(build_root) do
        {:ok, apps} ->
          Enum.map(apps, &Path.join([build_root, &1, "ebin"]))

        {:error, _} ->
          []
      end

    Enum.flat_map(beam_dirs, fn beam_dir ->
      case File.ls(beam_dir) do
        {:ok, files} ->
          files
          |> Enum.filter(&String.ends_with?(&1, ".beam"))
          |> Enum.flat_map(fn file ->
            module = file |> String.replace_suffix(".beam", "") |> String.to_atom()
            if core_module?(module), do: check_module(module), else: []
          end)

        {:error, _} ->
          []
      end
    end)
  end

  defp core_module?(module) do
    name = Atom.to_string(module)
    Enum.any?(@core_prefixes, &String.starts_with?(name, &1))
  end

  defp check_module(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, module_doc, _, fn_docs} ->
        # :hidden means @moduledoc false — intentionally suppressed; skip entirely.
        if module_doc == :hidden do
          []
        else
          moduledoc_errors =
            if module_doc == :none do
              ["#{inspect(module)}: missing @moduledoc (use @moduledoc false to suppress)"]
            else
              []
            end

          fn_errors =
            for {{kind, name, arity}, _ann, _sig, doc, _meta} <- fn_docs,
                kind in [:function, :macro],
                to_string(name) not in @callback_names,
                not String.starts_with?(to_string(name), "_"),
                doc == :none do
              "#{inspect(module)}.#{name}/#{arity}: missing @doc"
            end

          moduledoc_errors ++ fn_errors
        end

      _ ->
        []
    end
  end
end
