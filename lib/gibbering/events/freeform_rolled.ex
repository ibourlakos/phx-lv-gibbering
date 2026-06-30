defmodule Gibbering.Events.FreeformRolled do
  @moduledoc false

  # Broadcast directly on the scene topic by GameLive (not via SceneServer).
  # Not persisted — freeform rolls don't affect game state.

  @type die_type :: String.t()

  @type t :: %__MODULE__{
          roller_name: String.t(),
          dice_map: %{die_type() => pos_integer()},
          results: %{die_type() => [pos_integer()]},
          total: non_neg_integer()
        }

  defstruct [:roller_name, :dice_map, :results, :total]
end
