defmodule Gibbering.Admin.CampaignsAdminTest do
  use Gibbering.DataCase, async: true

  import Gibbering.AccountsFixtures
  import Gibbering.GameFixtures

  alias Gibbering.Admin
  alias Gibbering.Campaigns

  defp create_actor do
    {:ok, actor} =
      Admin.create_support_user(%{
        email: "actor#{System.unique_integer([:positive])}@admin.local",
        password: "hunter2_admin",
        role: "moderator"
      })

    actor
  end

  describe "list_all_campaigns/0" do
    test "returns all campaigns with member count" do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      Campaigns.join_campaign(campaign_id, user.id)

      campaigns = Admin.list_all_campaigns()
      assert Enum.any?(campaigns, &(&1.id == campaign_id))
    end
  end

  describe "get_campaign_with_members/1" do
    test "returns campaign with members preloaded" do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      Campaigns.join_campaign(campaign_id, user.id)

      result = Admin.get_campaign_with_members(campaign_id)
      assert result.id == campaign_id
      assert is_list(result.campaign_members)
    end

    test "returns nil for unknown id" do
      assert is_nil(Admin.get_campaign_with_members(0))
    end
  end

  describe "force_close_campaign/3" do
    test "sets campaign status to ended" do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      actor = create_actor()

      assert {:ok, campaign} =
               Admin.force_close_campaign(actor.id, campaign_id, "test closure")

      assert campaign.status == "ended"
    end

    test "logs the action to the audit log" do
      user = register_user()
      campaign_id = insert_campaign(%{dm_id: user.id})
      actor = create_actor()

      Admin.force_close_campaign(actor.id, campaign_id, "test closure")

      logs = Admin.list_audit_log(actor_id: actor.id, action: "campaign.force_close")
      assert length(logs) == 1

      entry = hd(logs)
      assert entry.target_id == to_string(campaign_id)
      assert entry.metadata["reason"] == "test closure"
    end

    test "returns error for unknown campaign" do
      actor = create_actor()
      assert {:error, :not_found} = Admin.force_close_campaign(actor.id, 0, "nope")
    end
  end
end
