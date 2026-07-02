defmodule GibberingTalesAdmin.Admin.AuditLogTest do
  use GibberingTalesAdmin.DataCase, async: true

  alias GibberingTalesAdmin.Admin
  alias GibberingTalesAdmin.Admin.AuditLog

  defp create_actor do
    {:ok, user} =
      Admin.create_support_user(%{
        email: "actor@admin.local",
        password: "hunter2_admin",
        role: "moderator"
      })

    user
  end

  describe "log_action/4" do
    test "inserts an audit log entry" do
      actor = create_actor()

      assert {:ok, %AuditLog{} = entry} =
               Admin.log_action(actor.id, "user.suspend", "user", "42")

      assert entry.actor_id == actor.id
      assert entry.action == "user.suspend"
      assert entry.target_type == "user"
      assert entry.target_id == "42"
      assert is_nil(entry.metadata) or is_map(entry.metadata)
    end

    test "accepts optional metadata map" do
      actor = create_actor()

      assert {:ok, entry} =
               Admin.log_action(actor.id, "campaign.force_close", "campaign", "7",
                 metadata: %{"reason" => "ToS violation"}
               )

      assert entry.metadata["reason"] == "ToS violation"
    end

    test "returns error for unknown actor_id" do
      assert {:error, _} = Admin.log_action(999_999, "user.suspend", "user", "1")
    end
  end

  describe "list_audit_log/1" do
    test "returns all entries in descending inserted_at order" do
      actor = create_actor()
      {:ok, _} = Admin.log_action(actor.id, "user.suspend", "user", "1")
      {:ok, _} = Admin.log_action(actor.id, "campaign.close", "campaign", "2")

      entries = Admin.list_audit_log()
      assert length(entries) >= 2
      [first | _] = entries
      assert %AuditLog{} = first
    end

    test "filters by actor_id" do
      actor = create_actor()

      {:ok, other} =
        Admin.create_support_user(%{
          email: "other@admin.local",
          password: "hunter2_admin",
          role: "viewer"
        })

      {:ok, _} = Admin.log_action(actor.id, "user.suspend", "user", "1")
      {:ok, _} = Admin.log_action(other.id, "user.verify", "user", "2")

      entries = Admin.list_audit_log(actor_id: actor.id)
      assert Enum.all?(entries, &(&1.actor_id == actor.id))
    end

    test "filters by action" do
      actor = create_actor()
      {:ok, _} = Admin.log_action(actor.id, "user.suspend", "user", "1")
      {:ok, _} = Admin.log_action(actor.id, "campaign.close", "campaign", "2")

      entries = Admin.list_audit_log(action: "user.suspend")
      assert Enum.all?(entries, &(&1.action == "user.suspend"))
    end
  end
end
