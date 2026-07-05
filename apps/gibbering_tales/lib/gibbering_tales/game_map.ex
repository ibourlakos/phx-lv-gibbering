defmodule GibberingTales.GameMap do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maps" do
    field :x_extent, :integer, default: 10
    field :y_extent, :integer, default: 10
    field :tile_size, :integer, default: 32
    # %{"x,y,south|east" => %{"type" => "wall" | "door", "open" => bool}} — see GibberingEngine.Coords.edge_key/3
    field :edges, :map, default: %{}

    belongs_to :campaign, GibberingTales.Campaign
    has_many :tiles, GibberingTales.GridTile, foreign_key: :map_id

    timestamps()
  end

  def changeset(map, attrs) do
    map
    |> cast(attrs, [:x_extent, :y_extent, :tile_size, :campaign_id, :edges])
    |> validate_required([:x_extent, :y_extent, :tile_size, :campaign_id])
  end
end
