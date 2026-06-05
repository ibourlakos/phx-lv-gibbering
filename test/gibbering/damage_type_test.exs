defmodule Gibbering.DamageTypeTest do
  use ExUnit.Case, async: true

  alias Gibbering.DamageType

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
  end
end
