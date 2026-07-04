defmodule GibberingTales.DamageTypeTest do
  use ExUnit.Case, async: true

  alias GibberingTales.DamageType

  @srd_types ~w(acid bludgeoning cold fire force lightning necrotic piercing
                poison psychic radiant slashing thunder)

  describe "cast/1" do
    test "accepts all SRD core damage types" do
      for type <- @srd_types do
        assert {:ok, atom} = DamageType.cast(type)
        assert is_atom(atom)
      end
    end

    test "returns error for unknown type strings" do
      assert {:error, :unknown} = DamageType.cast("holy")
      assert {:error, :unknown} = DamageType.cast("shadow")
      assert {:error, :unknown} = DamageType.cast("FIRE")
      assert {:error, :unknown} = DamageType.cast("")
    end

    test "does not intern an atom for unknown input" do
      unique = "unknown_damage_type_#{System.unique_integer([:positive])}"

      assert {:error, :unknown} = DamageType.cast(unique)
      assert_raise ArgumentError, fn -> String.to_existing_atom(unique) end
    end
  end

  describe "all/0" do
    test "returns all 13 SRD damage type atoms" do
      all = DamageType.all()
      assert length(all) == 13
      assert Enum.all?(all, &is_atom/1)

      for type <- @srd_types do
        assert String.to_atom(type) in all
      end
    end
  end
end
