defmodule Gibbering.CampaignInvitationsTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.{CampaignInvitations, Campaigns}
  alias Gibbering.AccountsFixtures
  alias Gibbering.CharactersFixtures
  alias Gibbering.GameFixtures

  setup do
    dm = AccountsFixtures.register_user()
    player = AccountsFixtures.register_user()
    campaign_id = GameFixtures.insert_campaign()
    character = CharactersFixtures.create_character(player)
    %{dm: dm, player: player, campaign_id: campaign_id, character: character}
  end

  describe "request_to_join/3 (Flow A — player-initiated)" do
    test "creates a pending player_request invitation", %{
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      assert {:ok, inv} =
               CampaignInvitations.request_to_join(campaign_id, player.id, character.id)

      assert inv.campaign_id == campaign_id
      assert inv.user_id == player.id
      assert inv.character_id == character.id
      assert inv.direction == "player_request"
      assert inv.status == "pending"
    end
  end

  describe "invite_player/3 (Flow B — DM-initiated)" do
    test "creates a pending dm_invite invitation", %{
      dm: dm,
      player: player,
      campaign_id: campaign_id
    } do
      assert {:ok, inv} =
               CampaignInvitations.invite_player(campaign_id, player.id, dm.id)

      assert inv.campaign_id == campaign_id
      assert inv.user_id == player.id
      assert inv.initiated_by_id == dm.id
      assert inv.direction == "dm_invite"
      assert inv.status == "pending"
      assert is_nil(inv.character_id)
    end
  end

  describe "list_pending_for_campaign/1" do
    test "returns only pending invitations for the campaign", %{
      dm: dm,
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, _} = CampaignInvitations.request_to_join(campaign_id, player.id, character.id)
      other_player = AccountsFixtures.register_user()
      {:ok, _} = CampaignInvitations.invite_player(campaign_id, other_player.id, dm.id)

      results = CampaignInvitations.list_pending_for_campaign(campaign_id)
      assert length(results) == 2
      assert Enum.all?(results, &(&1.status == "pending"))
    end

    test "does not return invitations for other campaigns", %{
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      other_campaign_id = GameFixtures.insert_campaign()
      {:ok, _} = CampaignInvitations.request_to_join(campaign_id, player.id, character.id)

      assert CampaignInvitations.list_pending_for_campaign(other_campaign_id) == []
    end
  end

  describe "list_pending_for_user/1" do
    test "returns pending invitations for the user across campaigns", %{
      dm: dm,
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      other_campaign_id = GameFixtures.insert_campaign()
      {:ok, _} = CampaignInvitations.request_to_join(campaign_id, player.id, character.id)
      {:ok, _} = CampaignInvitations.invite_player(other_campaign_id, player.id, dm.id)

      results = CampaignInvitations.list_pending_for_user(player.id)
      assert length(results) == 2
    end
  end

  describe "approve/1 (DM approves player_request)" do
    test "creates CampaignCharacter, joins campaign, marks invitation approved", %{
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, inv} = CampaignInvitations.request_to_join(campaign_id, player.id, character.id)
      assert {:ok, approved} = CampaignInvitations.approve(inv)

      assert approved.status == "approved"
      assert Campaigns.member?(campaign_id, player.id)

      ccs = Gibbering.CampaignCharacters.list_for_campaign(campaign_id)
      assert length(ccs) == 1
      assert hd(ccs).character_id == character.id
      assert hd(ccs).owner_id == player.id
    end
  end

  describe "reject/1 (DM rejects player_request)" do
    test "marks invitation rejected without creating records", %{
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, inv} = CampaignInvitations.request_to_join(campaign_id, player.id, character.id)
      assert {:ok, rejected} = CampaignInvitations.reject(inv)

      assert rejected.status == "rejected"
      refute Campaigns.member?(campaign_id, player.id)
      assert Gibbering.CampaignCharacters.list_for_campaign(campaign_id) == []
    end
  end

  describe "accept/2 (player accepts dm_invite)" do
    test "creates CampaignCharacter, joins campaign, marks invitation accepted", %{
      dm: dm,
      player: player,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, inv} = CampaignInvitations.invite_player(campaign_id, player.id, dm.id)
      assert {:ok, accepted} = CampaignInvitations.accept(inv, character.id)

      assert accepted.status == "accepted"
      assert Campaigns.member?(campaign_id, player.id)

      ccs = Gibbering.CampaignCharacters.list_for_campaign(campaign_id)
      assert length(ccs) == 1
      assert hd(ccs).character_id == character.id
    end
  end

  describe "decline/1 (player declines dm_invite)" do
    test "marks invitation declined without creating records", %{
      dm: dm,
      player: player,
      campaign_id: campaign_id
    } do
      {:ok, inv} = CampaignInvitations.invite_player(campaign_id, player.id, dm.id)
      assert {:ok, declined} = CampaignInvitations.decline(inv)

      assert declined.status == "declined"
      refute Campaigns.member?(campaign_id, player.id)
    end
  end
end
