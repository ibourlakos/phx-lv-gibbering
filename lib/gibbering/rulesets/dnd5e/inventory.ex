defmodule Gibbering.Rulesets.DnD5e.Inventory do
  @moduledoc """
  Item-instance shape and accessors for creature inventories and loot containers.

  Items live in the entity `stats` JSONB map as uniform instance lists
  (see `docs/architecture/data-model.md`, WorldObject section):

  - Creatures (`"hero"`, `"monster"`) carry `stats["inventory"]`.
  - Loot containers (`type: "object"`, `object_subtype == "loot_source"`)
    hold `stats["items"]`.

  Both lists share one instance shape:

      %{"instance_id" => uuid_string, "item_key" => string, "quantity" => integer}

  `item_key` references a key in `Gibbering.Data.Items`. Stack-merge and transfer
  logic belong to the pickup event loop (#127); this module only defines the shape
  and read accessors.

  `object_subtype` is a top-level key in the engine entity map, populated at scene load
  from the entity's `EntityPreset` record. It is not read from `stats` at runtime.
  """

  @doc """
  Build a fresh item instance with a generated UUID. Quantity defaults to 1.
  """
  @spec item_instance(String.t(), pos_integer()) :: map()
  def item_instance(item_key, quantity \\ 1) when is_binary(item_key) do
    %{
      "instance_id" => Ecto.UUID.generate(),
      "item_key" => item_key,
      "quantity" => quantity
    }
  end

  @doc "A creature's inventory list, or `[]` when absent."
  @spec inventory(map()) :: [map()]
  def inventory(entity), do: get_in(entity, [Access.key(:stats), "inventory"]) || []

  @doc "A container's item list, or `[]` when absent."
  @spec items(map()) :: [map()]
  def items(entity), do: get_in(entity, [Access.key(:stats), "items"]) || []

  @doc "The `object_subtype` value (`\"loot_source\" | \"static_decor\"`), or nil. Populated from EntityPreset at scene load."
  @spec object_subtype(map()) :: String.t() | nil
  def object_subtype(entity), do: Map.get(entity, :object_subtype)

  @doc "True when the entity is an `object` whose sub-type is `loot_source`."
  @spec loot_source?(map()) :: boolean()
  def loot_source?(%{type: "object"} = entity), do: object_subtype(entity) == "loot_source"
  def loot_source?(_entity), do: false

  @doc "True when the entity carries the canonical `\"interactable\"` tag."
  @spec interactable?(map()) :: boolean()
  def interactable?(entity), do: "interactable" in Map.get(entity, :tags, [])

  @doc "True when the entity carries the canonical `\"passable\"` tag."
  @spec passable?(map()) :: boolean()
  def passable?(entity), do: "passable" in Map.get(entity, :tags, [])
end
