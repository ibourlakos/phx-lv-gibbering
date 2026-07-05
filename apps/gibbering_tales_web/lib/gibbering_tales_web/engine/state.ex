defmodule GibberingTalesWeb.Engine.State do
  @moduledoc "Runtime scene state: entity map, grid, turn order, and action economy helpers."

  # dnd5e.ex and state.ex are recompiled together; suppress cross-file undefined warning
  @compile {:no_warn_undefined, GibberingTales.Rulesets.DnD5e}

  alias GibberingEngine.Coords
  alias GibberingTales.Campaign
  alias GibberingTales.Rulesets.DnD5e.{RulesetState, Stats}

  @type scene_phase ::
          :lobby | :exploration | :initiative_rolling | :in_combat | :paused | :victory | :defeat

  defstruct [
    :campaign_id,
    :map_id,
    :x_extent,
    :y_extent,
    :tile_size,
    # %{{x, y} => %{texture: string, movement: map, decoration: string | nil}}
    :grid_tiles,
    # %{{x, y, :south | :east} => %{type: :wall | :door, open: bool}} — see GibberingEngine.Coords
    :edges,
    # %{id => %{name, type, sprite, x, y, hp, max_hp, tags, stats}}
    :actors,
    # integer | nil
    :actor_id,
    # [{x, y}]
    :valid_moves,
    # %{{x, y} => :normal | :difficult} — terrain cost tier per reachable tile; populated with valid_moves
    :valid_move_costs,
    # [entity_id] — entities the selected entity can attack or target this turn
    :valid_targets,
    # [entity_id] — hero ids in sequence
    :turn_order,
    # index into turn_order
    :active_index,
    # module implementing Gibbering.Ruleset behaviour
    ruleset: GibberingTales.Rulesets.DnD5e,
    # opaque D&D 5e-specific state (phase, initiative, effects, etc.)
    ruleset_state: nil
  ]

  @doc """
  Builds an initial `%State{}` from a `%Campaign{}` loaded with its tiles and entities.

  `presets` is an optional `%{key => %EntityPreset{}}` map. When supplied, each entity whose
  `preset_key` matches a preset has `:object_subtype` populated from the preset, replacing the
  old `stats[\"object_subtype\"]` workaround.
  """
  def from_campaign(%Campaign{} = campaign, presets \\ %{}) do
    map = campaign.active_map

    tiles =
      map.tiles
      |> Map.new(fn t ->
        {{t.x, t.y}, %{texture: t.texture, movement: t.movement, decoration: t.decoration}}
      end)

    entities =
      campaign.entities
      |> Map.new(fn e ->
        preset = e.preset_key && Map.get(presets, e.preset_key)

        base = %{
          name: e.name,
          type: e.type,
          sprite: e.sprite,
          race: e.race || "human",
          class: e.class || "fighter",
          x: e.x,
          y: e.y,
          facing: :south,
          hp: e.hp,
          max_hp: e.max_hp,
          level: e.level,
          temp_hp: e.temp_hp,
          tags: e.tags,
          stats: e.stats,
          speed: (e.stats || %{})["speed"] || 30,
          object_subtype: (preset && preset.object_subtype) || (e.stats || %{})["object_subtype"],
          description: preset && preset.description
        }

        ruleset = GibberingTales.Rulesets.DnD5e

        hydrated =
          base
          |> Map.put(:action_economy, ruleset.initial_action_economy(base))
          |> Map.put(:resources, ruleset.initial_resources(base))
          |> Map.put(:conditions, [])
          |> Stats.hydrate_entity()

        {e.id, hydrated}
      end)

    hero_ids =
      campaign.entities
      |> Enum.filter(&(&1.type == "hero"))
      |> Enum.map(& &1.id)

    ruleset = GibberingTales.Rulesets.DnD5e

    %__MODULE__{
      campaign_id: campaign.id,
      map_id: map.id,
      x_extent: map.x_extent,
      y_extent: map.y_extent,
      tile_size: map.tile_size,
      grid_tiles: tiles,
      edges: Coords.decode_edges(map.edges || %{}),
      actors: entities,
      actor_id: nil,
      valid_moves: [],
      valid_move_costs: %{},
      valid_targets: [],
      turn_order: hero_ids,
      active_index: 0,
      ruleset: ruleset,
      ruleset_state: ruleset.init_ruleset_state()
    }
  end

  # ---------------------------------------------------------------------------
  # Accessors — read ruleset_state fields through DnD5e.RulesetState functions
  # ---------------------------------------------------------------------------

  @doc "Returns the current scene phase."
  def phase(%__MODULE__{ruleset_state: rs}), do: RulesetState.phase(rs)

  @doc "Returns the phase before entering :paused, or nil."
  def previous_phase(%__MODULE__{ruleset_state: rs}), do: RulesetState.previous_phase(rs)

  @doc "Returns true while waiting for a manual player roll."
  def awaiting_roll?(%__MODULE__{ruleset_state: rs}), do: RulesetState.awaiting_roll?(rs)

  @doc "Returns the suspended action pending a roll result."
  def pending_roll(%__MODULE__{ruleset_state: rs}), do: RulesetState.pending_roll(rs)

  @doc "Returns the MapSet of entity_ids whose initiative rolls are still pending."
  def pending_initiative_rolls(%__MODULE__{ruleset_state: rs}),
    do: RulesetState.pending_initiative_rolls(rs)

  @doc "Returns the entity_id of the container currently open for the active hero, or nil."
  def open_container_id(%__MODULE__{ruleset_state: rs}), do: RulesetState.open_container_id(rs)

  # ---------------------------------------------------------------------------
  # Phase transitions (delegate to RulesetState)
  # ---------------------------------------------------------------------------

  @doc """
  Transitions to `new_phase` if the transition is valid.
  From `:paused`, the only valid target is `previous_phase`.
  Returns `{:ok, new_state}` or `{:error, reason}`.
  """
  def transition_phase(%__MODULE__{} = state, new_phase) do
    case RulesetState.transition_phase(state.ruleset_state, new_phase) do
      {:ok, rs} -> {:ok, %{state | ruleset_state: rs}}
      err -> err
    end
  end

  @doc "Forces a phase transition without validation — for DM override calls."
  def force_transition_phase(%__MODULE__{} = state, new_phase) do
    case RulesetState.force_transition_phase(state.ruleset_state, new_phase) do
      {:ok, rs} -> {:ok, %{state | ruleset_state: rs}}
      err -> err
    end
  end

  @doc """
  Stores `value` as the initiative for `entity_id` and re-sorts `turn_order` by
  initiative descending. The currently active entity remains active after the sort.
  """
  def set_initiative(%__MODULE__{} = state, entity_id, value) do
    new_rs = RulesetState.set_initiative_value(state.ruleset_state, entity_id, value)
    initiative_values = RulesetState.initiative_values(new_rs)
    current = Enum.at(state.turn_order, state.active_index)
    sorted = Enum.sort_by(state.turn_order, fn id -> -Map.get(initiative_values, id, 0) end)
    new_index = (current && Enum.find_index(sorted, &(&1 == current))) || 0
    %{state | ruleset_state: new_rs, turn_order: sorted, active_index: new_index}
  end

  @doc "Appends `entity_id` to `turn_order`. No-op if already present or not in entities."
  def add_to_turn_order(%__MODULE__{} = state, entity_id) do
    if entity_id in state.turn_order or not Map.has_key?(state.actors, entity_id) do
      state
    else
      %{state | turn_order: state.turn_order ++ [entity_id]}
    end
  end

  @doc "Removes `entity_id` from `turn_order`, keeping `active_index` in bounds."
  def remove_from_turn_order(%__MODULE__{} = state, entity_id) do
    new_order = List.delete(state.turn_order, entity_id)
    new_index = min(state.active_index, max(length(new_order) - 1, 0))
    %{state | turn_order: new_order, active_index: new_index}
  end

  @doc """
  Replaces `turn_order` with `ordered_ids`, filtering out any ids not currently in the
  order. The currently active entity's position is preserved.
  """
  def reorder_turn_order(%__MODULE__{} = state, ordered_ids) do
    current = Enum.at(state.turn_order, state.active_index)
    valid = Enum.filter(ordered_ids, &(&1 in state.turn_order))
    new_index = (current && Enum.find_index(valid, &(&1 == current))) || 0
    %{state | turn_order: valid, active_index: new_index}
  end

  @doc "Applies `delta` HP to `entity_id`, clamping to `[0, max_hp]`. No-op for unknown ids."
  def adjust_hp(%__MODULE__{} = state, entity_id, delta) do
    case Map.get(state.actors, entity_id) do
      nil ->
        state

      entity ->
        new_hp = max(0, min(entity.max_hp, entity.hp + delta))
        updated = Map.put(entity, :hp, new_hp)
        %{state | actors: Map.put(state.actors, entity_id, updated)}
    end
  end

  @doc "Adds `entity_id` to the DM-hidden set."
  def hide_entity(%__MODULE__{} = state, entity_id) do
    %{state | ruleset_state: RulesetState.hide_entity(state.ruleset_state, entity_id)}
  end

  @doc "Removes `entity_id` from the DM-hidden set."
  def show_entity(%__MODULE__{} = state, entity_id) do
    %{state | ruleset_state: RulesetState.show_entity(state.ruleset_state, entity_id)}
  end

  @doc "Toggles `entity_id` in the hidden set."
  def toggle_visibility(%__MODULE__{} = state, entity_id) do
    %{state | ruleset_state: RulesetState.toggle_visibility(state.ruleset_state, entity_id)}
  end

  @doc "Prepends a log entry string to `session_log`."
  def add_log_entry(%__MODULE__{} = state, entry) do
    %{state | ruleset_state: RulesetState.add_log_entry(state.ruleset_state, entry)}
  end

  # ---------------------------------------------------------------------------
  # Roll state (delegate to RulesetState)
  # ---------------------------------------------------------------------------

  @doc "Clears the suspended roll: sets awaiting_roll to false and pending_roll to nil."
  def clear_pending_roll(%__MODULE__{} = state) do
    %{state | ruleset_state: RulesetState.clear_pending_roll(state.ruleset_state)}
  end

  @doc "Adds `entity_id` to the pending initiative rolls set."
  def add_pending_initiative_roll(%__MODULE__{} = state, entity_id) do
    %{
      state
      | ruleset_state: RulesetState.add_pending_initiative_roll(state.ruleset_state, entity_id)
    }
  end

  @doc "Removes `entity_id` from the pending initiative rolls set."
  def remove_pending_initiative_roll(%__MODULE__{} = state, entity_id) do
    %{
      state
      | ruleset_state: RulesetState.remove_pending_initiative_roll(state.ruleset_state, entity_id)
    }
  end

  @doc "Sets the open_container_id in ruleset_state."
  def set_open_container_id(%__MODULE__{} = state, id) do
    %{state | ruleset_state: RulesetState.set_open_container_id(state.ruleset_state, id)}
  end

  @doc "Suspends an action pending a player roll. Sets awaiting_roll: true and records the pending action."
  def set_awaiting_roll(%__MODULE__{} = state, pending_action) do
    rs =
      state.ruleset_state
      |> RulesetState.set_awaiting_roll(true)
      |> RulesetState.set_pending_roll(pending_action)

    %{state | ruleset_state: rs}
  end

  @doc "Returns the entity id of the hero whose turn it currently is, or `nil` when there is no turn order."
  def active_hero_id(%__MODULE__{turn_order: []}), do: nil
  def active_hero_id(%__MODULE__{turn_order: order, active_index: idx}), do: Enum.at(order, idx)

  @doc """
  Returns `:victory` if all monsters are at 0 HP, `:defeat` if all heroes are at 0 HP,
  or `nil` if neither condition is met. Requires at least one entity of each relevant
  type to be present before triggering. Intended to be called only during `:in_combat`.
  """
  def check_combat_outcome(%__MODULE__{actors: entities}) do
    {heroes, monsters} =
      Enum.split_with(Map.values(entities), fn e -> e.type == "hero" end)

    cond do
      monsters != [] and Enum.all?(monsters, &(&1.hp == 0)) -> :victory
      heroes != [] and Enum.all?(heroes, &(&1.hp == 0)) -> :defeat
      true -> nil
    end
  end

  @doc """
  Marks an action economy slot as `:spent`.
  Returns `{:ok, new_state}` or `{:error, :already_spent}`.
  """
  def consume_action(%__MODULE__{} = state, entity_id, slot)
      when slot in [:action, :bonus_action, :reaction] do
    entity = state.actors[entity_id]

    case get_in(entity, [:action_economy, slot]) do
      :available ->
        updated = put_in(entity, [:action_economy, slot], :spent)
        {:ok, %{state | actors: Map.put(state.actors, entity_id, updated)}}

      _ ->
        {:error, :already_spent}
    end
  end

  @doc """
  Deducts `feet` from the entity's `movement_remaining`.
  Returns `{:ok, new_state}` or `{:error, :insufficient_movement}`.
  """
  def consume_movement(%__MODULE__{} = state, entity_id, feet) do
    entity = state.actors[entity_id]
    remaining = get_in(entity, [:action_economy, :movement_remaining]) || 0

    if remaining >= feet do
      updated = put_in(entity, [:action_economy, :movement_remaining], remaining - feet)
      {:ok, %{state | actors: Map.put(state.actors, entity_id, updated)}}
    else
      {:error, :insufficient_movement}
    end
  end

  @doc """
  Decrements a named class resource by 1.
  Returns `{:ok, new_state}` or `{:error, :no_charges}`.
  """
  def consume_resource(%__MODULE__{} = state, entity_id, resource_key) do
    entity = state.actors[entity_id]
    current = get_in(entity, [:resources, resource_key]) || 0

    if is_integer(current) and current >= 1 do
      updated = put_in(entity, [:resources, resource_key], current - 1)
      {:ok, %{state | actors: Map.put(state.actors, entity_id, updated)}}
    else
      {:error, :no_charges}
    end
  end

  @doc """
  Decrements a spell slot at the given `level`.
  Returns `{:ok, new_state}` or `{:error, :no_slots}`.
  """
  def consume_spell_slot(%__MODULE__{} = state, entity_id, level) do
    entity = state.actors[entity_id]
    current = get_in(entity, [:resources, :spell_slots, level]) || 0

    if current >= 1 do
      updated = put_in(entity, [:resources, :spell_slots, level], current - 1)
      {:ok, %{state | actors: Map.put(state.actors, entity_id, updated)}}
    else
      {:error, :no_slots}
    end
  end

  @doc "Applies short-rest recovery to a single entity via the active ruleset."
  def apply_short_rest(%__MODULE__{} = state, entity_id) do
    entity = state.actors[entity_id]

    {:ok,
     %{
       state
       | actors: Map.put(state.actors, entity_id, state.ruleset.short_rest_entity(entity))
     }}
  end

  @doc "Applies long-rest recovery to a single entity via the active ruleset."
  def apply_long_rest(%__MODULE__{} = state, entity_id) do
    entity = state.actors[entity_id]

    {:ok,
     %{
       state
       | actors: Map.put(state.actors, entity_id, state.ruleset.long_rest_entity(entity))
     }}
  end

  @doc """
  Applies `condition_id` to `entity_id`.
  Adds an ActiveEffect entry to `ruleset_state.active_effects` and appends the key to
  `entity.conditions`. Opts: `source:` (default `:unknown`), `duration:` integer
  turns or nil for permanent.
  Returns `{:ok, new_state}`.
  """
  def apply_condition(%__MODULE__{} = state, entity_id, condition_id, opts \\ []) do
    effect = %{
      id: System.unique_integer([:positive]),
      entity_id: entity_id,
      condition_id: condition_id,
      conditions: [condition_id],
      source: Keyword.get(opts, :source, :unknown),
      duration: Keyword.get(opts, :duration, nil)
    }

    new_rs = RulesetState.add_active_effect(state.ruleset_state, effect)

    new_entities =
      Map.update!(state.actors, entity_id, fn entity ->
        Map.update(entity, :conditions, [condition_id], &Enum.uniq([condition_id | &1]))
      end)

    {:ok, %{state | ruleset_state: new_rs, actors: new_entities}}
  end

  @doc """
  Removes all active effects for `condition_id` from `entity_id`.
  Removes the key from `entity.conditions` unless another active effect
  still lists it. Returns `{:ok, new_state}`.
  """
  def remove_condition(%__MODULE__{} = state, entity_id, condition_id) do
    {new_rs, still_active} =
      RulesetState.remove_active_effects_for(state.ruleset_state, entity_id, condition_id)

    new_entities =
      Map.update!(state.actors, entity_id, fn entity ->
        if still_active,
          do: entity,
          else: Map.update(entity, :conditions, [], &List.delete(&1, condition_id))
      end)

    {:ok, %{state | ruleset_state: new_rs, actors: new_entities}}
  end

  @doc "Advances to the next hero in the turn order and resets that hero's action economy for the new turn."
  def advance_turn(%__MODULE__{} = state) do
    next = rem(state.active_index + 1, max(length(state.turn_order), 1))
    next_id = Enum.at(state.turn_order, next)

    entities =
      if next_id && Map.has_key?(state.actors, next_id) do
        Map.update!(state.actors, next_id, &state.ruleset.advance_turn/1)
      else
        state.actors
      end

    %{
      state
      | active_index: next,
        actor_id: nil,
        valid_moves: [],
        valid_move_costs: %{},
        valid_targets: [],
        actors: entities
    }
  end
end
