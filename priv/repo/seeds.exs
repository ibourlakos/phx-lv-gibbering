alias Gibbering.{Repo, Campaign, GridTile, Entity, CampaignMember}
alias Gibbering.Accounts

# Wipe existing seed data
Repo.delete_all(CampaignMember)
Repo.delete_all(Entity)
Repo.delete_all(GridTile)
Repo.delete_all(Campaign)

# Seed users (idempotent — skip if username exists)
{:ok, dm_user} =
  case Accounts.get_user_by_username("dungeon_master") do
    nil ->
      Accounts.register_user(%{username: "dungeon_master", password: "gibbering", role: "dm"})

    existing ->
      {:ok, existing}
  end

{:ok, player1} =
  case Accounts.get_user_by_username("aldric_player") do
    nil ->
      Accounts.register_user(%{username: "aldric_player", password: "gibbering", role: "player"})

    existing ->
      {:ok, existing}
  end

{:ok, player2} =
  case Accounts.get_user_by_username("sylvara_player") do
    nil ->
      Accounts.register_user(%{username: "sylvara_player", password: "gibbering", role: "player"})

    existing ->
      {:ok, existing}
  end

{:ok, player3} =
  case Accounts.get_user_by_username("zippik_player") do
    nil ->
      Accounts.register_user(%{username: "zippik_player", password: "gibbering", role: "player"})

    existing ->
      {:ok, existing}
  end

# Campaign
campaign =
  Repo.insert!(%Campaign{
    name: "The Proving Grounds",
    map_width: 10,
    map_height: 10,
    tile_size: 56,
    dm_id: dm_user.id
  })

# Campaign membership
for user <- [dm_user, player1, player2, player3] do
  Repo.insert!(%CampaignMember{campaign_id: campaign.id, user_id: user.id})
end

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

# Human Fighter
Repo.insert!(%Entity{
  name: "Aldric",
  type: "hero",
  sprite: "human_fighter",
  race: "human",
  class: "fighter",
  x: 2,
  y: 5,
  hp: 20,
  max_hp: 20,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "strength" => 17,
    "dexterity" => 13,
    "constitution" => 15,
    "intelligence" => 9,
    "wisdom" => 11,
    "charisma" => 9
  },
  campaign_id: campaign.id
})

# Elf Wizard
Repo.insert!(%Entity{
  name: "Sylvara",
  type: "hero",
  sprite: "elf_wizard",
  race: "elf",
  class: "wizard",
  x: 2,
  y: 7,
  hp: 12,
  max_hp: 12,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "strength" => 8,
    "dexterity" => 14,
    "constitution" => 13,
    "intelligence" => 20,
    "wisdom" => 15,
    "charisma" => 10,
    "spells" => ["fire_bolt", "mage_hand", "magic_missile", "sleep"]
  },
  campaign_id: campaign.id
})

# Gnome Rogue
Repo.insert!(%Entity{
  name: "Zippik",
  type: "hero",
  sprite: "gnome_rogue",
  race: "gnome",
  class: "rogue",
  x: 3,
  y: 6,
  hp: 16,
  max_hp: 16,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 25,
    "strength" => 10,
    "dexterity" => 18,
    "constitution" => 13,
    "intelligence" => 16,
    "wisdom" => 12,
    "charisma" => 12
  },
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
