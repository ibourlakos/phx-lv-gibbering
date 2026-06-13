alias Gibbering.{Repo, Campaign, GameMap, GridTile, Entity, CampaignMember}
alias Gibbering.{Character, CampaignCharacter, CampaignInvitation, CampaignInviteLink}
alias Gibbering.Engine.GameSession
alias Gibbering.Accounts
alias Gibbering.Accounts.User
alias Gibbering.Admin
alias Gibbering.Catalogue.{Race, Class, Spell, Monster, Style, Appearance}
alias Gibbering.Data.{Races, Classes, Spells, Monsters}

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
# Campaign: The Proving Grounds  (DM = dungeon_master)
# ---------------------------------------------------------------------------

campaign =
  Repo.insert!(%Campaign{
    name: "The Proving Grounds",
    dm_id: dm.id
  })

for user <- [dm, alice, bob, charlie] do
  Repo.insert!(%CampaignMember{campaign_id: campaign.id, user_id: user.id})
end

map = Repo.insert!(%GameMap{campaign_id: campaign.id, x_extent: 10, y_extent: 10, tile_size: 56})
Repo.update!(Campaign.changeset(campaign, %{active_map_id: map.id}))

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
      map_id: map.id
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

IO.puts("""

── Dev seed complete ─────────────────────────────────────────────────────────
Campaign: #{campaign.name} (##{campaign.id})
  Game:   http://localhost:4000/game/#{campaign.id}
  Lobby:  http://localhost:4000/lobby/#{campaign.id}

Users (all password: gibbering)
  dungeon_master  — DM of The Proving Grounds
  alice           — player
  bob             — player
  charlie         — player
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
