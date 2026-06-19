alias Gibbering.{Repo, Campaign, GameMap, GridTile, Entity, CampaignMember}
alias Gibbering.{Character, CampaignCharacter, CampaignInvitation, CampaignInviteLink}
alias Gibbering.Engine.GameSession
alias Gibbering.Accounts
alias Gibbering.Accounts.User
alias Gibbering.Admin
alias Gibbering.Catalogue.{Race, Class, Spell, Monster, Style, Appearance}
alias Gibbering.Data.{Races, Classes, Spells, Monsters}
alias Gibbering.Rulesets.DnD5e.Inventory

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

Enum.each(Monsters.seed_data(), fn {key, attrs} ->
  unless Repo.get(Monster, key) do
    Repo.insert!(%Monster{
      key: key,
      name: attrs.name,
      size: attrs.size,
      monster_type: attrs.monster_type,
      alignment: attrs.alignment,
      armor_class: attrs.armor_class,
      hit_points: attrs.hit_points,
      hit_dice: attrs.hit_dice,
      speed: attrs.speed,
      strength: attrs.strength,
      dexterity: attrs.dexterity,
      constitution: attrs.constitution,
      intelligence: attrs.intelligence,
      wisdom: attrs.wisdom,
      charisma: attrs.charisma,
      challenge_rating: attrs.challenge_rating,
      xp_reward: attrs.xp_reward,
      source_license: attrs.source_license,
      stat_block: attrs.stat_block,
      inserted_at: now,
      updated_at: now
    })
  end
end)

IO.puts(
  "Seeded catalogue: #{map_size(Races.seed_data())} races, #{map_size(Classes.seed_data())} classes, #{map_size(Spells.seed_data())} spells, #{map_size(Monsters.seed_data())} monsters"
)

# ---------------------------------------------------------------------------
# Full wipe of all user-generated data (campaigns, characters, users).
# Safe to re-run; support users and catalogue data are preserved.
# ---------------------------------------------------------------------------

Repo.delete_all(CampaignInviteLink)
Repo.delete_all(CampaignInvitation)
Repo.delete_all(CampaignCharacter)
Repo.delete_all(CampaignMember)
Repo.delete_all(GameSession)
Repo.delete_all(Entity)
Repo.delete_all(GridTile)
Repo.update_all(Campaign, set: [active_map_id: nil])
Repo.delete_all(GameMap)
Repo.delete_all(Campaign)
Repo.delete_all(Character)
Repo.delete_all(User)

# ---------------------------------------------------------------------------
# Users  (all password: "gibbering")
# ---------------------------------------------------------------------------

{:ok, dm} = Accounts.register_user(%{username: "dungeon_master", password: "gibbering"})
{:ok, alice} = Accounts.register_user(%{username: "alice", password: "gibbering"})
{:ok, bob} = Accounts.register_user(%{username: "bob", password: "gibbering"})
{:ok, charlie} = Accounts.register_user(%{username: "charlie", password: "gibbering"})

# ---------------------------------------------------------------------------
# Campaign 1: Ambush at Duskwood Crossing  (DM + 3 players)
# ---------------------------------------------------------------------------
# 16x16 forest clearing. Three travelers ambushed on a woodland road by a
# bugbear warlord, two bandits, and a trained wolf. Saddlebag loot from
# the abandoned wagon sits mid-road.
# ---------------------------------------------------------------------------

campaign1 =
  Repo.insert!(%Campaign{
    name: "Ambush at Duskwood Crossing",
    dm_id: dm.id
  })

for user <- [dm, alice, bob, charlie] do
  Repo.insert!(%CampaignMember{campaign_id: campaign1.id, user_id: user.id})
end

map1 =
  Repo.insert!(%GameMap{campaign_id: campaign1.id, x_extent: 16, y_extent: 16, tile_size: 56})

Repo.update!(Campaign.changeset(campaign1, %{active_map_id: map1.id}))

# Stone border + scattered interior tree clumps + north/south forest screens.
# Road runs east-west through y=7–8; parties enter from the west.
border1 =
  for(x <- 0..15, do: {x, 0}) ++
    for(x <- 0..15, do: {x, 15}) ++
    for(y <- 1..14, do: {0, y}) ++
    for(y <- 1..14, do: {15, y})

interior_trees1 = [
  # NW clump
  {2, 2},
  {3, 2},
  {2, 3},
  # NE clump
  {12, 2},
  {13, 2},
  {13, 3},
  # SW clump
  {2, 12},
  {2, 13},
  {3, 13},
  # SE clump
  {12, 12},
  {13, 12},
  {12, 13},
  # North forest screen (blocks line of sight across the clearing)
  {6, 3},
  {7, 3},
  # South forest screen
  {7, 12},
  {8, 12},
  # Western flank cover trees
  {4, 5},
  {4, 10},
  # Eastern flank cover trees
  {11, 5},
  {11, 10}
]

stone1 = MapSet.new(border1 ++ interior_trees1)

decorations1 = %{
  {3, 3} => "grass_tuft",
  {4, 3} => "grass_tuft",
  {12, 3} => "grass_tuft",
  {3, 12} => "grass_tuft",
  {13, 11} => "grass_tuft",
  {1, 7} => "grass_tuft",
  {1, 8} => "grass_tuft",
  {14, 7} => "grass_tuft",
  # Cover rocks flanking the road
  {5, 5} => "rock_cluster",
  {10, 5} => "rock_cluster",
  {5, 10} => "rock_cluster",
  {10, 10} => "rock_cluster",
  # Debris on and near the road
  {7, 7} => "bones",
  {9, 8} => "bones",
  {6, 8} => "grass_tuft"
}

tiles1 =
  for x <- 0..15, y <- 0..15 do
    texture = if {x, y} in stone1, do: "stone", else: "grass"
    decoration = if texture == "grass", do: Map.get(decorations1, {x, y}), else: nil

    %{
      x: x,
      y: y,
      texture: texture,
      movement: if(texture == "grass", do: %{"walk" => 100, "fly" => 100}, else: %{}),
      decoration: decoration,
      map_id: map1.id
    }
  end

Repo.insert_all(GridTile, tiles1)

# ── Heroes ──────────────────────────────────────────────────────────────────

# Human Cleric — L3, divine support
Repo.insert!(%Entity{
  name: "Mirela",
  type: "hero",
  sprite: "human_wizard",
  race: "human",
  class: "cleric",
  x: 2,
  y: 7,
  hp: 22,
  max_hp: 22,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 12,
    "dexterity" => 10,
    "constitution" => 13,
    "intelligence" => 11,
    "wisdom" => 18,
    "charisma" => 14,
    "spells" => ["fire_bolt", "mage_hand", "magic_missile", "sleep"],
    "inventory" => [],
    "equipped_weapon" => %{
      "key" => "quarterstaff",
      "damage_dice" => "1d6",
      "damage_type" => "bludgeoning",
      "attack_ability" => "strength",
      "properties" => ["versatile"]
    },
    "equipped_armor" => %{
      "key" => "chain_shirt",
      "base_ac" => 13,
      "armor_category" => "medium",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign1.id
})

# Half-orc Barbarian — L3, melee frontline
Repo.insert!(%Entity{
  name: "Thrax",
  type: "hero",
  sprite: "half_orc_barbarian",
  race: "half_orc",
  class: "barbarian",
  x: 2,
  y: 6,
  hp: 34,
  max_hp: 34,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 18,
    "dexterity" => 13,
    "constitution" => 16,
    "intelligence" => 8,
    "wisdom" => 11,
    "charisma" => 9,
    "inventory" => [],
    "equipped_weapon" => %{
      "key" => "battleaxe",
      "damage_dice" => "1d8",
      "damage_type" => "slashing",
      "attack_ability" => "strength",
      "properties" => ["versatile"]
    },
    "equipped_armor" => %{
      "key" => "scale_mail",
      "base_ac" => 14,
      "armor_category" => "medium",
      "stealth_disadvantage" => true
    }
  },
  campaign_id: campaign1.id
})

# Halfling Rogue — L3, skirmisher
Repo.insert!(%Entity{
  name: "Sable",
  type: "hero",
  sprite: "halfling_rogue",
  race: "halfling",
  class: "rogue",
  x: 3,
  y: 8,
  hp: 21,
  max_hp: 21,
  level: 3,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 25,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 9,
    "dexterity" => 18,
    "constitution" => 12,
    "intelligence" => 14,
    "wisdom" => 13,
    "charisma" => 11,
    "inventory" => [],
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
  campaign_id: campaign1.id
})

# ── Monsters ────────────────────────────────────────────────────────────────

# Bandit "Morra" — north road ambush position
Repo.insert!(%Entity{
  name: "Morra",
  type: "monster",
  sprite: "bandit",
  race: "human",
  x: 10,
  y: 6,
  hp: 11,
  max_hp: 11,
  level: 1,
  challenge_rating: Decimal.new("0.125"),
  xp_reward: 25,
  tags: [],
  stats: %{
    "monster_type" => "Humanoid",
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 11,
    "dexterity" => 12,
    "constitution" => 12,
    "intelligence" => 10,
    "wisdom" => 10,
    "charisma" => 10,
    "inventory" => [],
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
  campaign_id: campaign1.id
})

# Bandit "Keld" — south road ambush position
Repo.insert!(%Entity{
  name: "Keld",
  type: "monster",
  sprite: "bandit",
  race: "human",
  x: 10,
  y: 9,
  hp: 11,
  max_hp: 11,
  level: 1,
  challenge_rating: Decimal.new("0.125"),
  xp_reward: 25,
  tags: [],
  stats: %{
    "monster_type" => "Humanoid",
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 11,
    "dexterity" => 12,
    "constitution" => 12,
    "intelligence" => 10,
    "wisdom" => 10,
    "charisma" => 10,
    "inventory" => [],
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
  campaign_id: campaign1.id
})

# Wolf "Fang" — hunting alongside the bandits
Repo.insert!(%Entity{
  name: "Fang",
  type: "monster",
  sprite: "wolf",
  race: "beast",
  x: 12,
  y: 8,
  hp: 11,
  max_hp: 11,
  level: 1,
  challenge_rating: Decimal.new("0.25"),
  xp_reward: 50,
  tags: [],
  stats: %{
    "monster_type" => "Beast",
    "speed" => 40,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 12,
    "dexterity" => 15,
    "constitution" => 12,
    "intelligence" => 3,
    "wisdom" => 12,
    "charisma" => 6,
    "inventory" => [],
    "equipped_weapon" => %{
      "key" => "dagger",
      "damage_dice" => "1d4",
      "damage_type" => "piercing",
      "attack_ability" => "dexterity",
      "properties" => ["finesse", "light", "thrown"]
    },
    "equipped_armor" => %{
      "key" => "no_armor",
      "base_ac" => nil,
      "armor_category" => "none",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign1.id
})

# Bugbear "Grak" — ambush warlord, far eastern edge
Repo.insert!(%Entity{
  name: "Grak",
  type: "monster",
  sprite: "bugbear",
  race: "goblinoid",
  x: 13,
  y: 7,
  hp: 27,
  max_hp: 27,
  temp_hp: 5,
  level: 1,
  challenge_rating: Decimal.new("1"),
  xp_reward: 200,
  tags: [],
  stats: %{
    "monster_type" => "Humanoid",
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 15,
    "dexterity" => 14,
    "constitution" => 13,
    "intelligence" => 8,
    "wisdom" => 11,
    "charisma" => 9,
    "inventory" => [],
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
  campaign_id: campaign1.id
})

# ── Objects ─────────────────────────────────────────────────────────────────

# Overturned Wagon — impassable wreckage blocking the road
Repo.insert!(%Entity{
  name: "Overturned Wagon",
  type: "object",
  sprite: "rock",
  x: 8,
  y: 7,
  hp: 10,
  max_hp: 10,
  tags: ["blocking"],
  stats: %{"object_subtype" => "static_decor"},
  campaign_id: campaign1.id
})

# Saddlebag — loot spilled from the wagon
Repo.insert!(%Entity{
  name: "Saddlebag",
  type: "object",
  sprite: "chest",
  x: 8,
  y: 8,
  hp: 3,
  max_hp: 3,
  tags: ["interactable", "blocking"],
  stats: %{
    "object_subtype" => "loot_source",
    "items" => [
      Inventory.item_instance("healing_potion", 2),
      Inventory.item_instance("rapier", 1)
    ]
  },
  campaign_id: campaign1.id
})

# ---------------------------------------------------------------------------
# Campaign 2: The Sunken Crypt  (DM solo — dungeon master runs all heroes)
# ---------------------------------------------------------------------------
# 12x12 stone dungeon. Two chambers separated by a center divider wall with
# a three-tile corridor (y=5–7). Heroes start in the west chamber; two
# skeletons and a zombie guard the east. Burial urn holds deeper loot.
# ---------------------------------------------------------------------------

campaign2 =
  Repo.insert!(%Campaign{
    name: "The Sunken Crypt",
    dm_id: dm.id
  })

Repo.insert!(%CampaignMember{campaign_id: campaign2.id, user_id: dm.id})

map2 =
  Repo.insert!(%GameMap{campaign_id: campaign2.id, x_extent: 12, y_extent: 12, tile_size: 56})

Repo.update!(Campaign.changeset(campaign2, %{active_map_id: map2.id}))

# Stone border + center divider at x=5 (open corridor at y=5,6,7).
# Stone pillars in each chamber for tactical cover.
border2 =
  for(x <- 0..11, do: {x, 0}) ++
    for(x <- 0..11, do: {x, 11}) ++
    for(y <- 1..10, do: {0, y}) ++
    for(y <- 1..10, do: {11, y})

divider2 = for(y <- 1..4, do: {5, y}) ++ for(y <- 8..10, do: {5, y})

stone2 =
  MapSet.new(
    # Pillars in west chamber
    # Pillars in east chamber
    border2 ++
      divider2 ++
      [{2, 2}, {2, 8}] ++
      [{8, 2}, {8, 8}]
  )

decorations2 = %{
  {3, 5} => "bones",
  {6, 5} => "bones",
  {6, 6} => "bones",
  {3, 7} => "rock_cluster",
  {9, 3} => "rock_cluster",
  {9, 8} => "rock_cluster"
}

tiles2 =
  for x <- 0..11, y <- 0..11 do
    texture = if {x, y} in stone2, do: "stone", else: "grass"
    decoration = if texture == "grass", do: Map.get(decorations2, {x, y}), else: nil

    %{
      x: x,
      y: y,
      texture: texture,
      movement: if(texture == "grass", do: %{"walk" => 100, "fly" => 100}, else: %{}),
      decoration: decoration,
      map_id: map2.id
    }
  end

Repo.insert_all(GridTile, tiles2)

# ── Heroes ──────────────────────────────────────────────────────────────────

# Dragonborn Paladin — L2, armored frontline
Repo.insert!(%Entity{
  name: "Kaelthas",
  type: "hero",
  sprite: "dragonborn_paladin",
  race: "dragonborn",
  class: "paladin",
  x: 2,
  y: 5,
  hp: 22,
  max_hp: 22,
  level: 2,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 16,
    "dexterity" => 10,
    "constitution" => 14,
    "intelligence" => 8,
    "wisdom" => 12,
    "charisma" => 14,
    "inventory" => [],
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
  campaign_id: campaign2.id
})

# Tiefling Warlock — L2, arcane striker
Repo.insert!(%Entity{
  name: "Vex",
  type: "hero",
  sprite: "tiefling_warlock",
  race: "tiefling",
  class: "warlock",
  x: 2,
  y: 6,
  hp: 14,
  max_hp: 14,
  level: 2,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 8,
    "dexterity" => 14,
    "constitution" => 12,
    "intelligence" => 13,
    "wisdom" => 10,
    "charisma" => 18,
    "spells" => ["fire_bolt", "mage_hand"],
    "inventory" => [],
    "equipped_weapon" => %{
      "key" => "dagger",
      "damage_dice" => "1d4",
      "damage_type" => "piercing",
      "attack_ability" => "dexterity",
      "properties" => ["finesse", "light", "thrown"]
    },
    "equipped_armor" => %{
      "key" => "leather_armor",
      "base_ac" => 11,
      "armor_category" => "light",
      "stealth_disadvantage" => false
    }
  },
  campaign_id: campaign2.id
})

# Dwarf Cleric — L2, healing anchor
Repo.insert!(%Entity{
  name: "Boldar",
  type: "hero",
  sprite: "dwarf_cleric",
  race: "dwarf",
  class: "cleric",
  x: 3,
  y: 5,
  hp: 18,
  max_hp: 18,
  level: 2,
  tags: ["player_controlled"],
  stats: %{
    "speed" => 25,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 14,
    "dexterity" => 10,
    "constitution" => 16,
    "intelligence" => 11,
    "wisdom" => 17,
    "charisma" => 11,
    "spells" => ["fire_bolt", "mage_hand", "magic_missile"],
    "inventory" => [],
    "equipped_weapon" => %{
      "key" => "quarterstaff",
      "damage_dice" => "1d6",
      "damage_type" => "bludgeoning",
      "attack_ability" => "strength",
      "properties" => ["versatile"]
    },
    "equipped_armor" => %{
      "key" => "scale_mail",
      "base_ac" => 14,
      "armor_category" => "medium",
      "stealth_disadvantage" => true
    }
  },
  campaign_id: campaign2.id
})

# ── Monsters ────────────────────────────────────────────────────────────────

# Skeleton "Bonewalker" — north of east chamber
Repo.insert!(%Entity{
  name: "Bonewalker",
  type: "monster",
  sprite: "skeleton",
  race: "undead",
  x: 7,
  y: 4,
  hp: 13,
  max_hp: 13,
  level: 1,
  challenge_rating: Decimal.new("0.25"),
  xp_reward: 50,
  tags: [],
  stats: %{
    "monster_type" => "Undead",
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 10,
    "dexterity" => 14,
    "constitution" => 15,
    "intelligence" => 6,
    "wisdom" => 8,
    "charisma" => 5,
    "inventory" => [],
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
  campaign_id: campaign2.id
})

# Skeleton "Dustbone" — south of east chamber
Repo.insert!(%Entity{
  name: "Dustbone",
  type: "monster",
  sprite: "skeleton",
  race: "undead",
  x: 7,
  y: 7,
  hp: 13,
  max_hp: 13,
  level: 1,
  challenge_rating: Decimal.new("0.25"),
  xp_reward: 50,
  tags: [],
  stats: %{
    "monster_type" => "Undead",
    "speed" => 30,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 10,
    "dexterity" => 14,
    "constitution" => 15,
    "intelligence" => 6,
    "wisdom" => 8,
    "charisma" => 5,
    "inventory" => [],
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
  campaign_id: campaign2.id
})

# Zombie "Groaner" — center of east chamber
Repo.insert!(%Entity{
  name: "Groaner",
  type: "monster",
  sprite: "zombie",
  race: "undead",
  x: 8,
  y: 5,
  hp: 22,
  max_hp: 22,
  level: 1,
  challenge_rating: Decimal.new("0.25"),
  xp_reward: 50,
  tags: [],
  stats: %{
    "monster_type" => "Undead",
    "speed" => 20,
    "climb_speed" => nil,
    "swim_speed" => nil,
    "fly_speed" => nil,
    "strength" => 13,
    "dexterity" => 6,
    "constitution" => 16,
    "intelligence" => 3,
    "wisdom" => 6,
    "charisma" => 5,
    "inventory" => [],
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
  campaign_id: campaign2.id
})

# ── Objects ─────────────────────────────────────────────────────────────────

# Stone Coffin — impassable sarcophagus in the east chamber
Repo.insert!(%Entity{
  name: "Stone Coffin",
  type: "object",
  sprite: "rock",
  x: 9,
  y: 2,
  hp: 20,
  max_hp: 20,
  tags: ["blocking"],
  stats: %{"object_subtype" => "static_decor"},
  campaign_id: campaign2.id
})

# Burial Urn — loot container in the east chamber
Repo.insert!(%Entity{
  name: "Burial Urn",
  type: "object",
  sprite: "chest",
  x: 9,
  y: 9,
  hp: 4,
  max_hp: 4,
  tags: ["interactable", "blocking"],
  stats: %{
    "object_subtype" => "loot_source",
    "items" => [
      Inventory.item_instance("healing_potion", 1),
      Inventory.item_instance("greater_healing_potion", 1)
    ]
  },
  campaign_id: campaign2.id
})

IO.puts("""

── Dev seed complete ─────────────────────────────────────────────────────────
Campaign 1: #{campaign1.name} (##{campaign1.id})
  Game:   http://localhost:4000/game/#{campaign1.id}
  Lobby:  http://localhost:4000/lobby/#{campaign1.id}

Campaign 2: #{campaign2.name} (##{campaign2.id}) — DM solo
  Game:   http://localhost:4000/game/#{campaign2.id}
  Lobby:  http://localhost:4000/lobby/#{campaign2.id}

Users (all password: gibbering)
  dungeon_master  — DM on both campaigns; plays all heroes in The Sunken Crypt
  alice, bob, charlie  — players on Duskwood Crossing
─────────────────────────────────────────────────────────────────────────────
""")

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

# ---------------------------------------------------------------------------
# Styles + appearances (idempotent — skip if DST style already present)
# ---------------------------------------------------------------------------

unless Repo.get_by(Style, slug: "dst") do
  {:ok, dst} =
    Repo.insert(%Style{
      slug: "dst",
      name: "Don't Starve Together",
      description:
        "Muted dark palette, thick near-black outlines, gothic/whimsical ink aesthetic.",
      inserted_at: now,
      updated_at: now
    })

  tile_appearances = [
    {"grass", %{"fill" => "#3d6b45", "stroke" => "#2a4d30"}},
    {"stone", %{"fill" => "#555555", "stroke" => "#383838"}},
    {"rubble", %{"fill" => "#7a6248", "stroke" => "#4d3d2c"}}
  ]

  entity_appearances = [
    # Legacy generic sprites
    {"warrior", %{"body_color" => "#4a6fa5"}},
    {"wizard", %{"body_color" => "#7b5ea7"}},
    {"rock", %{"body_color" => "#787878"}},
    # Human sprites
    {"human_fighter", %{"body_color" => "#4a6fa5"}},
    {"human_wizard", %{"body_color" => "#7b5ea7"}},
    {"human_rogue", %{"body_color" => "#6b4c38"}},
    # Elf sprites
    {"elf_fighter", %{"body_color" => "#5a8f6a"}},
    {"elf_wizard", %{"body_color" => "#7b5ea7"}},
    {"elf_rogue", %{"body_color" => "#4a7060"}},
    # Gnome sprites
    {"gnome_fighter", %{"body_color" => "#8b4513"}},
    {"gnome_wizard", %{"body_color" => "#9b59b6"}},
    {"gnome_rogue", %{"body_color" => "#5d4037"}},
    # Dwarf sprites (fallback rect — named sprite pending)
    {"dwarf_fighter", %{"body_color" => "#7a5c2a"}},
    {"dwarf_cleric", %{"body_color" => "#c0a060"}},
    {"dwarf_rogue", %{"body_color" => "#5a4020"}},
    # Half-elf sprites
    {"half_elf_fighter", %{"body_color" => "#5a7a60"}},
    {"half_elf_wizard", %{"body_color" => "#7060a0"}},
    {"half_elf_rogue", %{"body_color" => "#486050"}},
    # Halfling sprites
    {"halfling_fighter", %{"body_color" => "#c08040"}},
    {"halfling_rogue", %{"body_color" => "#a06030"}},
    # Tiefling sprites
    {"tiefling_warlock", %{"body_color" => "#8b2040"}},
    {"tiefling_sorcerer", %{"body_color" => "#a03050"}},
    # Dragonborn sprites
    {"dragonborn_fighter", %{"body_color" => "#2a7060"}},
    {"dragonborn_paladin", %{"body_color" => "#206858"}},
    # Half-orc sprites
    {"half_orc_barbarian", %{"body_color" => "#4a7830"}},
    {"half_orc_fighter", %{"body_color" => "#3a6020"}},
    # Monster sprites (fallback rects — named SVGs pending)
    {"goblin", %{"body_color" => "#5a7a30"}},
    {"skeleton", %{"body_color" => "#d8d0b0"}},
    {"zombie", %{"body_color" => "#5a6a3a"}},
    {"kobold", %{"body_color" => "#8b3a1a"}},
    {"bandit", %{"body_color" => "#6b5540"}},
    {"cultist", %{"body_color" => "#4a2060"}},
    {"guard", %{"body_color" => "#607890"}},
    {"wolf", %{"body_color" => "#706050"}},
    {"orc", %{"body_color" => "#3a6030"}},
    {"bugbear", %{"body_color" => "#5a5030"}},
    {"ogre", %{"body_color" => "#7a6040"}},
    {"troll", %{"body_color" => "#3a6838"}}
  ]

  for {key, data} <- tile_appearances do
    Repo.insert!(%Appearance{
      style_id: dst.id,
      content_type: "tile",
      content_key: key,
      data: data,
      inserted_at: now,
      updated_at: now
    })
  end

  for {key, data} <- entity_appearances do
    Repo.insert!(%Appearance{
      style_id: dst.id,
      content_type: "entity",
      content_key: key,
      data: data,
      inserted_at: now,
      updated_at: now
    })
  end

  IO.puts(
    "Seeded DST style with #{length(tile_appearances)} tile and #{length(entity_appearances)} entity appearances"
  )
end
