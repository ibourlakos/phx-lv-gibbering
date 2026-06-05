To build a truly functional D&D 5th Edition rules engine, we have to look past the surface-level text of the books and map out the underlying mathematical dependencies. D&D 5e is essentially a system of **actors, resources, actions, and modifiers** that continuously alter each other's state.

Below is a detailed semantic map, organized by core domains, mapping out the precise entities, their internal properties, and the directional edges (relationships) that the **Gibbering Engine** will need to parse.

---

## 1. The Core Actor Graph (The Entity Blueprint)

Every character (PC) or monster (NPC) on your SVG grid is an **Actor**. Their final runtime values are calculated by traversing relationships down to their base origins.

```
[ Race ] ──( Grants )──> [ Traits ] ──( Modifies )──> [ Core Attributes ]
                                                               ▲
[ Class ] ──( Dictates )──> [ Proficiencies ] ──( Scaling )────┤
                                                               ▼
[ Actor State ] ◄──( Evaluates )── [ Equipment / Inventory ] ──┘

```

### Player Characters (PC) Nodes

* **Properties:** `Level`, `Current_XP`, `Current_HP`, `Max_HP`, `Temporary_HP`, `Death_Saves_Success/Failure`.
* **Edges:**
* `HAS_RACE` ➔ Points to a **Race Node** (e.g., Mountain Dwarf).
* `HAS_CLASS` ➔ Points to one or more **Class Nodes** (handles multi-classing).
* `EQUIPPED` ➔ Points to **Item Nodes** currently occupying an equipment slot.
* `KNOWS` ➔ Points to **Action/Spell Nodes**.



### Class & Race Definition Nodes (Static Blueprints)

* **Class Properties:** `Hit_Die_Type` (e.g., d10), `Saving_Throw_Proficiencies`, `Spellcasting_Ability_Modifier` (e.g., Wisdom for Clerics).
* **Race Properties:** `Base_Speed` (e.g., 30ft), `Size_Category` (e.g., Medium).
* **Shared Edges:**
* `GRANTS_FEATURE` ➔ Points to a **Feature/Trait Node** unlocked at a specific level.
* `GRANTS_PROFICIENCY` ➔ Points to a Skill or Tool node.



---

## 2. The Modifiers & Pipeline Interrupt Graph

This is where the semantic map becomes highly functional for a software developer. When an event occurs (like an attack or a saving throw), the engine must traverse these nodes to find active modifiers before executing the final math.

### Feature / Trait Nodes (The Rule Changers)

Features are passive rules that alter core mechanics.

* **Properties:** `Trigger_Condition` (e.g., `On_Short_Rest`, `When_Attacking_With_Finesse`), `Effect_Type` (e.g., `Add_Dice`, `Grant_Advantage`, `Damage_Resistance`).
* **Example Edge Mapping:** * `Barbarian_Class` ──`GRANTS`──> `Rage_Feature`
* `Rage_Feature` ──`MODIFIES`──> `Actor.Damage_Resistance` (Target: Bludgeoning, Piercing, Slashing)
* `Rage_Feature` ──`MODIFIES`──> `Actor.Attack_Rolls` (Condition: Melee Strength attacks get +2 damage)



### Condition / Status Effect Nodes (The Temporary Shifting State)

Conditions are volatile nodes attached directly to an Actor during combat.

* **Properties:** `Exclusion_Rules` (What it blocks), `Stat_Penalties`.
* **Example Edge Mapping:**
* `Spell_Ghoul_Touch` ──`INFLICTS`──> `Condition_Paralyzed`
* `Condition_Paralyzed` ──`MODIFIES`──> `Actor.Condition_Incapacitated` (Implicit inclusion)
* `Condition_Paralyzed` ──`MODIFIES`──> `Actor.Speed` (Sets speed to 0)
* `Condition_Paralyzed` ──`MODIFIES`──> `Incoming_Attacks` (Grants Auto-Crit if attacker is within 5ft)



---

## 3. The Action & Combat Resolver Graph

When a user triggers an action from the **Gibbering Engine** front-end, it generates an Action Resolution Node. This node evaluates a multi-step sequence across the semantic tree.

```
[ Active Actor ] ──( Triggers )──> [ Action Node ]
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 ▼                                               ▼
      [ Type: Weapon Attack ]                          [ Type: Saving Throw ]
                 │                                               │
        Evaluates AC vs. Roll                            Evaluates DC vs. Target
                 │                                               │
                 └───────────────────────┬───────────────────────┘
                                         ▼
                               [ Target Actor State ]
                                         │
                                   Checks Edges:
                    [ Resistances? ] ── [ Immunities? ] ── [ Vulnerabilities? ]
                                         │
                                         ▼
                               [ Applies Final Damage / HP Diffs ]

```

### Action / Spell Nodes

* **Properties:** `Activation_Cost` (Action, Bonus Action, Reaction), `Range` (Tiles), `Target_Type` (Single Target, Self, AoE Shape), `Component_Cost` (Slots, Material).
* **Edges:**
* `REQUIRES_ROLL` ➔ Links to an **Attribute/Skill Node** (e.g., d20 + Strength Mod + Proficiency).
* `CHALLENGES` ➔ Links to a Target's **Saving Throw Modifier** (e.g., Fireball challenges Target's Dexterity Saving Throw).
* `INFLICTS_DAMAGE` ➔ Points to a Damage Template node (`Dice_Formula`, `Damage_Type`).
* `INFLICTS_CONDITION` ➔ Links to a **Condition Node**.



---

## 4. The Inventory & Item Sub-Graph

Items function identically to Features, but their edges are conditional on whether they are `Equipped` or `Consumed`.

### Item Nodes

* **Properties:** `Weight`, `Value`, `Is_Magical`, `Attunement_Required`.
* **Sub-Types & Unique Edges:**
* **Weapon:** `HAS_PROPERTY` ➔ Links to weapon traits (Finesse, Heavy, Reach—which dynamically extends the SVG action range pointer from 1 tile to 2 tiles).
* **Armor:** `OVERRIDES` ➔ Links to the Actor's Armor Class calculation loop (e.g., Plate Armor changes AC from `10 + DEX` to a flat `18`).
* **Consumable (Potion):** `EXECUTES` ➔ Triggers an instant, one-time Action Node (e.g., Potion of Healing inflicts `-2d4 - 2` damage type `Healing`).



---

## How the Gibbering Engine Evaluates This Graph

By treating your game as a semantic graph, you avoid nesting complex, nested conditional loops in your code. When a hero swings an axe at a monster, your core engine logic executes a clean pipeline:

1. **Fetch Actor State:** Gather the Hero node and all active connected edges (`Class`, `Rage`, `Equipped_Axe`).
2. **Compile Modifiers:** Query connected feature nodes matching the tag `on_attack`. The engine evaluates that `Rage` adds a `+2` bonus to the damage calculation.
3. **Fetch Target State:** Gather the Monster node and all active connected edges (`Condition_Paralyzed`, `Resistance_Bludgeoning`).
4. **Resolve Intersection:** The engine discovers the target has `Condition_Paralyzed`, which forces the incoming hit to step up to a critical hit if the SVG grid space distance between the actors is $\le 1$ tile.

This layout allows you to write a clean, standardized data contract. No matter how many strange rules WotC throws at you in the SRD, they all distill down into these precise node connections.

---


Let’s strip away the database layout and the network loops for a moment. To build the backbone of the **Gibbering Engine**, we need to map the clean, conceptual blueprints of the D&D 5e universe itself.

Think of this as the pure object-oriented domain model or a high-level taxonomy chart. It represents how entities exist in a vacuum based entirely on the official rules.

---

## 1. The Living Entity Hierarchy (The Actor Domain)

In D&D, everything that can take a turn, move across a tile, or lose hit points belongs to a shared lineage. Here is how the core classification tree branches out:

### **Creature** (The Abstract Root Class)

Every living thing on the map inherits from this root class.

* **Core Properties:** `current_hp`, `max_hp`, `temp_hp`, `armor_class`, `speed`, `size_category` (Tiny to Gargantuan), `alignment`, `position_x`, `position_y`.
* **The Six Attributes:** `strength`, `dexterity`, `constitution`, `intelligence`, `wisdom`, `charisma`.

#### └── **Character** (Extends Creature)

An individual entity with a distinct identity, backstory, and a fully formed sheet.

* **Additional Properties:** `name`, `languages`, `personality_traits`, `inventory_list`.

##### ├── **PlayableCharacter (PC)** (Extends Character)

The heroes controlled by your friends. This class is uniquely defined by progression, choice, and player resources.

* **Unique Properties:** `current_xp`, `hit_dice_pool` (e.g., 3d10 left), `death_save_successes`, `death_save_failures`, `inspiration_token`.
* **Core Composition:** Has a `Race` blueprint and a `Class` list (to allow multi-classing).

##### └── **NonPlayableCharacter (NPC)** (Extends Character)

The townspeople, shopkeepers, and quest-givers controlled by the DM.

* **Unique Properties:** `disposition` (Friendly/Neutral/Hostile), `faction_affiliation`.

#### └── **Monster** (Extends Creature)

The combat-ready threats designed to challenge the players. Unlike PCs, their capabilities don't scale dynamically via leveling; they are hard-coded into static snapshots.

* **Unique Properties:** `challenge_rating` (CR), `xp_reward_value`, `senses` (e.g., Truesight 60ft), `legendary_resistances_count`.

---

## 2. The Anatomy of a Spell (The Magic Domain)

Spells in D&D 5e are highly structured, self-contained rule payloads. Every spell is an instance of a master `Spell` class, defined by a strict set of properties that your engine will need to evaluate.

### **The Spell Class Structure**

* **`name`**: (String) e.g., `"Fireball"`
* **`level`**: (Integer, 0 to 9) 0 represents a Cantrip (unlimited casting).
* **`school`**: (Enum) Evocation, Abjuration, Conjuration, Divination, Enchantment, Illusion, Necromancy, Transmutation.
* **`casting_time`**: (Struct) Specifies the action resource required:
* `type`: (Enum) `:action`, `:bonus_action`, `:reaction`, `:minute`, `:hour`
* `value`: (Integer) e.g., 1 Action or 10 Minutes.


* **`range`**: (Struct) How far the spell can travel down the grid.
* `type`: (Enum) `:self`, `:touch`, `:ranged`, `:unlimited`
* `distance_feet`: (Integer) e.g., 120 (which the engine converts to 24 SVG tiles).


* **`components`**: (Map of Booleans) What is required to physically cast it.
* `verbal`: (Boolean) Requires speaking.
* `somatic`: (Boolean) Requires hand gestures.
* `material`: (Boolean) Requires physical items (and text description if it consumes a costly component).


* **`duration`**: (Struct) How long the effect lingers on the map.
* `is_concentration`: (Boolean) If true, taking damage forces a check to maintain the spell.
* `type`: (Enum) `:instantaneous`, `:rounds`, `:minutes`, `:hours`
* `value`: (Integer) e.g., 10 Rounds.


* **`target_area`**: (Struct) The visual blueprint for the Gibbering Engine’s SVG overlay.
* `shape`: (Enum) `:single_target`, `:sphere`, `:cone`, `:line`, `:cylinder`, `:cube`
* `radius_or_length_feet`: (Integer) e.g., a 20-foot radius sphere.


* **`effect`**: (Polymorphic Payload) What the spell actually executes on hit.
* `type`: (Enum) `:damage`, `:healing`, `:buff_or_debuff`, `:utility`
* `saving_throw_required`: (Enum or nil) e.g., `:dexterity`
* `damage_dice`: (String or nil) e.g., `"8d6"`
* `damage_type`: (Enum or nil) e.g., `:fire`



---

## 3. The Feature and Trait Classification (The Modifier Domain)

To prevent your classes from turning into massive spaghetti monsters, passive abilities like an Elf’s *Darkvision* or a Rogue's *Sneak Attack* are encapsulated into a clean, standalone class hierarchy.

### **RuleModifier** (Abstract Root)

* **Core Properties:** `id`, `name`, `description`.

#### ├── **Trait** (Extends RuleModifier)

Passive biological/ancestral abilities tied strictly to a creature's **Race**.

* *Example:* `DarkvisionTrait` overrides the environmental lighting rules for that actor's rendering viewport.

#### ├── **Feature** (Extends RuleModifier)

Abilities earned through professional training via a creature's **Class**.

* *Example:* `SneakAttackFeature` hooks into the attack phase, checking a conditional edge (`if target_has_disadvantage == false and ally_is_within_5ft == true`) to inject extra damage dice into the calculation loop.

---

This pure high-level universe modeling is precisely how WotC designs their text rules, and it makes translating it into structural programming components incredibly satisfying.

Which high-level domain should we map out next? We can look at how **Items & Equipment** are classified, or dive into the structure of **Conditions & Status Effects**.

---

In the D&D universe, items bridge the gap between static narrative objects and active mechanical rules changers.

To model this at a high level, everything that is a physical object—whether it is sitting inside a chest in a dungeon room or tucked away inside a player’s backpack—inherits from a master **Item** domain.

Here is how the physical world and the inventory system are classified in the D&D 5e universe.

---

## 1. The Item Domain Taxonomy

An item is essentially a passive data container until it is interacted with, equipped, or consumed. Here is how the high-level classification tree breaks down:

### **Item** (The Abstract Root Class)

Every physical object in the world belongs to this lineage.

* **Core Properties:** `name`, `weight_pounds`, `cost_gold_pieces`, `is_magical` (Boolean), `requires_attunement` (Boolean), `description`.

#### └── **Equipment** (Extends Item)

Items meant to be worn or wielded to alter a creature's core combat stats.

* **Core Properties:** `equipment_slot` (Enum: `:main_hand`, `:off_hand`, `:body`, `:head`, `:ring`, etc.), `is_equipped` (Boolean).

##### ├── **Weapon** (Extends Equipment)

* **Unique Properties:** `damage_dice` (e.g., `"1d8"`), `damage_type` (Enum: `:slashing`, `:piercing`, `:bludgeoning`), `weapon_category` (Enum: `:simple`, `:martial`).
* **Composition:** Contains a list of `WeaponProperties` (Enums: `:finesse`, `:heavy`, `:reach`, `:two_handed`). These act as rule-benders (e.g., `:reach` changes the attack range from 5 feet to 10 feet).

##### ├── **Armor** (Extends Equipment)

* **Unique Properties:** `armor_category` (Enum: `:light`, `:medium`, `:heavy`, `:shield`), `base_ac` (Integer, e.g., 16), `stealth_disadvantage` (Boolean), `strength_requirement` (Integer or nil).

#### └── **Consumable** (Extends Item)

Items that are destroyed upon use to trigger an immediate, one-time spell or mechanical effect.

* **Unique Properties:** `charges_or_uses` (Integer).
* **Composition:** Holds a pointer directly to an **Action or Spell effect** (e.g., a *Potion of Healing* casts a hard-coded Tier-1 healing spell on the consumer).

#### └── **Container** (Extends Item)

Objects designed to hold other item instances. This is how backpacks, sacks, and chests are modeled.

* **Unique Properties:** `weight_capacity_pounds`, `volume_capacity_cubic_feet`.
* **Composition:** Contains a list of `Item` instances.

---

## 2. Inventory vs. Environment: Where Do Items Live?

To make the **Gibbering Engine** understand where an item physically exists, items don't just hang in a vacuum. They exist in one of two major contexts: the **Spatial Context (The Environment)** or the **Possession Context (The Inventory)**.

### A. The Possession Context (Inventory)

When an item is picked up by a hero, it enters that `Creature` node's inventory graph.

* A `Creature` has an `inventory` property, which is a list pointing to `Item` instances.
* If an item is an instance of `Equipment`, it checks the `is_equipped` status.
* **The Rule Link:** If `is_equipped` is true, the item injects its properties directly into the Creature's runtime calculation loop. For example, equipping a Longsword hooks into the creature's "Attack Action" choices. Equipping Plate Armor overrides the creature's baseline Armor Class calculation formula.

### B. The Spatial Context (The Environment)

When an item is sitting in a dungeon room, it is wrapped inside an **Environmental Object** node. This is how the Gibbering Engine can render it on the 2D SVG stage.

#### **WorldObject** (The Environment Class)

An instance of something physically taking up space on the map grid.

* **Core Properties:** `position_x`, `position_y`, `is_passable` (Boolean—can you walk through it?), `is_interactable` (Boolean).

##### ├── **StaticDecor** (Extends WorldObject)

Objects that are purely visual or structural.

* *Examples:* Pillars, walls, non-lootable tables, statues. They have no inventory and cannot be picked up.

##### ├── **LootSource / Interactable** (Extends WorldObject)

Objects that players can open, break, or ransack.

* *Examples:* A treasure chest, a fallen guard's corpse, a pile of gold on the floor.
* **Composition:** This class implements the `Container` traits. It holds a list of `Item` nodes inside it.

---

## 3. The Gameplay Transition Loop

When your friend playing a Rogue walks their pixel-art token up to a chest on the SVG stage and clicks "Open," the Gibbering Engine processes a clean high-level ownership swap:

1. **Query Environment:** The engine checks if the Rogue’s tile coordinates are adjacent to the `WorldObject (Chest)`.
2. **Expose Sub-Graph:** The engine reads the `Container` node inside the chest and streams the names of the `Item` instances back to the client UI.
3. **Transfer Ownership:** When the player clicks "Take All," the engine deletes the items from the Chest's container array and pushes those exact `Item` instances into the Rogue’s `Creature.inventory` array.
4. **Recalculate Weight:** The engine updates the Rogue's total carried weight property based on the sum of the newly acquired item weights.

Does this separation between structural item blueprints and where they physically sit in the world align with how you want the game loop to behave? Next, we could sketch out the core **Turn and Combat Loop** ruleset, or look at how **Environmental Hazards** (like a pit of toxic slime) map onto the grid.


---

In the D&D 5e universe, your intuition is spot on. **Spells and Abilities are fundamentally sibling concepts**, but they are connected through a higher-level abstract mechanism: **The Resource and Action System**.

To make this clear, we need to separate **Ability Scores** (like Strength or Wisdom) from **Class Abilities / Special Features** (like a Paladin’s *Divine Smite*, a Barbarian's *Rage*, or a Wizard's *Spellcasting*).

Here is how the D&D universe structures them at a high level, and exactly how they link to spells.

---

## 1. The Action Resolution Bridge: Feature vs. Spell

In D&D 5e, both a **Spell** (like *Fireball*) and an **Active Class Ability** (like a Paladin's *Divine Smite* or a Dragonborn's *Breath Weapon*) are types of **Actions**. They represent an entity actively forcing a mechanical event onto the game world.

Here is how they sit in the class taxonomy:

### **Action Blueprint** (The Conceptual Parent Class)

Anything an entity can execute on its turn that targets a tile, a creature, or an area.

* **Shared Properties:** `activation_cost` (Action, Bonus Action, Reaction), `range_feet`, `target_shape`, `has_saving_throw`.

#### ├── **Spell** (Extends Action Blueprint)

A magic formula pulled from the fabric of the multiverse.

* **Unique Rules:** It costs a **Spell Slot** resource to cast, it can be countered by *Counterspell*, it belongs to a magic school, and it requires components (Verbal, Somatic, Material).

#### └── **ActivatedAbility** (Extends Action Blueprint)

A special maneuver or supernatural power granted by a creature's Class or Race.

* **Unique Rules:** It doesn't use spell slots. Instead, it uses its own **Class Resource Pool** (e.g., *Ki Points* for Monks, *Channel Divinity* uses for Clerics, or *Superiority Dice* for Fighters). It ignores components and cannot be *Counterspelled*.

---

## 2. How Spells and Class Abilities Intersect

There are two major places where the lines between spells and class abilities blur completely. This is where the "link" becomes explicit in the rules:

### Connection A: Class Abilities That Grant or Cast Spells

The most common link is that **Spellcasting is itself an Activated Ability** granted by a character's Class.

* A Level 1 Wizard has a Class Feature called `Spellcasting`. This feature acts as the gateway container that allows the character to know, prepare, and execute instances of the `Spell` class.
* Other features explicitly cast spells without using slots. For example, a Warlock's `Eldritch Invocations` feature might say: *"You can cast Levitate at will, without expending a spell slot."* In your code, that Class Feature simply acts as a shortcut link pointing directly to the `Spell (Levitate)` blueprint.

### Connection B: The Shared Modifier Loop (Ability Scores)

This is the mathematical link. Both Spells and Activated Abilities rely entirely on a creature's **Core Ability Scores** (Strength, Dexterity, Constitution, Intelligence, Wisdom, Charisma) to calculate their success rates.

Whenever a Spell or an Ability challenges a target, it calculates its **DC (Difficulty Class)** using a shared cosmic formula:

$$\text{DC} = 8 + \text{Proficiency Bonus} + \text{Ability Score Modifier}$$

```
                ┌───────────────────────────┐
                │   Core Ability Scores     │
                │  (STR, DEX, INT, WIS...)  │
                └─────────────┬─────────────┘
                              │ Drops Modifier Into
                              ▼
                ┌───────────────────────────┐
                │   Math Resolver Pipeline  │
                └──────┬─────────────┬──────┘
                       │             │
        Calculates To-Hit / DC       Calculates To-Hit / DC
                       ▼             ▼
              ┌───────────┐       ┌────────────────────┐
              │   Spell   │       │  ActivatedAbility  │
              │ (Fireball)│       │ (Channel Divinity) │
              └───────────┘       └────────────────────┘

```

* **For a Wizard's Spell:** The math loop queries the Wizard's **Intelligence** modifier to see how hard it is to dodge their *Fireball*.
* **For a Cleric's Class Ability:** The math loop queries the Cleric's **Wisdom** modifier to see how hard it is to resist their *Turn Undead* class ability.

---

## 3. The Unified "Power" Structure

When building the **Gibbering Engine**, treating Spells and Activated Abilities as sibling variations of a master `Action` concept is a massive engineering win.

When a user opens their action bar on your 2D SVG stage, the engine doesn't need separate, bloated UI systems for spells and maneuvers. It just queries the character node's `usable_actions` array:

```elixir
# What the Gibbering Engine sees in a character's action book:
usable_actions = [
  %Action{name: "Longsword Swing", type: :weapon_attack},
  %Action{name: "Cure Wounds", type: :spell, resource_required: :spell_slot_level_1},
  %Action{name: "Second Wind", type: :class_ability, resource_required: :short_rest_charge}
]

```

By unifying them under this high-level umbrella, your engine can treat clicking a button to cast a spell or clicking a button to use a fighter maneuver identically: it checks the resource cost, highlights the valid SVG grid targets, and rolls the d20.

Does this clear up the distinction between how stats, features, and spells feed into each other? We can take this high-level understanding and chart out a full **Combat Turn Sequence** to see all of these elements moving at once.
