defmodule Gibbering.Admin.UsersAdminTest do
  use Gibbering.DataCase, async: true

  import Gibbering.AccountsFixtures

  alias Gibbering.Admin
  alias Gibbering.Accounts

  defp create_actor do
    {:ok, actor} =
      Admin.create_support_user(%{
        email: "actor#{System.unique_integer([:positive])}@admin.local",
        password: "hunter2_admin",
        role: "moderator"
      })

    actor
  end

  describe "list_users/1" do
    test "returns all users" do
      user = register_user()
      users = Admin.list_users()
      assert Enum.any?(users, &(&1.id == user.id))
    end

    test "filters by username search" do
      unique = "findme#{System.unique_integer([:positive])}"
      user = register_user(%{"username" => unique})
      _other = register_user()

      users = Admin.list_users(search: unique)
      assert length(users) == 1
      assert hd(users).id == user.id
    end
  end

  describe "get_user_with_memberships/1" do
    test "returns user with campaign memberships preloaded" do
      user = register_user()
      result = Admin.get_user_with_memberships(user.id)
      assert result.id == user.id
      assert is_list(result.campaign_members)
    end

    test "returns nil for unknown id" do
      assert is_nil(Admin.get_user_with_memberships(0))
    end
  end

  describe "suspend_user/2" do
    test "sets suspended_at on the user" do
      actor = create_actor()
      user = register_user()

      assert {:ok, updated} = Admin.suspend_user(actor.id, user.id)
      assert updated.suspended_at != nil
    end

    test "logs the action to the audit log" do
      actor = create_actor()
      user = register_user()

      Admin.suspend_user(actor.id, user.id)
      logs = Admin.list_audit_log(actor_id: actor.id, action: "user.suspend")
      assert length(logs) == 1
      assert hd(logs).target_id == to_string(user.id)
    end

    test "suspended user cannot log in" do
      actor = create_actor()
      user = register_user(%{"username" => "tobanned", "password" => "password123"})
      Admin.suspend_user(actor.id, user.id)

      assert {:error, :suspended} = Accounts.authenticate_user("tobanned", "password123")
    end
  end

  describe "unsuspend_user/2" do
    test "clears suspended_at" do
      actor = create_actor()
      user = register_user()
      Admin.suspend_user(actor.id, user.id)

      assert {:ok, updated} = Admin.unsuspend_user(actor.id, user.id)
      assert is_nil(updated.suspended_at)
    end

    test "logs the action to the audit log" do
      actor = create_actor()
      user = register_user()
      Admin.suspend_user(actor.id, user.id)
      Admin.unsuspend_user(actor.id, user.id)

      logs = Admin.list_audit_log(actor_id: actor.id, action: "user.unsuspend")
      assert length(logs) == 1
      assert hd(logs).target_id == to_string(user.id)
    end
  end
end
