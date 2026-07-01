defmodule Gibbering.Engine.Inventory do
  @moduledoc """
  Pure inventory operations: opening containers, taking items, equipping items,
  and computing carry weight. No side effects — all functions take and return
  plain entity maps.
  """

  alias Gibbering.Data.Items
  alias Gibbering.Rulesets.DnD5e.Stats

  # ---------------------------------------------------------------------------
  # carry weight
  # ---------------------------------------------------------------------------

  @doc "Sums `weight_pounds * quantity` for all items in the entity's inventory."
  @spec compute_carry_weight(map()) :: float()
  def compute_carry_weight(entity) do
    inventory = get_in(entity, [:stats, "inventory"]) || []

    Enum.reduce(inventory, 0.0, fn instance, acc ->
      weight =
        case Items.get(instance["item_key"]) do
          nil -> 0
          item -> item.weight_pounds
        end

      acc + weight * instance["quantity"]
    end)
  end

  # ---------------------------------------------------------------------------
  # container access
  # ---------------------------------------------------------------------------

  @doc """
  Returns `:ok` if `actor` can open `container`, or `{:error, reason}` if not.

  Checks:
  - Chebyshev distance ≤ 1 (adjacent or diagonal).
  - Container's `object_subtype` is `"loot_source"`.
  """
  @spec can_open_container?(map(), map()) :: :ok | {:error, :not_adjacent | :not_a_container}
  def can_open_container?(actor, container) do
    cond do
      Map.get(container, :object_subtype) != "loot_source" ->
        {:error, :not_a_container}

      chebyshev(actor, container) > 1 ->
        {:error, :not_adjacent}

      true ->
        :ok
    end
  end

  # ---------------------------------------------------------------------------
  # take item
  # ---------------------------------------------------------------------------

  @doc """
  Moves `quantity` units of the item identified by `instance_id` from
  `container.stats["items"]` to `actor.stats["inventory"]`.

  Returns `{:ok, updated_actor, updated_container}` or `{:error, reason}`.

  Stacking rules:
  - Non-magical items with the same `item_key` are merged by accumulating quantity.
  - Magical items are kept as distinct instances regardless of key.

  Updates `actor.stats["carry_weight"]` after transfer.
  """
  @spec take_item(map(), map(), String.t(), pos_integer()) ::
          {:ok, map(), map()} | {:error, :item_not_found | :insufficient_quantity}
  def take_item(actor, container, instance_id, quantity) do
    items = get_in(container, [:stats, "items"]) || []

    case Enum.find(items, &(&1["instance_id"] == instance_id)) do
      nil ->
        {:error, :item_not_found}

      found ->
        if found["quantity"] < quantity do
          {:error, :insufficient_quantity}
        else
          remaining = found["quantity"] - quantity

          new_container_items =
            if remaining == 0 do
              Enum.reject(items, &(&1["instance_id"] == instance_id))
            else
              Enum.map(items, fn i ->
                if i["instance_id"] == instance_id, do: Map.put(i, "quantity", remaining), else: i
              end)
            end

          taken_instance = Map.put(found, "quantity", quantity)

          new_inventory =
            merge_into_inventory(get_in(actor, [:stats, "inventory"]) || [], taken_instance)

          new_actor =
            actor
            |> put_in([:stats, "inventory"], new_inventory)
            |> update_carry_weight()

          new_container = put_in(container, [:stats, "items"], new_container_items)

          {:ok, new_actor, new_container}
        end
    end
  end

  # ---------------------------------------------------------------------------
  # equip item
  # ---------------------------------------------------------------------------

  @doc """
  Equips the inventory item identified by `instance_id` on `actor`.

  Determines the slot from `Data.Items`:
  - `:weapon` → `stats["equipped_weapon"]`
  - `:armor`  → `stats["equipped_armor"]`

  If the slot is occupied, the old item is moved back into inventory first.
  Re-hydrates the entity via `DnD5e.Stats.hydrate_entity/1` after equipping.

  Returns `{:ok, updated_actor}` or `{:error, :item_not_found}`.
  """
  @spec equip_item(map(), String.t()) :: {:ok, map()} | {:error, :item_not_found}
  def equip_item(actor, instance_id) do
    inventory = get_in(actor, [:stats, "inventory"]) || []

    case Enum.find(inventory, &(&1["instance_id"] == instance_id)) do
      nil ->
        {:error, :item_not_found}

      instance ->
        item_key = instance["item_key"]
        item = Items.get(item_key)
        slot = slot_for(item)
        slot_map = build_slot_map(item_key, item)

        new_inventory =
          inventory
          |> Enum.reject(&(&1["instance_id"] == instance_id))
          |> maybe_return_old_equipped(actor, slot, item_key)

        new_actor =
          actor
          |> put_in([:stats, slot], slot_map)
          |> put_in([:stats, "inventory"], new_inventory)
          |> update_carry_weight()
          |> Stats.hydrate_entity()

        {:ok, new_actor}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp chebyshev(%{x: x1, y: y1}, %{x: x2, y: y2}), do: max(abs(x1 - x2), abs(y1 - y2))

  defp merge_into_inventory(inventory, instance) do
    key = instance["item_key"]
    magical = instance["is_magical"]

    stackable_idx =
      if magical do
        nil
      else
        Enum.find_index(inventory, fn i ->
          i["item_key"] == key && !i["is_magical"]
        end)
      end

    case stackable_idx do
      nil ->
        inventory ++ [instance]

      idx ->
        List.update_at(inventory, idx, fn existing ->
          Map.update!(existing, "quantity", &(&1 + instance["quantity"]))
        end)
    end
  end

  defp update_carry_weight(entity) do
    weight = compute_carry_weight(entity)
    put_in(entity, [:stats, "carry_weight"], weight)
  end

  defp slot_for(%{item_type: :weapon}), do: "equipped_weapon"
  defp slot_for(%{item_type: :armor}), do: "equipped_armor"

  defp build_slot_map(key, %{item_type: :weapon} = item) do
    %{
      "key" => key,
      "damage_dice" => item.damage_dice,
      "damage_type" => item.damage_type,
      "properties" => item.weapon_properties
    }
  end

  defp build_slot_map(key, %{item_type: :armor} = item) do
    %{
      "key" => key,
      "base_ac" => item.base_ac,
      "armor_category" => Atom.to_string(item.armor_category)
    }
  end

  defp maybe_return_old_equipped(inventory, actor, slot, new_key) do
    case get_in(actor, [:stats, slot]) do
      nil ->
        inventory

      %{"key" => ^new_key} ->
        inventory

      %{"key" => old_key} ->
        old_instance = %{
          "instance_id" => Ecto.UUID.generate(),
          "item_key" => old_key,
          "quantity" => 1,
          "is_magical" => false
        }

        inventory ++ [old_instance]

      _ ->
        inventory
    end
  end
end
