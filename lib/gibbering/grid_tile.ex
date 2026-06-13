defmodule Gibbering.GridTile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grid_tiles" do
    field :x, :integer
    field :y, :integer
    field :texture, :string, default: "grass"
    field :walkable, :boolean, default: true
    field :decoration, :string

    belongs_to :map, Gibbering.GameMap
  end

  def changeset(tile, attrs) do
    tile
    |> cast(attrs, [:x, :y, :texture, :walkable, :decoration, :map_id])
    |> validate_required([:x, :y, :texture, :walkable, :map_id])
  end
end
