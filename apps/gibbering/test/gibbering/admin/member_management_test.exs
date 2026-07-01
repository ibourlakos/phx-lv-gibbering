defmodule Gibbering.Admin.MemberManagementTest do
  use Gibbering.DataCase, async: true

  import GibberingTales.AccountsFixtures
  import Gibbering.GameFixtures

  alias Gibbering.Admin
  alias GibberingTales.Campaigns

  defp create_actor(role \\ "moderator") do
    {:ok, actor} =
      Admin.create_support_user(%{
        email: "actor#{System.unique_integer([:positive])}@admin.local",
        password: "hunter2_admin",
        role: role
      })

    actor
  end

  describe "remove_campaign_member/4" do
    test "removes the member from the campaign" do
      actor = create_actor()
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      assert Campaigns.member?(campaign_id, player.id)

      assert {:ok, _} =
               Admin.remove_campaign_member(actor.id, campaign_id, player.id, "disruptive")

      refute Campaigns.member?(campaign_id, player.id)
    end

    test "logs the action in the audit log" do
      actor = create_actor()
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      Admin.remove_campaign_member(actor.id, campaign_id, player.id, "disruptive")

      logs = Admin.list_audit_log(actor_id: actor.id, action: "campaign.remove_member")
      assert length(logs) == 1
      entry = hd(logs)
      assert entry.target_type == "campaign_member"
      assert entry.target_id == "#{campaign_id}:#{player.id}"
      assert entry.metadata["reason"] == "disruptive"
    end

    test "refuses to remove the DM" do
      actor = create_actor()
      dm = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, dm.id)

      assert {:error, :cannot_remove_dm} =
               Admin.remove_campaign_member(actor.id, campaign_id, dm.id, "test")
    end

    test "refuses for viewer role" do
      actor = create_actor("viewer")
      dm = register_user()
      player = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})
      Campaigns.join_campaign(campaign_id, player.id)

      assert {:error, :forbidden} =
               Admin.remove_campaign_member(actor.id, campaign_id, player.id, "nope")
    end

    test "returns error when member not found" do
      actor = create_actor()
      dm = register_user()
      campaign_id = insert_campaign(%{dm_id: dm.id})

      assert {:error, :not_a_member} =
               Admin.remove_campaign_member(actor.id, campaign_id, 0, "nope")
    end
  end
end
