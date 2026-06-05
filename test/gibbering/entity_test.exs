defmodule Gibbering.EntityTest do
  use ExUnit.Case, async: true

  import Gibbering.DataCase, only: [errors_on: 1]

  alias Gibbering.Entity

  @valid_attrs %{
    name: "Aldric",
    type: "hero",
    sprite: "human_fighter",
    race: "human",
    class: "fighter",
    x: 1,
    y: 1,
    hp: 30,
    max_hp: 30,
    campaign_id: 1
  }

  describe "level field" do
    test "defaults to 1" do
      changeset = Entity.changeset(%Entity{}, @valid_attrs)
      assert changeset.valid?
      entity = Ecto.Changeset.apply_changes(changeset)
      assert entity.level == 1
    end

    test "accepts explicit level" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :level, 5))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :level) == 5
    end

    test "rejects level below 1" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :level, 0))
      assert "must be greater than or equal to 1" in errors_on(changeset).level
    end

    test "rejects level above 20" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :level, 21))
      assert "must be less than or equal to 20" in errors_on(changeset).level
    end
  end

  describe "temp_hp field" do
    test "defaults to 0" do
      changeset = Entity.changeset(%Entity{}, @valid_attrs)
      assert changeset.valid?
      entity = Ecto.Changeset.apply_changes(changeset)
      assert entity.temp_hp == 0
    end

    test "accepts positive temp_hp" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :temp_hp, 10))
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :temp_hp) == 10
    end

    test "rejects negative temp_hp" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :temp_hp, -1))
      assert "must be greater than or equal to 0" in errors_on(changeset).temp_hp
    end
  end

  describe "challenge_rating field (monster-specific, nullable)" do
    test "is nil by default" do
      changeset = Entity.changeset(%Entity{}, @valid_attrs)
      assert changeset.valid?
      entity = Ecto.Changeset.apply_changes(changeset)
      assert is_nil(entity.challenge_rating)
    end

    test "accepts a CR value for monsters" do
      attrs = Map.merge(@valid_attrs, %{type: "monster", challenge_rating: Decimal.new("0.25")})
      changeset = Entity.changeset(%Entity{}, attrs)
      assert changeset.valid?
    end
  end

  describe "xp_reward field (monster-specific, nullable)" do
    test "is nil by default" do
      changeset = Entity.changeset(%Entity{}, @valid_attrs)
      entity = Ecto.Changeset.apply_changes(changeset)
      assert is_nil(entity.xp_reward)
    end

    test "accepts xp_reward for monsters" do
      attrs = Map.merge(@valid_attrs, %{type: "monster", xp_reward: 200})
      changeset = Entity.changeset(%Entity{}, attrs)
      assert changeset.valid?
    end

    test "rejects negative xp_reward" do
      changeset = Entity.changeset(%Entity{}, Map.put(@valid_attrs, :xp_reward, -10))
      assert "must be greater than or equal to 0" in errors_on(changeset).xp_reward
    end
  end
end
