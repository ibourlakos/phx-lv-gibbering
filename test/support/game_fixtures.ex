defmodule Gibbering.GameFixtures do
  @moduledoc """
  Shared helpers for building game state in tests.

  Two categories:
  - In-memory builders (`build_state/1`, `with_entity/3`, `with_tile/3`) — no DB, no process.
    Use these for testing pure functions in Rules and State.
  - DB factories (`insert_campaign/1`) — insert Ecto records into the sandbox DB.
    Use these for SceneServer integration tests.
  """

  alias Gibbering.Engine.State
  alias Gibbering.Rulesets.{DnD5e, DnD5e.Stats}
  alias Gibbering.{Repo, Campaign, GameMap, GridTile, Entity}

  # ---------------------------------------------------------------------------
  # In-memory state builders
  # ---------------------------------------------------------------------------

  @hero_id 1
  @monster_id 2

  @doc """
  Build a minimal %State{} entirely in memory — no DB required.

  Defaults:
  - 5x5 map of walkable grass tiles
  - Hero (id=1) at (2, 2) with speed 30
  - Monster (id=2) at (3, 3)

  Override any field via keyword opts:
    build_state(map_width: 10, map_height: 10)
    build_state(entities: %{...}, grid_tiles: %{...})
  """
  def build_state(opts \\ []) do
    width = Keyword.get(opts, :x_extent, 5)
    height = Keyword.get(opts, :y_extent, 5)

    tiles =
      for x <- 0..(width - 1), y <- 0..(height - 1), into: %{} do
        {{x, y}, %{texture: "grass", walkable: true, decoration: nil}}
      end

    hero_base = %{
      name: "Test Hero",
      type: "hero",
      sprite: "hero.png",
      race: "human",
      class: "fighter",
      level: 1,
      temp_hp: 0,
      x: 2,
      y: 2,
      hp: 10,
      max_hp: 10,
      tags: [],
      stats: %{
        "speed" => 30,
        "strength" => 16,
        "dexterity" => 12,
        "constitution" => 14,
        "intelligence" => 10,
        "wisdom" => 10,
        "charisma" => 10,
        "equipped_weapon" => %{
          "key" => "longsword",
          "damage_dice" => "1d8",
          "damage_type" => "slashing",
          "attack_ability" => "strength",
          "properties" => []
        },
        "equipped_armor" => %{"base_ac" => 16, "armor_category" => "heavy"}
      }
    }

    monster_base = %{
      name: "Test Goblin",
      type: "monster",
      sprite: "goblin.png",
      race: "human",
      class: "fighter",
      level: 1,
      temp_hp: 0,
      x: 3,
      y: 3,
      hp: 5,
      max_hp: 5,
      tags: [],
      stats: %{
        "speed" => 30,
        "strength" => 8,
        "dexterity" => 14,
        "constitution" => 10,
        "intelligence" => 10,
        "wisdom" => 8,
        "charisma" => 8,
        "equipped_armor" => %{"base_ac" => 11, "armor_category" => "light"}
      }
    }

    hydrate = fn base ->
      base
      |> Map.put(:action_economy, DnD5e.initial_action_economy(base))
      |> Map.put(:resources, DnD5e.initial_resources(base))
      |> Map.put(:conditions, [])
      |> Stats.hydrate_entity()
    end

    entities = %{
      @hero_id => hydrate.(hero_base),
      @monster_id => hydrate.(monster_base)
    }

    base = %State{
      campaign_id: 0,
      map_id: 0,
      x_extent: width,
      y_extent: height,
      tile_size: 32,
      grid_tiles: tiles,
      entities: entities,
      selected_id: nil,
      valid_moves: [],
      turn_order: [@hero_id],
      active_index: 0
    }

    Enum.reduce(opts, base, fn
      {:x_extent, _}, s -> s
      {:y_extent, _}, s -> s
      {key, val}, s -> Map.put(s, key, val)
    end)
  end

  @doc """
  Return the default hero id used in `build_state/1`.
  """
  def hero_id, do: @hero_id

  @doc """
  Return the default monster id used in `build_state/1`.
  """
  def monster_id, do: @monster_id

  @doc """
  Merge `attrs` into the entity `id` in `state`.

      state = with_entity(state, hero_id(), x: 0, y: 0)
      state = with_entity(state, monster_id(), hp: 1, tags: ["destructible"])
  """
  def with_entity(state, id, attrs) do
    entity = Map.merge(state.entities[id], Map.new(attrs))
    %{state | entities: Map.put(state.entities, id, entity)}
  end

  @doc """
  Merge `attrs` into the grid tile at `{x, y}`.

      state = with_tile(state, {2, 1}, walkable: false, texture: "stone")
  """
  def with_tile(state, pos, attrs) do
    existing = Map.get(state.grid_tiles, pos, %{texture: "grass", walkable: true})
    tile = Map.merge(existing, Map.new(attrs))
    %{state | grid_tiles: Map.put(state.grid_tiles, pos, tile)}
  end

  # ---------------------------------------------------------------------------
  # DB factories (require sandbox DB — use with DataCase)
  # ---------------------------------------------------------------------------

  @doc """
  Insert a Campaign (with a full 5x5 walkable grid, one hero, one monster)
  into the sandbox DB. Returns the campaign id to pass to SceneServer.start_link/1.

  Each call generates a unique campaign name so tests can run in any order.
  """
  def insert_campaign(attrs \\ %{}) do
    name = Map.get(attrs, :name, "Test Campaign #{System.unique_integer([:positive])}")
    width = Map.get(attrs, :x_extent, 5)
    height = Map.get(attrs, :y_extent, 5)
    dm_id = Map.get(attrs, :dm_id, nil)

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
        %{x: x, y: y, texture: "grass", walkable: true, map_id: map.id}
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
