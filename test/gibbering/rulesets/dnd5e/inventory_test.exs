defmodule Gibbering.Rulesets.DnD5e.InventoryTest do
  use ExUnit.Case, async: true

  alias Gibbering.Rulesets.DnD5e.Inventory

  describe "item_instance/2" do
    test "builds an instance map with a generated UUID, item_key, and quantity" do
      instance = Inventory.item_instance("shortsword", 1)

      assert %{"instance_id" => id, "item_key" => "shortsword", "quantity" => 1} = instance
      assert is_binary(id)
      assert {:ok, _} = Ecto.UUID.cast(id)
    end

    test "defaults quantity to 1" do
      assert %{"item_key" => "healing_potion", "quantity" => 1} =
               Inventory.item_instance("healing_potion")
    end

    test "two instances of the same item_key get distinct instance_ids" do
      a = Inventory.item_instance("shortsword")
      b = Inventory.item_instance("shortsword")
      assert a["instance_id"] != b["instance_id"]
    end
  end

  describe "inventory/1 and items/1" do
    test "inventory/1 returns the creature's inventory list" do
      entity = %{stats: %{"inventory" => [%{"item_key" => "dagger", "quantity" => 1}]}}
      assert [%{"item_key" => "dagger"}] = Inventory.inventory(entity)
    end

    test "inventory/1 returns [] when the key is absent" do
      assert Inventory.inventory(%{stats: %{}}) == []
    end

    test "items/1 returns the container's item list" do
      entity = %{stats: %{"items" => [%{"item_key" => "shortsword", "quantity" => 1}]}}
      assert [%{"item_key" => "shortsword"}] = Inventory.items(entity)
    end

    test "items/1 returns [] when the key is absent" do
      assert Inventory.items(%{stats: %{}}) == []
    end
  end

  describe "object_subtype/1" do
    test "returns the object_subtype string from top-level key" do
      assert Inventory.object_subtype(%{object_subtype: "loot_source"}) == "loot_source"
    end

    test "returns nil when absent" do
      assert Inventory.object_subtype(%{}) == nil
    end
  end

  describe "loot_source?/1" do
    test "true for an object with object_subtype loot_source" do
      assert Inventory.loot_source?(%{type: "object", object_subtype: "loot_source"})
    end

    test "false for static_decor objects" do
      refute Inventory.loot_source?(%{type: "object", object_subtype: "static_decor"})
    end

    test "false for non-object entities" do
      refute Inventory.loot_source?(%{type: "hero", object_subtype: "loot_source"})
    end
  end

  describe "tag predicates" do
    test "interactable?/1 reflects the \"interactable\" tag" do
      assert Inventory.interactable?(%{tags: ["interactable", "passable"]})
      refute Inventory.interactable?(%{tags: ["blocking"]})
    end

    test "passable?/1 reflects the \"passable\" tag" do
      assert Inventory.passable?(%{tags: ["passable"]})
      refute Inventory.passable?(%{tags: ["blocking"]})
    end
  end
end
