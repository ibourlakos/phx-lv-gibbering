defmodule Gibbering.CampaignCharactersTest do
  use Gibbering.DataCase, async: true

  alias Gibbering.CampaignCharacters
  alias Gibbering.AccountsFixtures
  alias Gibbering.CharactersFixtures
  alias Gibbering.GameFixtures

  setup do
    owner = AccountsFixtures.register_user()
    campaign_id = GameFixtures.insert_campaign()
    character = CharactersFixtures.create_character(owner)
    %{owner: owner, campaign_id: campaign_id, character: character}
  end

  describe "create/2" do
    test "creates a campaign character with valid attrs", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      attrs = %{
        campaign_id: campaign_id,
        character_id: character.id,
        owner_id: owner.id,
        controller_id: owner.id
      }

      assert {:ok, cc} = CampaignCharacters.create(campaign_id, attrs)
      assert cc.campaign_id == campaign_id
      assert cc.character_id == character.id
      assert cc.owner_id == owner.id
      assert cc.controller_id == owner.id
      assert cc.active == false
    end

    test "controller_id defaults to owner_id when omitted", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      attrs = %{campaign_id: campaign_id, character_id: character.id, owner_id: owner.id}
      assert {:ok, cc} = CampaignCharacters.create(campaign_id, attrs)
      assert cc.controller_id == owner.id
    end

    test "returns error when character_id and owner_id are missing", %{campaign_id: campaign_id} do
      assert {:error, changeset} = CampaignCharacters.create(campaign_id, %{})
      assert errors_on(changeset).character_id
      assert errors_on(changeset).owner_id
    end
  end

  describe "list_for_campaign/1" do
    test "returns all campaign characters for the given campaign", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, _} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      results = CampaignCharacters.list_for_campaign(campaign_id)
      assert length(results) == 1
      assert hd(results).character_id == character.id
    end

    test "does not return characters from other campaigns", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      other_campaign_id = GameFixtures.insert_campaign()

      {:ok, _} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      assert CampaignCharacters.list_for_campaign(other_campaign_id) == []
    end
  end

  describe "get/2" do
    test "returns the campaign character by campaign and id", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, cc} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      assert {:ok, found} = CampaignCharacters.get(campaign_id, cc.id)
      assert found.id == cc.id
    end

    test "returns error when id does not belong to the campaign", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      other_campaign_id = GameFixtures.insert_campaign()

      {:ok, cc} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      assert {:error, :not_found} = CampaignCharacters.get(other_campaign_id, cc.id)
    end
  end

  describe "update/3" do
    test "DM can set active, controller_id, and override fields", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, cc} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      controller = AccountsFixtures.register_user()

      assert {:ok, updated} =
               CampaignCharacters.update(cc, %{
                 active: true,
                 controller_id: controller.id,
                 override_level: 5,
                 override_ability_scores: %{"strength" => 18},
                 override_background_key: "soldier",
                 override_bonus_proficiencies: ["perception"],
                 dm_life_events: [%{"text" => "Survived the siege"}]
               })

      assert updated.active == true
      assert updated.controller_id == controller.id
      assert updated.override_level == 5
      assert updated.override_ability_scores == %{"strength" => 18}
      assert updated.override_background_key == "soldier"
      assert updated.override_bonus_proficiencies == ["perception"]
      assert updated.dm_life_events == [%{"text" => "Survived the siege"}]
    end

    test "override fields are all nullable", %{
      owner: owner,
      campaign_id: campaign_id,
      character: character
    } do
      {:ok, cc} =
        CampaignCharacters.create(campaign_id, %{
          campaign_id: campaign_id,
          character_id: character.id,
          owner_id: owner.id,
          controller_id: owner.id
        })

      assert {:ok, updated} = CampaignCharacters.update(cc, %{override_level: nil})
      assert is_nil(updated.override_level)
    end
  end
end
