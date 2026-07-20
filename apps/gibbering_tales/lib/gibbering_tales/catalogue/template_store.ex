defmodule GibberingTales.Catalogue.TemplateStore do
  @moduledoc """
  Compiles the game's `.svg.eex` appearance templates into functions at build time and
  dispatches to them by `(style, archetype, silhouette, facing, layer)`.

  This is the game-specific content half of the appearance pipeline — the generic
  archetype/silhouette/layer-order resolution lives in `GibberingEngine.ActorAppearance`,
  which calls into `render/6` here via an injected callback. See
  `docs/architecture/engine-decomposition.md` for why the split is drawn at this boundary.
  """

  require EEx

  @templates_dir Path.expand("../../../priv/appearance_templates", __DIR__)
  @default_style "dst"

  templates_dir = @templates_dir
  files = Path.wildcard(Path.join(templates_dir, "*/*/*/*/*.svg.eex"))

  for file <- files do
    [style, archetype, silhouette, facing, layer_file] =
      file |> Path.relative_to(templates_dir) |> Path.split()

    layer = String.replace_suffix(layer_file, ".svg.eex", "")

    fun_name =
      String.to_atom(Enum.join(["render", style, archetype, silhouette, facing, layer], "__"))

    # Layers with no `assigns.*` interpolation (e.g. shadow, which is neutral across
    # styles) would otherwise trip "variable assigns is unused".
    arg = if File.read!(file) =~ "assigns", do: :assigns, else: :_assigns

    EEx.function_from_file(:def, fun_name, file, [arg])
  end

  @doc """
  Renders a single (archetype, silhouette, facing, layer) fragment for the given style,
  falling back to the default ("dst") style when the requested style has no template for
  that combination.
  """
  @spec render(String.t(), atom(), atom(), atom(), atom(), map()) :: String.t()
  def render(style, archetype, silhouette, facing, layer, assigns) do
    fun = fun_name(style, archetype, silhouette, facing, layer)

    cond do
      function_exported?(__MODULE__, fun, 1) ->
        apply(__MODULE__, fun, [assigns])

      style != @default_style ->
        render(@default_style, archetype, silhouette, facing, layer, assigns)

      true ->
        raise "missing appearance template for #{inspect({style, archetype, silhouette, facing, layer})}"
    end
  end

  defp fun_name(style, archetype, silhouette, facing, layer) do
    ["render", style, archetype, silhouette, facing, layer]
    |> Enum.join("__")
    |> String.to_atom()
  end
end
