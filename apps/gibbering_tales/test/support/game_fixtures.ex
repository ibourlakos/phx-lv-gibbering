defmodule GibberingTales.GameFixtures do
  @moduledoc "DB factories for Campaign/Map/Entity records in gibbering_tales tests."

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, GameMap, GridTile, Entity}

  def insert_campaign(attrs \\ %{}) do
    name = Map.get(attrs, :name, "Test Campaign #{System.unique_integer([:positive])}")
    dm_id = Map.get(attrs, :dm_id, nil)
    width = Map.get(attrs, :x_extent, 5)
    height = Map.get(attrs, :y_extent, 5)

    {:ok, campaign} = Repo.insert(%Campaign{name: name, dm_id: dm_id})

    map =
      Repo.insert!(%GameMap{
        campaign_id: campaign.id,
        x_extent: width,
        y_extent: height,
        tile_size: 32
      })

    Repo.update!(Campaign.changeset(campaign, %{active_map_id: map.id}))

    tile_rows =
      for x <- 0..(width - 1), y <- 0..(height - 1) do
        %{x: x, y: y, texture: "grass", movement: %{"walk" => 100, "fly" => 100}, map_id: map.id}
      end

    Repo.insert_all(GridTile, tile_rows)

    Repo.insert!(%Entity{
      name: "Test Hero",
      type: "hero",
      sprite: "hero.png",
      x: 2,
      y: 2,
      hp: 10,
      max_hp: 10,
      tags: [],
      stats: %{"speed" => 30},
      campaign_id: campaign.id
    })

    Repo.insert!(%Entity{
      name: "Test Goblin",
      type: "monster",
      sprite: "goblin.png",
      x: 3,
      y: 3,
      hp: 5,
      max_hp: 5,
      tags: [],
      stats: %{},
      campaign_id: campaign.id
    })

    campaign.id
  end
end
