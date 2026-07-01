defmodule Gibbering.Rulesets.DnD5e.Spell do
  @moduledoc """
  Runtime representation of an SRD spell.

  Drives targeting overlays, slot consumption, and concentration tracking.
  The `Catalogue.Spell` DB schema is the persistence layer; this struct is
  what the engine uses at resolution time.

  `casting_time` tagged tuples:
    {:action} | {:bonus_action} | {:reaction, trigger_pred} | {:minutes, n}

  `range`:
    {:feet, n} | :touch | :self

  `target_area.shape`:
    :point | :cone | :cube | :sphere | :cylinder | :line | :touch | :self

  `effect.attack_type`:
    :ranged_attack | :melee_attack | :save | :auto | :utility | :touch | :aoe
  """

  @enforce_keys [:key, :name, :level, :school, :casting_time, :range, :target_area, :effect]
  defstruct [
    :key,
    :name,
    :level,
    :school,
    :casting_time,
    :range,
    :target_area,
    :effect,
    components: [],
    duration: %{value: "instantaneous", is_concentration: false},
    tags: []
  ]

  @type casting_time ::
          {:action} | {:bonus_action} | {:reaction, term()} | {:minutes, pos_integer()}
  @type range :: {:feet, pos_integer()} | :touch | :self
  @type target_area :: %{shape: atom(), size: pos_integer() | nil}
  @type effect :: %{
          description: String.t(),
          damage_dice: String.t() | nil,
          damage_type: atom() | nil,
          attack_type: :ranged_attack | :melee_attack | :save | :auto | :utility | :touch | :aoe,
          save: atom() | nil
        }
  @type duration :: %{value: String.t(), is_concentration: boolean()}

  @type t :: %__MODULE__{
          key: atom(),
          name: String.t(),
          level: non_neg_integer(),
          school: atom(),
          casting_time: casting_time(),
          range: range(),
          target_area: target_area(),
          effect: effect(),
          components: [atom()],
          duration: duration(),
          tags: [String.t()]
        }
end
