defmodule GibberingWeb.CampaignPrepLiveTest do
  use GibberingWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import GibberingTales.AccountsFixtures

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, CampaignCharacter, CampaignCharacters, Campaigns}
  alias GibberingTales.Characters

  # ---------------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------------

  defp setup_campaign_with_dm(_ctx) do
    dm = register_user()
    player = register_user()

    {:ok, campaign} =
      Repo.insert(%Campaign{
        name: "Prep Test Campaign"
      })

    {:ok, _} = Campaigns.set_dm(campaign, dm.id)
    {:ok, _} = Campaigns.join_campaign(campaign.id, dm.id)
    {:ok, _} = Campaigns.join_campaign(campaign.id, player.id)

    campaign = Repo.get!(Campaign, campaign.id)

    character = insert_character(player)

    {:ok, cc} =
      CampaignCharacters.create(campaign.id, %{
        character_id: character.id,
        owner_id: player.id,
        controller_id: player.id
      })

    %{dm: dm, player: player, campaign: campaign, character: character, cc: cc}
  end

  defp insert_character(user) do
    {:ok, char} =
      Characters.create_character(user.id, %{
        "name" => "Thorin",
        "race" => "human",
        "class" => "fighter",
        "level" => "3",
        "strength" => "16",
        "dexterity" => "12",
        "constitution" => "14",
        "intelligence" => "10",
        "wisdom" => "10",
        "charisma" => "10"
      })

    char
  end

  defp mount_prep(conn, dm, campaign) do
    conn = log_in_user(conn, dm)
    {:ok, view, html} = live(conn, "/campaigns/#{campaign.id}/prep")
    {view, html}
  end

  # ---------------------------------------------------------------------------
  # Mount / access control
  # ---------------------------------------------------------------------------

  describe "mount" do
    setup :setup_campaign_with_dm

    test "DM can mount the prep page and sees the character", ctx do
      {_view, html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)
      assert html =~ "Campaign Prep"
      assert html =~ "Thorin"
    end

    test "non-DM is redirected", ctx do
      conn = log_in_user(ctx.conn, ctx.player)

      assert {:error, {:redirect, %{to: "/"}}} =
               live(conn, "/campaigns/#{ctx.campaign.id}/prep")
    end

    test "unknown campaign redirects", ctx do
      conn = log_in_user(ctx.conn, ctx.dm)
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/campaigns/99999999/prep")
    end
  end

  # ---------------------------------------------------------------------------
  # save_cc event
  # ---------------------------------------------------------------------------

  describe "save_cc" do
    setup :setup_campaign_with_dm

    test "DM can toggle active flag", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='save_cc']", %{
        "cc_id" => ctx.cc.id,
        "cc" => %{"active" => "true", "controller_id" => ctx.player.id}
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert cc.active == true
    end

    test "DM can set override level", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='save_cc']", %{
        "cc_id" => ctx.cc.id,
        "cc" => %{"active" => "false", "override_level" => "5"}
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert cc.override_level == 5
    end

    test "DM can set partial ability score overrides", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='save_cc']", %{
        "cc_id" => ctx.cc.id,
        "cc" => %{"active" => "false", "override_strength" => "18", "override_dexterity" => ""}
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert cc.override_ability_scores == %{"strength" => 18}
    end

    test "DM can set override bonus proficiencies via comma-separated input", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='save_cc']", %{
        "cc_id" => ctx.cc.id,
        "cc" => %{"active" => "false", "override_bonus_proficiencies" => "Athletics, Stealth"}
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert cc.override_bonus_proficiencies == ["Athletics", "Stealth"]
    end
  end

  # ---------------------------------------------------------------------------
  # add_life_event event
  # ---------------------------------------------------------------------------

  describe "add_life_event" do
    setup :setup_campaign_with_dm

    test "DM can add a life event", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='add_life_event']", %{
        "cc_id" => ctx.cc.id,
        "event_text" => "Found a mysterious relic in the ruins."
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert length(cc.dm_life_events) == 1
      assert hd(cc.dm_life_events)["text"] == "Found a mysterious relic in the ruins."
    end

    test "blank event text is rejected and nothing is persisted", ctx do
      {view, _html} = mount_prep(ctx.conn, ctx.dm, ctx.campaign)

      view
      |> form("form[phx-submit='add_life_event']", %{
        "cc_id" => ctx.cc.id,
        "event_text" => "   "
      })
      |> render_submit()

      cc = Repo.get!(CampaignCharacter, ctx.cc.id)
      assert cc.dm_life_events == []
    end
  end
end
