defmodule Gibbering.Admin.CharactersAdminTest do
  use Gibbering.DataCase, async: true

  import Gibbering.AccountsFixtures
  import Gibbering.CharactersFixtures

  alias Gibbering.Admin

  describe "list_characters_for_admin/1" do
    test "returns all characters with user preloaded" do
      user = register_user()
      char = create_character(user)
      results = Admin.list_characters_for_admin()
      assert Enum.any?(results, &(&1.id == char.id))
      assert Enum.all?(results, &(not is_nil(&1.user)))
    end

    test "searches by character name (case-insensitive)" do
      user = register_user()
      suffix = System.unique_integer([:positive])
      char = create_character(user, %{"name" => "Zyraxel#{suffix}"})
      _other = create_character(user, %{"name" => "Aldric#{suffix}"})
      results = Admin.list_characters_for_admin(search: "zyraxel#{suffix}")
      assert length(results) == 1
      assert hd(results).id == char.id
    end

    test "searches by owner username (case-insensitive)" do
      suffix = System.unique_integer([:positive])
      user = register_user(%{"username" => "findme#{suffix}"})
      char = create_character(user)
      _other = register_user()
      results = Admin.list_characters_for_admin(search: "FINDME#{suffix}")
      assert length(results) == 1
      assert hd(results).id == char.id
    end

    test "returns empty list when no match" do
      results = Admin.list_characters_for_admin(search: "zzz_no_match_#{System.unique_integer()}")
      assert results == []
    end
  end

  describe "get_character_for_admin!/1" do
    test "returns character with user preloaded" do
      user = register_user()
      char = create_character(user)
      result = Admin.get_character_for_admin!(char.id)
      assert result.id == char.id
      assert result.user.id == user.id
    end

    test "preloads user campaign memberships" do
      user = register_user()
      char = create_character(user)
      result = Admin.get_character_for_admin!(char.id)
      assert is_list(result.user.campaign_members)
    end

    test "raises on unknown id" do
      assert_raise Ecto.NoResultsError, fn -> Admin.get_character_for_admin!(0) end
    end
  end
end
