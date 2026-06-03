alias Gibbering.{Repo, Campaign, GridTile, Entity}

# Wipe existing seed data
Repo.delete_all(Entity)
Repo.delete_all(GridTile)
Repo.delete_all(Campaign)

# Campaign
campaign =
  Repo.insert!(%Campaign{
    name: "The Proving Grounds",
    map_width: 10,
    map_height: 10,
    tile_size: 56
  })

# 10x10 map — grass floor with stone border and a few interior walls
stone_positions =
  MapSet.new(
    for(x <- 0..9, do: {x, 0}) ++
      for(x <- 0..9, do: {x, 9}) ++
      for(y <- 0..9, do: {0, y}) ++
      for(y <- 0..9, do: {9, y}) ++
      [{4, 3}, {4, 4}, {4, 6}]
  )

decorations = %{
  {1, 2} => "dead_tree",
  {7, 2} => "dead_tree",
  {3, 7} => "rock_cluster",
  {7, 6} => "rock_cluster",
  {6, 3} => "bones",
  {2, 8} => "grass_tuft",
  {8, 7} => "grass_tuft",
  {5, 8} => "bones"
}

tiles =
  for x <- 0..9, y <- 0..9 do
    texture = if {x, y} in stone_positions, do: "stone", else: "grass"
    decoration = if texture == "grass", do: Map.get(decorations, {x, y}), else: nil

    %{
      x: x,
      y: y,
      texture: texture,
      walkable: texture == "grass",
      decoration: decoration,
      campaign_id: campaign.id
    }
  end

Repo.insert_all(GridTile, tiles)

# Warrior
Repo.insert!(%Entity{
  name: "Warrior",
  type: "hero",
  sprite: "warrior",
  x: 2,
  y: 5,
  hp: 20,
  max_hp: 20,
  tags: ["player_controlled"],
  stats: %{"speed" => 30, "strength" => 16},
  campaign_id: campaign.id
})

# Wizard
Repo.insert!(%Entity{
  name: "Wizard",
  type: "hero",
  sprite: "wizard",
  x: 2,
  y: 7,
  hp: 12,
  max_hp: 12,
  tags: ["player_controlled"],
  stats: %{"speed" => 25, "intelligence" => 18},
  campaign_id: campaign.id
})

# The Rock
Repo.insert!(%Entity{
  name: "The Rock",
  type: "object",
  sprite: "rock",
  x: 5,
  y: 5,
  hp: 8,
  max_hp: 8,
  tags: ["destructible", "blocking"],
  stats: %{},
  campaign_id: campaign.id
})

IO.puts("Seeded campaign ##{campaign.id}: #{campaign.name}")
IO.puts("Visit http://localhost:4000/game/#{campaign.id}")
