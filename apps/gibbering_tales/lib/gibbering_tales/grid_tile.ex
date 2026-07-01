defmodule GibberingTales.GridTile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grid_tiles" do
    field :x, :integer
    field :y, :integer
    field :texture, :string, default: "grass"
    field :movement, :map, default: %{}
    field :decoration, :string

    belongs_to :map, GibberingTales.GameMap
  end

  def changeset(tile, attrs) do
    tile
    |> cast(attrs, [:x, :y, :texture, :movement, :decoration, :map_id])
    |> validate_required([:x, :y, :texture, :map_id])
  end
end
