defmodule GibberingWeb.SVGAssertions do
  @moduledoc false

  # Structural SVG assertion helpers built on Floki.
  # Import this module in LiveView tests that assert SVG output:
  #
  #   import GibberingWeb.SVGAssertions
  #
  # All helpers accept either an HTML string or a pre-parsed Floki document.

  import ExUnit.Assertions

  @type html_or_doc :: String.t() | Floki.html_tree()

  defp parse(html) when is_binary(html), do: Floki.parse_document!(html)
  defp parse(doc), do: doc

  # ---------------------------------------------------------------------------
  # Entity visibility
  # ---------------------------------------------------------------------------

  @doc "Asserts that an entity group with `data-entity-id` equal to `entity_id` is present."
  def assert_entity_visible(html, entity_id) do
    doc = parse(html)
    results = Floki.find(doc, "[data-entity-id='#{entity_id}']")

    assert results != [],
           "Expected entity #{entity_id} to be visible in SVG, but it was not found"
  end

  @doc "Asserts that no entity group with `data-entity-id` equal to `entity_id` is present."
  def refute_entity_visible(html, entity_id) do
    doc = parse(html)
    results = Floki.find(doc, "[data-entity-id='#{entity_id}']")
    assert results == [], "Expected entity #{entity_id} to be hidden from SVG, but it was found"
  end

  # ---------------------------------------------------------------------------
  # HP bar (role-gated)
  # ---------------------------------------------------------------------------

  @doc """
  Asserts the DM HP bar for `entity_id` carries exact `data-hp` and `data-max-hp` attributes.
  Use in DM-role assertions only.
  """
  def assert_hp_exact(html, entity_id, hp, max_hp) do
    doc = parse(html)
    bars = Floki.find(doc, "#entity-#{entity_id} [data-layer='hp-bar']")
    assert bars != [], "Expected hp-bar layer for entity #{entity_id}, found none"
    [bar | _] = bars

    assert Floki.attribute(bar, "data-hp") == [to_string(hp)],
           "Expected data-hp=#{hp} on hp-bar for entity #{entity_id}"

    assert Floki.attribute(bar, "data-max-hp") == [to_string(max_hp)],
           "Expected data-max-hp=#{max_hp} on hp-bar for entity #{entity_id}"
  end

  @doc "Asserts the player HP bar for `entity_id` has no exact `data-hp` attribute."
  def refute_hp_exact(html, entity_id) do
    doc = parse(html)
    bars = Floki.find(doc, "#entity-#{entity_id} [data-layer='hp-bar']")
    assert bars != [], "Expected hp-bar layer for entity #{entity_id}, found none"
    [bar | _] = bars

    assert Floki.attribute(bar, "data-hp") == [],
           "Expected no data-hp on player hp-bar for entity #{entity_id}, but found one"
  end

  @doc "Asserts the player HP bar for `entity_id` carries the given bucket `label`."
  def assert_hp_bucket(html, entity_id, label) do
    doc = parse(html)
    bars = Floki.find(doc, "#entity-#{entity_id} [data-layer='hp-bar']")
    assert bars != [], "Expected hp-bar layer for entity #{entity_id}, found none"
    [bar | _] = bars

    assert Floki.attribute(bar, "data-hp-bucket") == [label],
           "Expected data-hp-bucket=#{label} on hp-bar for entity #{entity_id}"
  end

  # ---------------------------------------------------------------------------
  # Tile assertions
  # ---------------------------------------------------------------------------

  @doc "Asserts a tile polygon exists at grid position `{x, y}`."
  def assert_tile_at(html, x, y) do
    doc = parse(html)
    results = Floki.find(doc, "[data-grid-x='#{x}'][data-grid-y='#{y}']")
    assert results != [], "Expected tile at (#{x}, #{y}), found none"
  end

  # ---------------------------------------------------------------------------
  # Move overlay
  # ---------------------------------------------------------------------------

  @doc "Asserts at least one move overlay polygon is present."
  def assert_move_overlay(html) do
    doc = parse(html)
    results = Floki.find(doc, "[data-move-overlay]")
    assert results != [], "Expected move overlay polygons, found none"
  end

  @doc "Asserts no move overlay polygons are present."
  def refute_move_overlay(html) do
    doc = parse(html)
    results = Floki.find(doc, "[data-move-overlay]")
    assert results == [], "Expected no move overlay polygons, but found #{length(results)}"
  end

  # ---------------------------------------------------------------------------
  # Selection ring (SpriteCompositor — active entity ellipse)
  # ---------------------------------------------------------------------------

  @doc "Asserts the SpriteCompositor selection-ring ellipse is present (active entity turn)."
  def assert_selection_ring(html) do
    doc = parse(html)
    results = Floki.find(doc, "[data-layer='selection-ring']")
    assert results != [], "Expected selection-ring layer, found none"
  end

  @doc "Asserts the SpriteCompositor selection-ring ellipse is absent."
  def refute_selection_ring(html) do
    doc = parse(html)
    results = Floki.find(doc, "[data-layer='selection-ring']")
    assert results == [], "Expected no selection-ring layer, but found one"
  end

  # ---------------------------------------------------------------------------
  # Decorations
  # ---------------------------------------------------------------------------

  @doc "Asserts a decoration group with `data-decoration` equal to `type` is present."
  def assert_decoration(html, type) do
    doc = parse(html)
    results = Floki.find(doc, "[data-decoration='#{type}']")
    assert results != [], "Expected decoration '#{type}', found none"
  end

  @doc "Asserts no decoration group with `data-decoration` equal to `type` is present."
  def refute_decoration(html, type) do
    doc = parse(html)
    results = Floki.find(doc, "[data-decoration='#{type}']")
    assert results == [], "Expected no decoration '#{type}', but found one"
  end

  # ---------------------------------------------------------------------------
  # Condition badges
  # ---------------------------------------------------------------------------

  @doc "Asserts a condition badge circle with `data-condition` equal to `condition_id` is present."
  def assert_condition_badge(html, condition_id) do
    doc = parse(html)
    results = Floki.find(doc, "[data-condition='#{condition_id}']")
    assert results != [], "Expected condition badge for '#{condition_id}', found none"
  end
end
