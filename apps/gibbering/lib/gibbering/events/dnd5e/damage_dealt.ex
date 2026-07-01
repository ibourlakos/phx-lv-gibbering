defmodule Gibbering.Events.DnD5e.DamageDealt do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), after damage is applied to a target.
  Signals: target took amount damage of damage_type; new_hp is the authoritative
  post-damage HP. Damage types (slashing, fire, etc.) are D&D 5e SRD concepts.
  """

  @current_version 1

  @behaviour GibberingEngine.Events.Upcaster

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_type: atom(),
          schema_version: pos_integer(),
          occurred_at: DateTime.t(),
          correlation_id: String.t(),
          causation_id: String.t(),
          sequence_number: non_neg_integer(),
          visibility: :public | :dm_only | :revealed,
          target_id: String.t(),
          target_name: String.t(),
          amount: non_neg_integer(),
          damage_type: atom(),
          new_hp: integer()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :target_id,
    :target_name,
    :amount,
    :damage_type,
    :new_hp,
    event_type: :damage_dealt,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
