defmodule GibberingEngine.HUD do
  @moduledoc """
  Pure data structs representing HUD state for a scene viewer.

  Defined in `gibbering_engine` as shared vocabulary — any game's web layer
  can render from the same struct shape. Population is the responsibility of
  a game-specific helper (`GibberingTalesWeb.HUD.build/2`), not the engine.

  Fields:
    - `action_bar` — buttons available to the active player this turn
    - `overlays`   — tile/entity highlights (move range, attack targets, etc.)
    - `prompts`    — blocking input requests (roll prompts, confirmations)
    - `status_strip` — per-entity status indicators (conditions, exhaustion, etc.)
  """

  defstruct action_bar: [], overlays: [], prompts: [], status_strip: []

  @type t :: %__MODULE__{
          action_bar: [Action.t()],
          overlays: [Overlay.t()],
          prompts: [Prompt.t()],
          status_strip: [StatusItem.t()]
        }
end

defmodule GibberingEngine.HUD.Action do
  @moduledoc "A single button in the action bar."

  defstruct [:label, :sublabel, :event, :value, enabled: true, selected: false]

  @type t :: %__MODULE__{
          label: String.t(),
          sublabel: String.t() | nil,
          event: String.t(),
          value: %{String.t() => String.t()},
          enabled: boolean(),
          selected: boolean()
        }
end

defmodule GibberingEngine.HUD.Overlay do
  @moduledoc """
  A visual highlight on the game map.

  Move overlays carry `{x, y}` grid coordinates and a kind of `:move_normal`
  or `:move_difficult`. Target overlays carry an `entity_id` and a kind of
  `:attack_target` or `:spell_target`; the template resolves the entity's
  tile position from the game state.
  """

  defstruct [:kind, :x, :y, :entity_id]

  @type kind :: :move_normal | :move_difficult | :attack_target | :spell_target

  @type t :: %__MODULE__{
          kind: kind(),
          x: integer() | nil,
          y: integer() | nil,
          entity_id: integer() | nil
        }
end

defmodule GibberingEngine.HUD.Prompt do
  @moduledoc "A blocking input request, e.g. a pending dice roll."

  defstruct [:entity_id, :roll_type, :context_label, :dice_expression]

  @type t :: %__MODULE__{
          entity_id: integer(),
          roll_type: atom(),
          context_label: String.t(),
          dice_expression: String.t()
        }
end

defmodule GibberingEngine.HUD.StatusItem do
  @moduledoc "A status indicator for a single entity (condition, exhaustion level, etc.)."

  defstruct [:entity_id, :condition_id, :label]

  @type t :: %__MODULE__{
          entity_id: integer(),
          condition_id: atom(),
          label: String.t()
        }
end
