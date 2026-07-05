defmodule GibberingTales.Pipeline.LegalGuardTest do
  use ExUnit.Case, async: true

  alias GibberingTales.Pipeline.LegalGuard

  describe "check/1" do
    test "allows SRD creature names" do
      for name <- ["Goblin", "Aboleth", "Ancient Red Dragon", "Ogre", "Troll", "Lich"] do
        assert :ok = LegalGuard.check(name)
      end
    end

    test "blocks WotC setting names" do
      assert {:error, _} = LegalGuard.check("Forgotten Realms")
      assert {:error, _} = LegalGuard.check("Dragonlance")
      assert {:error, _} = LegalGuard.check("Eberron Warforged")
      assert {:error, _} = LegalGuard.check("Greyhawk Wizard")
    end

    test "blocks named PI characters" do
      assert {:error, _} = LegalGuard.check("Drizzt Do'Urden")
      assert {:error, _} = LegalGuard.check("Elminster")
      assert {:error, _} = LegalGuard.check("Mordenkainen's Faithful Hound")
      assert {:error, _} = LegalGuard.check("Strahd von Zarovich")
    end

    test "is case-insensitive" do
      assert {:error, _} = LegalGuard.check("FORGOTTEN REALMS")
      assert {:error, _} = LegalGuard.check("forgotten realms")
    end
  end

  describe "safe?/1" do
    test "returns true for safe names" do
      assert LegalGuard.safe?("Goblin")
      assert LegalGuard.safe?("Ancient Red Dragon")
    end

    test "returns false for PI names" do
      refute LegalGuard.safe?("Dragonlance Paladin")
      refute LegalGuard.safe?("Elminster")
    end
  end
end
