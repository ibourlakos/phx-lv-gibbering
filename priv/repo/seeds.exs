alias Gibbering.{Repo, Campaign, GridTile, Entity, CampaignMember}
alias Gibbering.Accounts
alias Gibbering.Admin
alias Gibbering.Catalogue.{Race, Class, Spell}
alias Gibbering.Data.{Races, Classes, Spells}

# ---------------------------------------------------------------------------
# Catalogue tables (idempotent — skip if already present)
# ---------------------------------------------------------------------------

now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

Enum.each(Races.seed_data(), fn {key, attrs} ->
  unless Repo.get(Race, key) do
    Repo.insert!(%Race{
      key: key,
      name: attrs.name,
      description: attrs.description,
      speed: attrs.speed,
      stat_bonuses: attrs.stat_bonuses,
      traits: Enum.map(attrs.traits, &Map.new(&1, fn {k, v} -> {to_string(k), v} end)),
      darkvision: attrs.darkvision,
      inserted_at: now,
      updated_at: now
    })
  end
end)

Enum.each(Classes.seed_data(), fn {key, attrs} ->
  unless Repo.get(Class, key) do
    Repo.insert!(%Class{
      key: key,
      name: attrs.name,
      description: attrs.description,
      hit_die: attrs.hit_die,
      base_hp: attrs.base_hp,
      primary_stats: attrs.primary_stats,
      saving_throws: attrs.saving_throws,
      armor_proficiencies: attrs.armor_proficiencies,
      weapon_proficiencies: attrs.weapon_proficiencies,
      spellcasting: attrs.spellcasting,
      spells: attrs.spells,
      features: Enum.map(attrs.features, &Map.new(&1, fn {k, v} -> {to_string(k), v} end)),
      stats: attrs.stats,
      inserted_at: now,
      updated_at: now
    })
  end
end)

Enum.each(Spells.seed_data(), fn {key, attrs} ->
  unless Repo.get(Spell, key) do
    Repo.insert!(%Spell{
      key: key,
      name: attrs.name,
      level: attrs.level,
      school: attrs.school,
      casting_time: attrs.casting_time,
      range: attrs.range,
      description: attrs.description,
      damage_dice: attrs.damage_dice,
      damage_type: attrs.damage_type,
      attack_type: attrs.attack_type,
      save: attrs.save,
      tags: attrs.tags,
      inserted_at: now,
      updated_at: now
    })
  end
end)

IO.puts(
  "Seeded catalogue: #{map_size(Races.seed_data())} races, #{map_size(Classes.seed_data())} classes, #{map_size(Spells.seed_data())} spells"
)

# Wipe existing seed data
Repo.delete_all(CampaignMember)
Repo.delete_all(Entity)
Repo.delete_all(GridTile)
Repo.delete_all(Campaign)

# Seed users (idempotent — skip if username exists)
{:ok, dm_user} =
  case Accounts.get_user_by_username("dungeon_master") do
    nil ->
      Accounts.register_user(%{username: "dungeon_master", password: "gibbering"})

    existing ->
      {:ok, existing}
  end

{:ok, player1} =
  case Accounts.get_user_by_username("aldric_player") do
    nil ->
      Accounts.register_user(%{username: "aldric_player", password: "gibbering"})

    existing ->
      {:ok, existing}
  end

{:ok, player2} =
  case Accounts.get_user_by_username("sylvara_player") do
    nil ->
      Accounts.register_user(%{username: "sylvara_player", password: "gibbering"})

    existing ->
      {:ok, existing}
  end

{:ok, player3} =
  case Accounts.get_user_by_username("zippik_player") do
    nil ->
      Accounts.register_user(%{username: "zippik_player", password: "gibbering"})

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

# Human Fighter — L3, CR n/a
Repo.insert!(%Entity{
  name: "Aldric",
  type: "hero",
  sprite: "human_fighter",
  race: "human",
  class: "fighter",
  x: 2,
  y: 5,
  hp: 28,
  max_hp: 28,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "strength" => 17,
    "dexterity" => 13,
    "constitution" => 15,
    "intelligence" => 9,
    "wisdom" => 11,
    "charisma" => 9,
    "equipped_weapon" => %{
      "key" => "longsword",
      "damage_dice" => "1d8",
      "damage_type" => "slashing",
      "attack_ability" => "strength",
      "properties" => ["versatile"]
    },
    "equipped_armor" => %{
      "key" => "chain_mail",
      "base_ac" => 16,
      "armor_category" => "heavy",
      "stealth_disadvantage" => true
    }
  },
  campaign_id: campaign.id
})

# Elf Wizard — L3, CR n/a
Repo.insert!(%Entity{
  name: "Sylvara",
  type: "hero",
  sprite: "elf_wizard",
  race: "elf",
  class: "wizard",
  x: 2,
  y: 7,
  hp: 18,
  max_hp: 18,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "strength" => 8,
    "dexterity" => 14,
    "constitution" => 13,
    "intelligence" => 20,
    "wisdom" => 15,
    "charisma" => 10,
    "spells" => ["fire_bolt", "mage_hand", "magic_missile", "sleep"],
    "equipped_weapon" => %{
      "key" => "quarterstaff",
      "damage_dice" => "1d6",
      "damage_type" => "bludgeoning",
      "attack_ability" => "strength",
      "properties" => ["versatile"]
    },
    "equipped_armor" => %{
      "key" => "no_armor",
      "base_ac" => nil,
      "armor_category" => "none",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign.id
})

# Gnome Rogue — L3, CR n/a
Repo.insert!(%Entity{
  name: "Zippik",
  type: "hero",
  sprite: "gnome_rogue",
  race: "gnome",
  class: "rogue",
  x: 3,
  y: 6,
  hp: 22,
  max_hp: 22,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 25,
    "strength" => 10,
    "dexterity" => 18,
    "constitution" => 13,
    "intelligence" => 16,
    "wisdom" => 12,
    "charisma" => 12,
    "equipped_weapon" => %{
      "key" => "shortsword",
      "damage_dice" => "1d6",
      "damage_type" => "piercing",
      "attack_ability" => "dexterity",
      "properties" => ["finesse", "light"]
    },
    "equipped_armor" => %{
      "key" => "leather_armor",
      "base_ac" => 11,
      "armor_category" => "light",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign.id
})

# Goblin — CR 1/4, 50 XP
Repo.insert!(%Entity{
  name: "Snaggle",
  type: "monster",
  sprite: "goblin",
  x: 7,
  y: 4,
  hp: 7,
  max_hp: 7,
  level: 1,
  challenge_rating: Decimal.new("0.25"),
  xp_reward: 50,
  tags: [],
  stats: %{
    "speed" => 30,
    "strength" => 8,
    "dexterity" => 14,
    "constitution" => 10,
    "intelligence" => 10,
    "wisdom" => 8,
    "charisma" => 8,
    "equipped_weapon" => %{
      "key" => "scimitar",
      "damage_dice" => "1d6",
      "damage_type" => "slashing",
      "attack_ability" => "dexterity",
      "properties" => ["finesse", "light"]
    },
    "equipped_armor" => %{
      "key" => "leather_armor",
      "base_ac" => 11,
      "armor_category" => "light",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign.id
})

# The Rock — object, no CR
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

# Admin support user — dev credentials: admin@gibbering.local / gibbering_admin
unless Repo.get_by(Gibbering.Admin.SupportUser, email: "admin@gibbering.local") do
  {:ok, _} =
    Admin.create_support_user(%{
      email: "admin@gibbering.local",
      password: "gibbering_admin",
      role: "admin"
    })

  IO.puts("Seeded support user: admin@gibbering.local (admin) — password: gibbering_admin")
end
