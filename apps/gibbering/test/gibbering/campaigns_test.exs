defmodule Gibbering.CampaignsTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.{Repo, Campaign, Campaigns, CampaignCharacters}
  alias Gibbering.AccountsFixtures
  alias Gibbering.CharactersFixtures

  defp insert_campaign(dm, attrs \\ %{}) do
    {:ok, campaign} =
      Repo.insert(%Campaign{
        name: Map.get(attrs, :name, "Campaign #{System.unique_integer([:positive])}"),
        dm_id: dm.id
      })

    campaign
  end

  describe "list_campaigns_for_user_with_characters/1" do
    test "returns empty list when user has no memberships" do
      user = AccountsFixtures.register_user()
      assert Campaigns.list_campaigns_for_user_with_characters(user.id) == []
    end

    test "returns campaign with player's characters" do
      dm = AccountsFixtures.register_user()
      player = AccountsFixtures.register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, player.id)

      character = CharactersFixtures.create_character(player)

      {:ok, _cc} =
        CampaignCharacters.create(campaign.id, %{
          character_id: character.id,
          owner_id: player.id
        })

      result = Campaigns.list_campaigns_for_user_with_characters(player.id)
      assert length(result) == 1
      {returned_campaign, ccs} = hd(result)
      assert returned_campaign.id == campaign.id
      assert length(ccs) == 1
      assert hd(ccs).character.name == character.name
    end

    test "does not include other players' characters in the same campaign" do
      dm = AccountsFixtures.register_user()
      player1 = AccountsFixtures.register_user()
      player2 = AccountsFixtures.register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, player1.id)
      {:ok, _} = Campaigns.join_campaign(campaign.id, player2.id)

      char1 = CharactersFixtures.create_character(player1)
      char2 = CharactersFixtures.create_character(player2)

      {:ok, _} =
        CampaignCharacters.create(campaign.id, %{
          character_id: char1.id,
          owner_id: player1.id
        })

      {:ok, _} =
        CampaignCharacters.create(campaign.id, %{
          character_id: char2.id,
          owner_id: player2.id
        })

      result = Campaigns.list_campaigns_for_user_with_characters(player1.id)
      assert length(result) == 1
      {_camp, ccs} = hd(result)
      assert length(ccs) == 1
      assert hd(ccs).owner_id == player1.id
    end

    test "DM membership returns campaign with empty character list" do
      dm = AccountsFixtures.register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, dm.id)

      result = Campaigns.list_campaigns_for_user_with_characters(dm.id)
      assert length(result) == 1
      {returned_campaign, ccs} = hd(result)
      assert returned_campaign.id == campaign.id
      assert ccs == []
    end

    test "campaign struct has dm preloaded" do
      dm = AccountsFixtures.register_user()
      campaign = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(campaign.id, dm.id)

      [{returned_campaign, _}] = Campaigns.list_campaigns_for_user_with_characters(dm.id)
      assert returned_campaign.dm.id == dm.id
    end

    test "returns multiple campaigns ordered by id" do
      player = AccountsFixtures.register_user()
      dm = AccountsFixtures.register_user()
      c1 = insert_campaign(dm)
      c2 = insert_campaign(dm)
      {:ok, _} = Campaigns.join_campaign(c1.id, player.id)
      {:ok, _} = Campaigns.join_campaign(c2.id, player.id)

      result = Campaigns.list_campaigns_for_user_with_characters(player.id)
      ids = Enum.map(result, fn {c, _} -> c.id end)
      assert ids == Enum.sort(ids)
    end
  end

  describe "campaign status default" do
    test "newly inserted campaign defaults to lobby" do
      dm = AccountsFixtures.register_user()
      campaign = insert_campaign(dm)
      assert campaign.status == "lobby"
    end
  end
end
