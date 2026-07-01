defmodule Gibbering.CampaignInviteLinksTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.{CampaignInviteLinks, Campaigns}
  alias Gibbering.AccountsFixtures
  alias Gibbering.GameFixtures

  setup do
    dm = AccountsFixtures.register_user()
    player = AccountsFixtures.register_user()
    campaign_id = GameFixtures.insert_campaign()
    {:ok, _} = Campaigns.join_campaign(campaign_id, dm.id)
    %{dm: dm, player: player, campaign_id: campaign_id}
  end

  describe "create_for_campaign/2" do
    test "creates an invite link with a token, expiry, and unlimited uses by default", ctx do
      assert {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      assert link.campaign_id == ctx.campaign_id
      assert link.created_by_id == ctx.dm.id
      assert is_binary(link.token) and byte_size(link.token) > 0
      assert %DateTime{} = link.expires_at
      assert link.uses_remaining == nil
      assert link.revoked == false
    end
  end

  describe "get_by_token/1" do
    test "returns {:ok, link} for a valid active token", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      assert {:ok, fetched} = CampaignInviteLinks.get_by_token(link.token)
      assert fetched.id == link.id
    end

    test "returns {:error, :not_found} for unknown token", _ctx do
      assert {:error, :not_found} = CampaignInviteLinks.get_by_token("nonexistent_token")
    end

    test "returns {:error, :expired} for an expired token", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      past = DateTime.utc_now() |> DateTime.add(-1, :second) |> DateTime.truncate(:second)
      Gibbering.Repo.update!(Ecto.Changeset.change(link, expires_at: past))

      assert {:error, :expired} = CampaignInviteLinks.get_by_token(link.token)
    end

    test "returns {:error, :revoked} for a revoked token", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      {:ok, _} = CampaignInviteLinks.revoke(link)

      assert {:error, :revoked} = CampaignInviteLinks.get_by_token(link.token)
    end
  end

  describe "redeem/2" do
    test "creates membership and returns :ok for a valid link", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      assert {:ok, _} = CampaignInviteLinks.redeem(link, ctx.player.id)
      assert Campaigns.member?(ctx.campaign_id, ctx.player.id)
    end

    test "is idempotent when user is already a member", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      {:ok, _} = CampaignInviteLinks.redeem(link, ctx.player.id)
      assert {:ok, _} = CampaignInviteLinks.redeem(link, ctx.player.id)
    end

    test "decrements uses_remaining when it is set", ctx do
      {:ok, link} =
        CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id, uses_remaining: 3)

      {:ok, updated} = CampaignInviteLinks.redeem(link, ctx.player.id)
      assert updated.uses_remaining == 2
    end

    test "returns {:error, :uses_exhausted} when uses_remaining reaches 0", ctx do
      other_user = AccountsFixtures.register_user()

      {:ok, link} =
        CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id, uses_remaining: 1)

      {:ok, _} = CampaignInviteLinks.redeem(link, ctx.player.id)
      link = Gibbering.Repo.get!(Gibbering.CampaignInviteLink, link.id)
      assert {:error, :uses_exhausted} = CampaignInviteLinks.redeem(link, other_user.id)
    end
  end

  describe "revoke/1" do
    test "marks the link as revoked", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      {:ok, revoked} = CampaignInviteLinks.revoke(link)
      assert revoked.revoked == true
    end
  end

  describe "active_for_campaign/1" do
    test "returns active link if one exists", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      assert {:ok, active} = CampaignInviteLinks.active_for_campaign(ctx.campaign_id)
      assert active.id == link.id
    end

    test "returns {:error, :none} when no active link exists", ctx do
      assert {:error, :none} = CampaignInviteLinks.active_for_campaign(ctx.campaign_id)
    end

    test "returns {:error, :none} when only revoked links exist", ctx do
      {:ok, link} = CampaignInviteLinks.create_for_campaign(ctx.campaign_id, ctx.dm.id)
      CampaignInviteLinks.revoke(link)
      assert {:error, :none} = CampaignInviteLinks.active_for_campaign(ctx.campaign_id)
    end
  end
end
