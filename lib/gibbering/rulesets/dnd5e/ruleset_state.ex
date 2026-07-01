defmodule Gibbering.Rulesets.DnD5e.RulesetState do
  @moduledoc """
  D&D 5e-specific runtime state stored as an opaque term in `Engine.State.ruleset_state`.

  Engine code must never pattern-match on or read fields of this struct directly.
  All access goes through the accessor and mutator functions defined here, called
  either from `Engine.State` wrapper functions or from D&D ruleset modules.
  """

  @valid_transitions %{
    lobby: [:exploration, :paused],
    exploration: [:initiative_rolling, :in_combat, :paused],
    initiative_rolling: [:in_combat, :paused],
    in_combat: [:exploration, :paused, :victory, :defeat]
  }

  defstruct [
    # Current scene phase
    phase: :lobby,
    # Phase before entering :paused (used to resume correctly)
    previous_phase: nil,
    # [%{id, entity_id, condition_id, conditions, source, duration}]
    active_effects: [],
    # %{entity_id => integer} — DM-rolled initiative values per entity
    initiative_values: %{},
    # MapSet of entity_ids hidden from player view
    hidden_entities: %MapSet{},
    # [{timestamp, text}] — intervention log, newest first
    session_log: [],
    # entity_id of the container currently open for the active hero, or nil
    open_container_id: nil,
    # true while waiting for a player to submit a manual roll value
    awaiting_roll: false,
    # {:attack, target_id} | {:cast_spell, spell_key, target_id} | nil
    pending_roll: nil,
    # MapSet of entity_ids whose initiative rolls are still pending player input
    pending_initiative_rolls: %MapSet{}
  ]

  @doc "Returns an initialized ruleset state for a new D&D 5e scene."
  def new do
    %__MODULE__{}
  end

  # ---------------------------------------------------------------------------
  # Accessors — all struct field reads go through these functions
  # ---------------------------------------------------------------------------

  @doc "Returns the current scene phase."
  def phase(%__MODULE__{phase: p}), do: p

  @doc "Returns the phase before entering `:paused`, or nil."
  def previous_phase(%__MODULE__{previous_phase: p}), do: p

  @doc "Returns true while waiting for a manual player roll."
  def awaiting_roll?(%__MODULE__{awaiting_roll: v}), do: v

  @doc "Returns the suspended action pending a roll result, or nil."
  def pending_roll(%__MODULE__{pending_roll: v}), do: v

  @doc "Returns the MapSet of entity_ids whose initiative rolls are still pending."
  def pending_initiative_rolls(%__MODULE__{pending_initiative_rolls: s}), do: s

  @doc "Returns the entity_id of the container currently open for the active hero, or nil."
  def open_container_id(%__MODULE__{open_container_id: id}), do: id

  @doc "Returns the map of `%{entity_id => integer}` initiative values."
  def initiative_values(%__MODULE__{initiative_values: v}), do: v

  @doc "Returns the MapSet of entity_ids hidden from player view."
  def hidden_entities(%__MODULE__{hidden_entities: s}), do: s

  @doc "Returns the session log as a list of entries, newest first."
  def session_log(%__MODULE__{session_log: l}), do: l

  @doc "Returns the list of active effect maps."
  def active_effects(%__MODULE__{active_effects: l}), do: l

  # ---------------------------------------------------------------------------
  # Phase transitions
  # ---------------------------------------------------------------------------

  @doc "Transitions to `new_phase` if the transition is valid. Returns `{:ok, rs}` or `{:error, reason}`."
  def transition_phase(%__MODULE__{phase: same} = rs, same), do: {:ok, rs}

  def transition_phase(%__MODULE__{phase: :paused, previous_phase: prev} = rs, new_phase) do
    if new_phase == prev do
      {:ok, %{rs | phase: new_phase, previous_phase: nil}}
    else
      {:error, "cannot leave :paused to #{new_phase}; expected #{prev}"}
    end
  end

  def transition_phase(%__MODULE__{phase: current} = rs, new_phase) do
    if new_phase in Map.get(@valid_transitions, current, []) do
      {:ok, %{rs | previous_phase: current, phase: new_phase}}
    else
      {:error, "invalid transition: #{current} → #{new_phase}"}
    end
  end

  @doc "Forces a phase transition without validation — for DM override calls."
  def force_transition_phase(%__MODULE__{phase: current} = rs, new_phase) do
    {:ok, %{rs | previous_phase: current, phase: new_phase}}
  end

  # ---------------------------------------------------------------------------
  # Initiative
  # ---------------------------------------------------------------------------

  @doc "Stores `value` as the initiative for `entity_id`. Sorting is done by Engine.State wrapper."
  def set_initiative_value(%__MODULE__{} = rs, entity_id, value) do
    %{rs | initiative_values: Map.put(rs.initiative_values, entity_id, value)}
  end

  # ---------------------------------------------------------------------------
  # Visibility
  # ---------------------------------------------------------------------------

  @doc "Adds `entity_id` to the hidden set."
  def hide_entity(%__MODULE__{} = rs, entity_id) do
    %{rs | hidden_entities: MapSet.put(rs.hidden_entities, entity_id)}
  end

  @doc "Removes `entity_id` from the hidden set."
  def show_entity(%__MODULE__{} = rs, entity_id) do
    %{rs | hidden_entities: MapSet.delete(rs.hidden_entities, entity_id)}
  end

  @doc "Toggles visibility for `entity_id`: hides if visible, shows if hidden."
  def toggle_visibility(%__MODULE__{} = rs, entity_id) do
    if MapSet.member?(rs.hidden_entities, entity_id),
      do: show_entity(rs, entity_id),
      else: hide_entity(rs, entity_id)
  end

  # ---------------------------------------------------------------------------
  # Session log
  # ---------------------------------------------------------------------------

  @doc "Prepends `entry` to `session_log`."
  def add_log_entry(%__MODULE__{} = rs, entry) do
    %{rs | session_log: [entry | rs.session_log]}
  end

  # ---------------------------------------------------------------------------
  # Roll state
  # ---------------------------------------------------------------------------

  @doc "Sets the `awaiting_roll` flag."
  def set_awaiting_roll(%__MODULE__{} = rs, value) when is_boolean(value) do
    %{rs | awaiting_roll: value}
  end

  @doc "Sets the `pending_roll` action descriptor."
  def set_pending_roll(%__MODULE__{} = rs, value) do
    %{rs | pending_roll: value}
  end

  @doc "Clears the suspended roll: sets awaiting_roll to false and pending_roll to nil."
  def clear_pending_roll(%__MODULE__{} = rs) do
    %{rs | awaiting_roll: false, pending_roll: nil}
  end

  @doc "Adds `entity_id` to the set of entities with a pending initiative roll."
  def add_pending_initiative_roll(%__MODULE__{} = rs, entity_id) do
    %{rs | pending_initiative_rolls: MapSet.put(rs.pending_initiative_rolls, entity_id)}
  end

  @doc "Removes `entity_id` from the set of entities with a pending initiative roll."
  def remove_pending_initiative_roll(%__MODULE__{} = rs, entity_id) do
    %{rs | pending_initiative_rolls: MapSet.delete(rs.pending_initiative_rolls, entity_id)}
  end

  # ---------------------------------------------------------------------------
  # Container
  # ---------------------------------------------------------------------------

  @doc "Sets the open container entity id (or nil to close)."
  def set_open_container_id(%__MODULE__{} = rs, id) do
    %{rs | open_container_id: id}
  end

  # ---------------------------------------------------------------------------
  # Conditions / active effects
  # ---------------------------------------------------------------------------

  @doc "Adds an active effect entry to `active_effects`. Entity conditions are updated by Engine.State."
  def add_active_effect(%__MODULE__{} = rs, effect) do
    %{rs | active_effects: [effect | rs.active_effects]}
  end

  @doc "Removes all active effects for `condition_id` on `entity_id`. Returns `{new_rs, still_active?}`."
  def remove_active_effects_for(%__MODULE__{} = rs, entity_id, condition_id) do
    new_effects =
      Enum.reject(rs.active_effects, fn ae ->
        ae.entity_id == entity_id and ae.condition_id == condition_id
      end)

    still_active =
      Enum.any?(new_effects, fn ae ->
        ae.entity_id == entity_id and condition_id in (ae.conditions || [])
      end)

    {%{rs | active_effects: new_effects}, still_active}
  end
end
