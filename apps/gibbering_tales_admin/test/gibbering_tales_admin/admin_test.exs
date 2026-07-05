defmodule Gibbering.AdminTest do
  use GibberingTalesAdmin.DataCase, async: true

  alias GibberingTalesAdmin.Admin
  alias GibberingTalesAdmin.Admin.SupportUser

  defp create_support_user(attrs \\ %{}) do
    defaults = %{email: "test@admin.local", password: "hunter2_admin", role: "viewer"}
    {:ok, user} = Admin.create_support_user(Map.merge(defaults, attrs))
    user
  end

  describe "create_support_user/1" do
    test "inserts a support user with hashed password" do
      assert {:ok, %SupportUser{} = user} =
               Admin.create_support_user(%{
                 email: "new@admin.local",
                 password: "secure_pass_1",
                 role: "moderator"
               })

      assert user.email == "new@admin.local"
      assert user.role == "moderator"
      refute is_nil(user.hashed_password)
    end

    test "rejects invalid role" do
      assert {:error, changeset} =
               Admin.create_support_user(%{
                 email: "x@admin.local",
                 password: "secure_pass_1",
                 role: "superuser"
               })

      assert %{role: [_]} = errors_on(changeset)
    end

    test "rejects short password" do
      assert {:error, changeset} =
               Admin.create_support_user(%{
                 email: "x@admin.local",
                 password: "short",
                 role: "viewer"
               })

      assert %{password: [_]} = errors_on(changeset)
    end

    test "rejects duplicate email" do
      create_support_user()

      assert {:error, changeset} =
               Admin.create_support_user(%{
                 email: "test@admin.local",
                 password: "hunter2_admin",
                 role: "viewer"
               })

      assert %{email: [_]} = errors_on(changeset)
    end
  end

  describe "authenticate_support_user/2" do
    test "returns ok with correct credentials" do
      create_support_user()

      assert {:ok, %SupportUser{}} =
               Admin.authenticate_support_user("test@admin.local", "hunter2_admin")
    end

    test "returns error with wrong password" do
      create_support_user()

      assert {:error, :invalid_credentials} =
               Admin.authenticate_support_user("test@admin.local", "wrongpass")
    end

    test "returns error for unknown email" do
      assert {:error, :invalid_credentials} =
               Admin.authenticate_support_user("nobody@admin.local", "anything")
    end
  end

  describe "get_support_user_by_id/1" do
    test "returns the user for a known id" do
      user = create_support_user()
      assert %SupportUser{id: id} = Admin.get_support_user_by_id(user.id)
      assert id == user.id
    end

    test "returns nil for unknown id" do
      assert is_nil(Admin.get_support_user_by_id(999_999))
    end
  end

  describe "change_support_user/2" do
    test "returns a changeset" do
      user = create_support_user()
      assert %Ecto.Changeset{} = Admin.change_support_user(user, %{role: "editor"})
    end
  end
end
