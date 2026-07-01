defmodule Gibbering.Events.DnD5e.SpellCast do
  @moduledoc """
  Layer: D&D 5e ruleset.
  Emitted by: SceneServer (via DnD5e ruleset), when a caster successfully casts a spell.
  Signals: caster cast spell_key at target (may be nil for self/area spells); outcome
  is a ruleset-defined atom (e.g. :hit, :miss, :saved). Spells are a D&D 5e SRD concept.
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
          caster_id: String.t(),
          caster_name: String.t(),
          spell_key: atom(),
          target_id: String.t() | nil,
          target_name: String.t() | nil,
          outcome: atom()
        }

  defstruct [
    :event_id,
    :occurred_at,
    :correlation_id,
    :causation_id,
    :sequence_number,
    :caster_id,
    :caster_name,
    :spell_key,
    :target_id,
    :target_name,
    :outcome,
    event_type: :spell_cast,
    schema_version: @current_version,
    visibility: :public
  ]

  @impl GibberingEngine.Events.Upcaster
  def current_version, do: @current_version

  @impl GibberingEngine.Events.Upcaster
  def upcast(_from_version, raw_map), do: raw_map
end
