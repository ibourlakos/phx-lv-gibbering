defmodule Gibbering.Engine.State do
  @moduledoc "Runtime scene state: entity map, grid, turn order, phase machine, and action economy helpers."

  alias Gibbering.Campaign
  alias Gibbering.Rulesets.DnD5e.Stats

  @type scene_phase :: :lobby | :exploration | :initiative_rolling | :in_combat | :paused

  @valid_transitions %{
    lobby: [:exploration, :paused],
    exploration: [:initiative_rolling, :in_combat, :paused],
    initiative_rolling: [:in_combat, :paused],
    in_combat: [:exploration, :paused]
  }

  defstruct [
    :campaign_id,
    :map_width,
    :map_height,
    :tile_size,
    # %{{x, y} => %{texture: string, walkable: bool}}
    :grid_tiles,
    # %{id => %{name, type, sprite, x, y, hp, max_hp, tags, stats}}
    :entities,
    # integer | nil
    :selected_id,
    # [{x, y}]
    :valid_moves,
    # [entity_id] — hero ids in sequence
    :turn_order,
    # index into turn_order
    :active_index,
    # scene_phase() — current phase of the scene
    phase: :lobby,
    # scene_phase() | nil — phase before entering :paused
    previous_phase: nil,
    # module implementing Gibbering.Ruleset behaviour
    ruleset: Gibbering.Rulesets.DnD5e,
    # [%{id, entity_id, condition_id, conditions, source, duration}]
    active_effects: [],
    # %{entity_id => integer} — DM-rolled initiative values per entity
    initiative_values: %{},
    # MapSet of entity_ids hidden from player view (DM-only visibility)
    hidden_entities: %MapSet{},
    # [{timestamp, text}] — chronological intervention log, newest first
    session_log: []
  ]

  @doc "Builds an initial `%State{}` from a `%Campaign{}` loaded with its tiles and entities."
  def from_campaign(%Campaign{} = campaign) do
    tiles =
      campaign.tiles
      |> Map.new(fn t ->
        {{t.x, t.y}, %{texture: t.texture, walkable: t.walkable, decoration: t.decoration}}
      end)

    entities =
      campaign.entities
      |> Map.new(fn e ->
        base = %{
          name: e.name,
          type: e.type,
          sprite: e.sprite,
          race: e.race || "human",
          class: e.class || "fighter",
          x: e.x,
          y: e.y,
          hp: e.hp,
          max_hp: e.max_hp,
          level: e.level,
          temp_hp: e.temp_hp,
          tags: e.tags,
          stats: e.stats,
          speed: (e.stats || %{})["speed"] || 30
        }

        ruleset = Gibbering.Rulesets.DnD5e

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

    %__MODULE__{
      campaign_id: campaign.id,
      map_width: campaign.map_width,
      map_height: campaign.map_height,
      tile_size: campaign.tile_size,
      grid_tiles: tiles,
      entities: entities,
      selected_id: nil,
      valid_moves: [],
      turn_order: hero_ids,
      active_index: 0,
      phase: :lobby,
      previous_phase: nil,
      ruleset: Gibbering.Rulesets.DnD5e,
      active_effects: []
    }
  end

  @doc """
  Transitions to `new_phase` if the transition is valid.
  From `:paused`, the only valid target is `previous_phase`.
  Returns `{:ok, new_state}` or `{:error, reason}`.
  """
  def transition_phase(%__MODULE__{phase: same} = state, same), do: {:ok, state}

  def transition_phase(%__MODULE__{phase: :paused, previous_phase: prev} = state, new_phase) do
    if new_phase == prev do
      {:ok, %{state | phase: new_phase, previous_phase: nil}}
    else
      {:error, "cannot leave :paused to #{new_phase}; expected #{prev}"}
    end
  end

  def transition_phase(%__MODULE__{phase: current} = state, new_phase) do
    if new_phase in Map.get(@valid_transitions, current, []) do
      {:ok, %{state | previous_phase: current, phase: new_phase}}
    else
      {:error, "invalid transition: #{current} → #{new_phase}"}
    end
  end

  @doc "Forces a phase transition without validation — for DM override calls."
  def force_transition_phase(%__MODULE__{phase: current} = state, new_phase) do
    {:ok, %{state | previous_phase: current, phase: new_phase}}
  end

  @doc """
  Stores `value` as the initiative for `entity_id` and re-sorts `turn_order` by
  initiative descending. The currently active entity remains active after the sort.
  """
  def set_initiative(%__MODULE__{} = state, entity_id, value) do
    current = Enum.at(state.turn_order, state.active_index)
    new_initiative = Map.put(state.initiative_values || %{}, entity_id, value)
    sorted = Enum.sort_by(state.turn_order, fn id -> -Map.get(new_initiative, id, 0) end)
    new_index = (current && Enum.find_index(sorted, &(&1 == current))) || 0
    %{state | initiative_values: new_initiative, turn_order: sorted, active_index: new_index}
  end

  @doc "Appends `entity_id` to `turn_order`. No-op if already present or not in entities."
  def add_to_turn_order(%__MODULE__{} = state, entity_id) do
    if entity_id in state.turn_order or not Map.has_key?(state.entities, entity_id) do
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
    case Map.get(state.entities, entity_id) do
      nil ->
        state

      entity ->
        new_hp = max(0, min(entity.max_hp, entity.hp + delta))
        updated = Map.put(entity, :hp, new_hp)
        %{state | entities: Map.put(state.entities, entity_id, updated)}
    end
  end

  @doc "Adds `entity_id` to the DM-hidden set."
  def hide_entity(%__MODULE__{} = state, entity_id) do
    %{state | hidden_entities: MapSet.put(state.hidden_entities || MapSet.new(), entity_id)}
  end

  @doc "Removes `entity_id` from the DM-hidden set."
  def show_entity(%__MODULE__{} = state, entity_id) do
    %{state | hidden_entities: MapSet.delete(state.hidden_entities || MapSet.new(), entity_id)}
  end

  @doc "Toggles `entity_id` in the hidden set."
  def toggle_visibility(%__MODULE__{} = state, entity_id) do
    set = state.hidden_entities || MapSet.new()

    if MapSet.member?(set, entity_id),
      do: show_entity(state, entity_id),
      else: hide_entity(state, entity_id)
  end

  @doc "Prepends a log entry string to `session_log`."
  def add_log_entry(%__MODULE__{} = state, entry) do
    %{state | session_log: [entry | state.session_log || []]}
  end

  @doc "Returns the entity id of the hero whose turn it currently is, or `nil` when there is no turn order."
  def active_hero_id(%__MODULE__{turn_order: []}), do: nil
  def active_hero_id(%__MODULE__{turn_order: order, active_index: idx}), do: Enum.at(order, idx)

  @doc """
  Marks an action economy slot as `:spent`.
  Returns `{:ok, new_state}` or `{:error, :already_spent}`.
  """
  def consume_action(%__MODULE__{} = state, entity_id, slot)
      when slot in [:action, :bonus_action, :reaction] do
    entity = state.entities[entity_id]

    case get_in(entity, [:action_economy, slot]) do
      :available ->
        updated = put_in(entity, [:action_economy, slot], :spent)
        {:ok, %{state | entities: Map.put(state.entities, entity_id, updated)}}

      _ ->
        {:error, :already_spent}
    end
  end

  @doc """
  Deducts `feet` from the entity's `movement_remaining`.
  Returns `{:ok, new_state}` or `{:error, :insufficient_movement}`.
  """
  def consume_movement(%__MODULE__{} = state, entity_id, feet) do
    entity = state.entities[entity_id]
    remaining = get_in(entity, [:action_economy, :movement_remaining]) || 0

    if remaining >= feet do
      updated = put_in(entity, [:action_economy, :movement_remaining], remaining - feet)
      {:ok, %{state | entities: Map.put(state.entities, entity_id, updated)}}
    else
      {:error, :insufficient_movement}
    end
  end

  @doc """
  Decrements a named class resource by 1.
  Returns `{:ok, new_state}` or `{:error, :no_charges}`.
  """
  def consume_resource(%__MODULE__{} = state, entity_id, resource_key) do
    entity = state.entities[entity_id]
    current = get_in(entity, [:resources, resource_key]) || 0

    if is_integer(current) and current >= 1 do
      updated = put_in(entity, [:resources, resource_key], current - 1)
      {:ok, %{state | entities: Map.put(state.entities, entity_id, updated)}}
    else
      {:error, :no_charges}
    end
  end

  @doc """
  Decrements a spell slot at the given `level`.
  Returns `{:ok, new_state}` or `{:error, :no_slots}`.
  """
  def consume_spell_slot(%__MODULE__{} = state, entity_id, level) do
    entity = state.entities[entity_id]
    current = get_in(entity, [:resources, :spell_slots, level]) || 0

    if current >= 1 do
      updated = put_in(entity, [:resources, :spell_slots, level], current - 1)
      {:ok, %{state | entities: Map.put(state.entities, entity_id, updated)}}
    else
      {:error, :no_slots}
    end
  end

  @doc "Applies short-rest recovery to a single entity via the active ruleset."
  def apply_short_rest(%__MODULE__{} = state, entity_id) do
    entity = state.entities[entity_id]

    {:ok,
     %{
       state
       | entities: Map.put(state.entities, entity_id, state.ruleset.short_rest_entity(entity))
     }}
  end

  @doc "Applies long-rest recovery to a single entity via the active ruleset."
  def apply_long_rest(%__MODULE__{} = state, entity_id) do
    entity = state.entities[entity_id]

    {:ok,
     %{
       state
       | entities: Map.put(state.entities, entity_id, state.ruleset.long_rest_entity(entity))
     }}
  end

  @doc """
  Applies `condition_id` to `entity_id`.
  Adds an ActiveEffect entry to `state.active_effects` and appends the key to
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

    new_entities =
      Map.update!(state.entities, entity_id, fn entity ->
        Map.update(entity, :conditions, [condition_id], &Enum.uniq([condition_id | &1]))
      end)

    {:ok, %{state | active_effects: [effect | state.active_effects], entities: new_entities}}
  end

  @doc """
  Removes all active effects for `condition_id` from `entity_id`.
  Removes the key from `entity.conditions` unless another active effect
  still lists it. Returns `{:ok, new_state}`.
  """
  def remove_condition(%__MODULE__{} = state, entity_id, condition_id) do
    new_effects =
      Enum.reject(state.active_effects, fn ae ->
        ae.entity_id == entity_id and ae.condition_id == condition_id
      end)

    still_active =
      Enum.any?(new_effects, fn ae ->
        ae.entity_id == entity_id and condition_id in (ae.conditions || [])
      end)

    new_entities =
      Map.update!(state.entities, entity_id, fn entity ->
        if still_active,
          do: entity,
          else: Map.update(entity, :conditions, [], &List.delete(&1, condition_id))
      end)

    {:ok, %{state | active_effects: new_effects, entities: new_entities}}
  end

  @doc "Advances to the next hero in the turn order and resets that hero's action economy for the new turn."
  def advance_turn(%__MODULE__{} = state) do
    next = rem(state.active_index + 1, max(length(state.turn_order), 1))
    next_id = Enum.at(state.turn_order, next)

    entities =
      if next_id && Map.has_key?(state.entities, next_id) do
        Map.update!(state.entities, next_id, &state.ruleset.advance_turn/1)
      else
        state.entities
      end

    %{state | active_index: next, selected_id: nil, valid_moves: [], entities: entities}
  end
end
