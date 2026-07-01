defmodule Gibbering.Events.DnD5e.AttackResolved do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), after an attack roll is resolved.
  Signals: attacker rolled against target; hit? indicates whether the attack hit.
  This event is D&D-specific because the attack/hit resolution model is a 5e concept.
  """

  @current_version 1

  @behaviour Gibbering.Events.Upcaster

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: atom(),
          schema_version: pos_integer(),
          occurred_at: DateTime.t(),
          correlation_id: String.t(),
          causation_id: String.t(),
          sequence_number: non_neg_integer(),
          visibility: :public | :dm_only | :revealed,
          attacker_id: String.t(),
          attacker_name: String.t(),
          target_id: String.t(),
          target_name: String.t(),
          roll: non_neg_integer(),
          hit?: boolean()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :attacker_id,
    :attacker_name,
    :target_id,
    :target_name,
    :roll,
    :hit?,
    event_type: :attack_resolved,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl Gibbering.Events.Upcaster
  def current_version, do: @current_version

  @impl Gibbering.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
