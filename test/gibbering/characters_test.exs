defmodule Gibbering.CharactersTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.Characters

  import Gibbering.AccountsFixtures
  import Gibbering.CharactersFixtures

  describe "create_character/2" do
    test "creates a character with valid attributes" do
      user = register_user()
      attrs = valid_character_attrs()

      assert {:ok, character} = Characters.create_character(user.id, attrs)
      assert character.name == attrs["name"]
      assert character.race == attrs["race"]
      assert character.class == attrs["class"]
      assert character.user_id == user.id
    end

    test "sets default level to 1 when not specified" do
      user = register_user()
      {:ok, character} = Characters.create_character(user.id, valid_character_attrs())
      assert character.level == 1
    end

    test "returns error changeset when name is missing" do
      user = register_user()

      assert {:error, changeset} =
               Characters.create_character(user.id, valid_character_attrs(%{"name" => ""}))

      assert errors_on(changeset).name
    end

    test "returns error changeset for an invalid race" do
      user = register_user()

      assert {:error, changeset} =
               Characters.create_character(user.id, valid_character_attrs(%{"race" => "orc"}))

      assert errors_on(changeset).race
    end

    test "returns error changeset for an invalid class" do
      user = register_user()

      assert {:error, changeset} =
               Characters.create_character(
                 user.id,
                 valid_character_attrs(%{"class" => "necromancer"})
               )

      assert errors_on(changeset).class
    end

    test "stores appearance as a map" do
      user = register_user()

      attrs =
        valid_character_attrs(%{
          "appearance" => %{"body_type" => "medium", "hair_color" => "brown"}
        })

      {:ok, character} = Characters.create_character(user.id, attrs)
      assert character.appearance["body_type"] == "medium"
    end

    test "stores life_events as a list of maps" do
      user = register_user()

      event = %{"era" => "childhood", "type" => "loss", "title" => "The fire"}

      attrs = valid_character_attrs(%{"life_events" => [event]})
      {:ok, character} = Characters.create_character(user.id, attrs)
      assert [stored] = character.life_events
      assert stored["title"] == "The fire"
    end
  end

  describe "list_for_user/1" do
    test "returns only characters belonging to the given user" do
      user1 = register_user()
      user2 = register_user()

      char1 = create_character(user1)
      _char2 = create_character(user2)

      result = Characters.list_for_user(user1.id)
      assert length(result) == 1
      assert hd(result).id == char1.id
    end

    test "returns an empty list when the user has no characters" do
      user = register_user()
      assert Characters.list_for_user(user.id) == []
    end

    test "returns multiple characters ordered by name" do
      user = register_user()
      create_character(user, %{"name" => "Zzarith"})
      create_character(user, %{"name" => "Aelindra"})

      [first, second] = Characters.list_for_user(user.id)
      assert first.name == "Aelindra"
      assert second.name == "Zzarith"
    end
  end

  describe "get_character!/2" do
    test "returns the character for its owner" do
      user = register_user()
      char = create_character(user)

      found = Characters.get_character!(user.id, char.id)
      assert found.id == char.id
    end

    test "raises Ecto.NoResultsError when the character belongs to another user" do
      user1 = register_user()
      user2 = register_user()
      char = create_character(user1)

      assert_raise Ecto.NoResultsError, fn ->
        Characters.get_character!(user2.id, char.id)
      end
    end

    test "raises Ecto.NoResultsError when the character does not exist" do
      user = register_user()

      assert_raise Ecto.NoResultsError, fn ->
        Characters.get_character!(user.id, 999_999)
      end
    end
  end

  describe "update_character/2" do
    test "updates the character with valid attributes" do
      user = register_user()
      char = create_character(user)

      assert {:ok, updated} = Characters.update_character(char, %{"name" => "Renamed Hero"})
      assert updated.name == "Renamed Hero"
    end

    test "returns error changeset for invalid updates" do
      user = register_user()
      char = create_character(user)

      assert {:error, changeset} = Characters.update_character(char, %{"name" => ""})
      assert errors_on(changeset).name
    end
  end

  describe "delete_character/2" do
    test "deletes the character for the owner" do
      user = register_user()
      char = create_character(user)

      assert {:ok, _} = Characters.delete_character(user.id, char.id)
      assert Characters.list_for_user(user.id) == []
    end

    test "raises when attempting to delete another user's character" do
      user1 = register_user()
      user2 = register_user()
      char = create_character(user1)

      assert_raise Ecto.NoResultsError, fn ->
        Characters.delete_character(user2.id, char.id)
      end
    end
  end
end
