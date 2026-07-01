defmodule Gibbering.AccountsTest do
  use Gibbering.DataCase, async: false

  alias Gibbering.Accounts
  alias Gibbering.AccountsFixtures

  describe "authenticate_user/2" do
    test "returns {:ok, user} for correct credentials" do
      attrs = AccountsFixtures.valid_user_attrs()
      {:ok, _} = Accounts.register_user(attrs)

      assert {:ok, user} = Accounts.authenticate_user(attrs["username"], attrs["password"])
      assert user.username == attrs["username"]
    end

    test "returns {:error, :invalid_credentials} for wrong password" do
      attrs = AccountsFixtures.valid_user_attrs()
      {:ok, _} = Accounts.register_user(attrs)

      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user(attrs["username"], "wrong_password")
    end

    test "returns {:error, :invalid_credentials} for unknown username" do
      assert {:error, :invalid_credentials} =
               Accounts.authenticate_user("nonexistent_user", "any_password")
    end
  end

  describe "get_user_by_id/1" do
    test "returns user struct for existing id" do
      user = AccountsFixtures.register_user()
      assert fetched = Accounts.get_user_by_id(user.id)
      assert fetched.id == user.id
      assert fetched.username == user.username
    end

    test "returns nil for unknown id" do
      assert Accounts.get_user_by_id(0) == nil
    end
  end

  describe "get_user_by_username/1" do
    test "returns user struct for existing username" do
      user = AccountsFixtures.register_user()
      assert fetched = Accounts.get_user_by_username(user.username)
      assert fetched.id == user.id
    end

    test "returns nil for unknown username" do
      assert Accounts.get_user_by_username("no_such_user") == nil
    end
  end
end
