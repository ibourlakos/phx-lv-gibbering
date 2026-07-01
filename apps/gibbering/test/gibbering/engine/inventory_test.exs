defmodule Gibbering.Engine.InventoryTest do
  use ExUnit.Case, async: true

  alias Gibbering.Engine.Inventory

  defp actor(overrides \\ []) do
    base = %{
      x: 2,
      y: 2,
      level: 1,
      stats: %{
        "strength" => 10,
        "dexterity" => 10,
        "constitution" => 10,
        "intelligence" => 10,
        "wisdom" => 10,
        "charisma" => 10,
        "inventory" => [],
        "carry_weight" => 0.0
      }
    }

    Enum.reduce(overrides, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp container(overrides \\ []) do
    base = %{
      x: 3,
      y: 2,
      object_subtype: "loot_source",
      stats: %{
        "items" => []
      }
    }

    Enum.reduce(overrides, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  defp instance(overrides \\ []) do
    base = %{
      "instance_id" => "inst-001",
      "item_key" => "dagger",
      "quantity" => 1,
      "is_magical" => false
    }

    Enum.reduce(overrides, base, fn {k, v}, acc -> Map.put(acc, k, v) end)
  end

  # ---------------------------------------------------------------------------
  # compute_carry_weight/1
  # ---------------------------------------------------------------------------

  describe "compute_carry_weight/1" do
    test "returns 0.0 for entity with empty inventory" do
      assert Inventory.compute_carry_weight(actor()) == 0.0
    end

    test "sums weight * quantity for inventory items" do
      # dagger = 1 lb, quantity 2 → 2 lbs
      inv = [instance(%{"item_key" => "dagger", "quantity" => 2})]
      e = actor(stats: %{"inventory" => inv, "carry_weight" => 0.0})
      assert Inventory.compute_carry_weight(e) == 2.0
    end

    test "sums multiple distinct items" do
      # dagger (1 lb × 1) + longsword (3 lb × 1) = 4 lbs
      inv = [
        instance(%{"instance_id" => "a", "item_key" => "dagger", "quantity" => 1}),
        instance(%{"instance_id" => "b", "item_key" => "longsword", "quantity" => 1})
      ]

      e = actor(stats: %{"inventory" => inv, "carry_weight" => 0.0})
      assert Inventory.compute_carry_weight(e) == 4.0
    end

    test "unknown item key contributes 0 weight" do
      inv = [instance(%{"item_key" => "vorpal_blade", "quantity" => 1})]
      e = actor(stats: %{"inventory" => inv, "carry_weight" => 0.0})
      assert Inventory.compute_carry_weight(e) == 0.0
    end
  end

  # ---------------------------------------------------------------------------
  # can_open_container?/2
  # ---------------------------------------------------------------------------

  describe "can_open_container?/2" do
    test "ok when actor is adjacent (Chebyshev 1)" do
      a = actor(x: 2, y: 2)
      c = container(x: 3, y: 2)
      assert Inventory.can_open_container?(a, c) == :ok
    end

    test "ok when actor is diagonally adjacent (Chebyshev 1)" do
      a = actor(x: 2, y: 2)
      c = container(x: 3, y: 3)
      assert Inventory.can_open_container?(a, c) == :ok
    end

    test "error :not_adjacent when too far" do
      a = actor(x: 0, y: 0)
      c = container(x: 3, y: 0)
      assert Inventory.can_open_container?(a, c) == {:error, :not_adjacent}
    end

    test "error :not_a_container when object_subtype is not loot_source" do
      a = actor(x: 2, y: 2)
      c = container(x: 3, y: 2, object_subtype: "static_decor")
      assert Inventory.can_open_container?(a, c) == {:error, :not_a_container}
    end

    test "error :not_a_container when object_subtype is absent" do
      a = actor(x: 2, y: 2)
      c = container(x: 3, y: 2, object_subtype: nil)
      assert Inventory.can_open_container?(a, c) == {:error, :not_a_container}
    end
  end

  # ---------------------------------------------------------------------------
  # take_item/4
  # ---------------------------------------------------------------------------

  describe "take_item/4" do
    test "moves quantity from container to actor inventory" do
      item = instance(%{"instance_id" => "i1", "item_key" => "dagger", "quantity" => 1})
      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor()

      {:ok, new_actor, new_container} = Inventory.take_item(a, c, "i1", 1)

      assert length(new_actor.stats["inventory"]) == 1
      assert hd(new_actor.stats["inventory"])["item_key"] == "dagger"
      assert new_container.stats["items"] == []
    end

    test "partial take leaves remaining quantity in container" do
      item = instance(%{"instance_id" => "i1", "quantity" => 3})
      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor()

      {:ok, new_actor, new_container} = Inventory.take_item(a, c, "i1", 2)

      assert hd(new_actor.stats["inventory"])["quantity"] == 2
      assert hd(new_container.stats["items"])["quantity"] == 1
    end

    test "merges stackable items by quantity (same non-magical key)" do
      item =
        instance(%{
          "instance_id" => "i1",
          "item_key" => "dagger",
          "quantity" => 1,
          "is_magical" => false
        })

      existing =
        instance(%{
          "instance_id" => "e1",
          "item_key" => "dagger",
          "quantity" => 2,
          "is_magical" => false
        })

      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor(stats: %{"inventory" => [existing], "carry_weight" => 0.0})

      {:ok, new_actor, _} = Inventory.take_item(a, c, "i1", 1)

      inv = new_actor.stats["inventory"]
      assert length(inv) == 1
      assert hd(inv)["quantity"] == 3
    end

    test "magical items are kept as distinct instances" do
      item =
        instance(%{
          "instance_id" => "i1",
          "item_key" => "dagger",
          "quantity" => 1,
          "is_magical" => true
        })

      existing =
        instance(%{
          "instance_id" => "e1",
          "item_key" => "dagger",
          "quantity" => 1,
          "is_magical" => true
        })

      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor(stats: %{"inventory" => [existing], "carry_weight" => 0.0})

      {:ok, new_actor, _} = Inventory.take_item(a, c, "i1", 1)

      assert length(new_actor.stats["inventory"]) == 2
    end

    test "updates carry_weight on actor after transfer" do
      # dagger = 1 lb
      item = instance(%{"instance_id" => "i1", "item_key" => "dagger", "quantity" => 1})
      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor()

      {:ok, new_actor, _} = Inventory.take_item(a, c, "i1", 1)

      assert new_actor.stats["carry_weight"] == 1.0
    end

    test "error :item_not_found when instance_id does not exist" do
      c = container()
      a = actor()
      assert Inventory.take_item(a, c, "ghost", 1) == {:error, :item_not_found}
    end

    test "error :insufficient_quantity when requesting more than available" do
      item = instance(%{"instance_id" => "i1", "quantity" => 1})
      c = container(stats: %{"object_subtype" => "loot_source", "items" => [item]})
      a = actor()
      assert Inventory.take_item(a, c, "i1", 5) == {:error, :insufficient_quantity}
    end
  end

  # ---------------------------------------------------------------------------
  # equip_item/2
  # ---------------------------------------------------------------------------

  describe "equip_item/2" do
    test "weapon moves from inventory to equipped_weapon slot" do
      inst = instance(%{"instance_id" => "i1", "item_key" => "longsword", "quantity" => 1})
      a = actor(stats: %{"inventory" => [inst], "carry_weight" => 0.0})

      {:ok, new_actor} = Inventory.equip_item(a, "i1")

      assert new_actor.stats["equipped_weapon"]["key"] == "longsword"
      assert new_actor.stats["inventory"] == []
    end

    test "armor moves from inventory to equipped_armor slot" do
      inst = instance(%{"instance_id" => "i1", "item_key" => "chain_mail", "quantity" => 1})
      a = actor(stats: %{"inventory" => [inst], "carry_weight" => 0.0})

      {:ok, new_actor} = Inventory.equip_item(a, "i1")

      assert new_actor.stats["equipped_armor"]["key"] == "chain_mail"
      assert new_actor.stats["inventory"] == []
    end

    test "equipping armor stores base_ac and armor_category for Stats.armor_class" do
      inst = instance(%{"instance_id" => "i1", "item_key" => "chain_mail", "quantity" => 1})
      a = actor(stats: %{"inventory" => [inst], "carry_weight" => 0.0})

      {:ok, new_actor} = Inventory.equip_item(a, "i1")

      slot = new_actor.stats["equipped_armor"]
      assert slot["base_ac"] == 16
      assert slot["armor_category"] == "heavy"
    end

    test "equipping weapon stores damage_dice for Rules.roll_damage" do
      inst = instance(%{"instance_id" => "i1", "item_key" => "greatsword", "quantity" => 1})
      a = actor(stats: %{"inventory" => [inst], "carry_weight" => 0.0})

      {:ok, new_actor} = Inventory.equip_item(a, "i1")

      assert new_actor.stats["equipped_weapon"]["damage_dice"] == "2d6"
    end

    test "old equipped weapon returns to inventory when replaced" do
      old_inst = instance(%{"instance_id" => "old", "item_key" => "dagger", "quantity" => 1})
      new_inst = instance(%{"instance_id" => "new", "item_key" => "longsword", "quantity" => 1})

      a =
        actor(
          stats: %{
            "inventory" => [new_inst],
            "equipped_weapon" => %{"key" => "dagger"},
            "carry_weight" => 0.0
          }
        )

      {:ok, new_actor} = Inventory.equip_item(a, "new")

      assert new_actor.stats["equipped_weapon"]["key"] == "longsword"
      inv_keys = Enum.map(new_actor.stats["inventory"], & &1["item_key"])
      assert "dagger" in inv_keys
    end

    test "error :item_not_found when instance_id is not in inventory" do
      a = actor()
      assert Inventory.equip_item(a, "ghost") == {:error, :item_not_found}
    end
  end
end
