defmodule GibberingTalesWeb.Components.EntitySprites do
  @moduledoc """
  Renders an entity's board sprite by wiring the engine's content-agnostic appearance
  pipeline (`GibberingEngine.ActorAppearance`) to this game's template content
  (`GibberingTales.Catalogue.TemplateStore`).
  """

  use Phoenix.Component

  alias GibberingEngine.ActorAppearance
  alias GibberingTales.Catalogue.TemplateStore

  attr :x, :integer, required: true
  attr :y, :integer, required: true
  attr :entity, :map, required: true
  attr :appearances, :map, required: true
  attr :style_slug, :string, required: true

  def entity_sprite(assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      {Phoenix.HTML.raw(
        ActorAppearance.render_body(@entity, @appearances, @style_slug, &TemplateStore.render/6)
      )}
    </g>
    """
  end
end
