defmodule GibberingTalesWeb.LobbyLive do
  use GibberingTalesWeb, :live_view

  import GibberingTalesWeb.Components.EntitySprites

  alias GibberingTales.Repo
  alias GibberingTales.{Campaign, Entity, Campaigns}
  alias GibberingTales.Catalogue.Cache, as: Catalogue
  alias GibberingTalesWeb.Engine.SceneServer

  @impl true
  def mount(%{"id" => campaign_id}, _session, socket) do
    campaign_id = String.to_integer(campaign_id)
    user = socket.assigns.current_user

    unless Campaigns.member?(campaign_id, user.id) do
      {:ok,
       socket
       |> put_flash(:error, "You are not a member of that campaign.")
       |> redirect(to: "/")}
    else
      campaign =
        Campaign
        |> Repo.get!(campaign_id)
        |> Repo.preload([:active_map, :entities])

      if connected?(socket) do
        Phoenix.PubSub.subscribe(GibberingTales.PubSub, lobby_topic(campaign_id))
      end

      {:ok,
       socket
       |> assign(:campaign, campaign)
       |> assign(:editing_id, nil)
       |> assign(:edit_form, %{})
       |> assign(:races, Catalogue.races_map())
       |> assign(:classes, Catalogue.classes_map())
       |> assign(:style_slug, GibberingTales.Catalogue.default_style_slug())
       |> assign(
         :appearances,
         GibberingTales.Catalogue.appearances_for_style(GibberingTales.Catalogue.default_style_slug())
       )}
    end
  end

  @impl true
  def handle_event("claim_slot", %{"id" => entity_id}, socket) do
    entity_id = String.to_integer(entity_id)
    user = socket.assigns.current_user
    entity = Repo.get!(Entity, entity_id)

    already_claimed =
      Enum.any?(socket.assigns.campaign.entities, fn e ->
        e.id != entity_id and Map.get(e.stats, "claimed_by") == user.id
      end)

    if already_claimed do
      {:noreply, put_flash(socket, :error, "You already hold a slot in this party.")}
    else
      stats =
        entity.stats
        |> Map.put("claimed_by", user.id)
        |> Map.put("claimed_by_name", user.username)

      entity
      |> Entity.changeset(%{stats: stats})
      |> Repo.update!()

      broadcast_refresh(socket.assigns.campaign.id)
      {:noreply, reload_campaign(socket)}
    end
  end

  @impl true
  def handle_event("release_slot", %{"id" => entity_id}, socket) do
    entity_id = String.to_integer(entity_id)
    entity = Repo.get!(Entity, entity_id)
    stats = entity.stats |> Map.delete("claimed_by") |> Map.delete("claimed_by_name")

    entity
    |> Entity.changeset(%{stats: stats})
    |> Repo.update!()

    broadcast_refresh(socket.assigns.campaign.id)
    {:noreply, reload_campaign(socket) |> assign(editing_id: nil, edit_form: %{})}
  end

  @impl true
  def handle_event("edit_slot", %{"id" => entity_id}, socket) do
    entity_id = String.to_integer(entity_id)
    entity = Repo.get!(Entity, entity_id)

    {:noreply,
     assign(socket,
       editing_id: entity_id,
       edit_form: %{"name" => entity.name, "race" => entity.race, "class" => entity.class}
     )}
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_id: nil, edit_form: %{})}
  end

  @impl true
  def handle_event("save_slot", params, socket) do
    editing_id = socket.assigns.editing_id
    entity = Repo.get!(Entity, editing_id)

    new_class = params["class"] || entity.class
    new_race = params["race"] || entity.race
    new_name = String.trim(params["name"] || entity.name)
    name = if new_name == "", do: entity.name, else: new_name

    class_data = Catalogue.get_class(new_class) || Catalogue.get_class(entity.class)

    base_hp = class_data.base_hp
    base_stats = class_data.stats

    race = Catalogue.get_race(new_race)
    race_bonuses = if race, do: race.stat_bonuses, else: %{}
    speed = if race, do: race.speed, else: 30

    merged_stats =
      base_stats
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        Map.put(acc, k, v + Map.get(race_bonuses, k, 0))
      end)
      |> Map.put("speed", speed)
      |> Map.put("claimed_by", Map.get(entity.stats, "claimed_by"))
      |> then(fn s ->
        if class_data.spellcasting do
          Map.put(s, "spells", class_data.spells)
        else
          s
        end
      end)
      |> then(fn s ->
        s
        |> maybe_preserve(entity.stats, "equipped_weapon")
        |> maybe_preserve(entity.stats, "equipped_armor")
      end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    sprite = "#{new_race}_#{new_class}"

    entity
    |> Entity.changeset(%{
      name: name,
      race: new_race,
      class: new_class,
      sprite: sprite,
      hp: base_hp,
      max_hp: base_hp,
      stats: merged_stats
    })
    |> Repo.update!()

    broadcast_refresh(socket.assigns.campaign.id)
    maybe_reload_scene(socket.assigns.campaign.id)
    {:noreply, reload_campaign(socket) |> assign(editing_id: nil, edit_form: %{})}
  end

  @impl true
  def handle_event("add_slot", _, socket) do
    if socket.assigns.current_user.id != socket.assigns.campaign.dm_id do
      {:noreply, put_flash(socket, :error, "Only the DM can add character slots.")}
    else
      heroes = Enum.filter(socket.assigns.campaign.entities, &(&1.type == "hero"))
      count = length(heroes)

      Repo.insert!(%Entity{
        name: "Adventurer #{count + 1}",
        type: "hero",
        sprite: "human_fighter",
        race: "human",
        class: "fighter",
        x: rem(count, 3) + 1,
        y: div(count, 3) * 2 + 3,
        hp: 20,
        max_hp: 20,
        tags: ["player_controlled"],
        stats: %{"speed" => 30},
        campaign_id: socket.assigns.campaign.id
      })

      broadcast_refresh(socket.assigns.campaign.id)
      maybe_reload_scene(socket.assigns.campaign.id)
      {:noreply, reload_campaign(socket)}
    end
  end

  @impl true
  def handle_event("remove_slot", %{"id" => entity_id}, socket) do
    if socket.assigns.current_user.id != socket.assigns.campaign.dm_id do
      {:noreply, put_flash(socket, :error, "Only the DM can remove character slots.")}
    else
      entity_id = String.to_integer(entity_id)
      entity = Repo.get!(Entity, entity_id)
      Repo.delete!(entity)

      broadcast_refresh(socket.assigns.campaign.id)
      maybe_reload_scene(socket.assigns.campaign.id)
      {:noreply, reload_campaign(socket) |> assign(editing_id: nil, edit_form: %{})}
    end
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, reload_campaign(socket)}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp lobby_topic(campaign_id), do: "lobby:#{campaign_id}"

  defp broadcast_refresh(campaign_id) do
    Phoenix.PubSub.broadcast(GibberingTales.PubSub, lobby_topic(campaign_id), :refresh)
  end

  defp maybe_reload_scene(campaign_id) do
    if SceneServer.running?(campaign_id) do
      SceneServer.reload_entities(campaign_id)
    end
  end

  defp reload_campaign(socket) do
    campaign =
      Campaign
      |> Repo.get!(socket.assigns.campaign.id)
      |> Repo.preload([:active_map, :entities])

    assign(socket, :campaign, campaign)
  end

  # ---------------------------------------------------------------------------
  # Sprite preview (small 48×48 version for lobby cards)
  # ---------------------------------------------------------------------------

  defp sprite_bg_color("human_fighter"), do: "#1e3a5a"
  defp sprite_bg_color("human_wizard"), do: "#2a1a4a"
  defp sprite_bg_color("human_rogue"), do: "#2a1a10"
  defp sprite_bg_color("elf_fighter"), do: "#1a3a28"
  defp sprite_bg_color("elf_wizard"), do: "#1a1040"
  defp sprite_bg_color("elf_rogue"), do: "#101e18"
  defp sprite_bg_color("gnome_fighter"), do: "#3a1a08"
  defp sprite_bg_color("gnome_wizard"), do: "#240a40"
  defp sprite_bg_color("gnome_rogue"), do: "#1e1208"
  defp sprite_bg_color(_), do: "#1a1a1a"

  defp race_label("human"), do: "Human"
  defp race_label("elf"), do: "Elf"
  defp race_label("gnome"), do: "Gnome"
  defp race_label(r), do: String.capitalize(r || "Unknown")

  defp class_label("fighter"), do: "Fighter"
  defp class_label("wizard"), do: "Wizard"
  defp class_label("rogue"), do: "Rogue"
  defp class_label(c), do: String.capitalize(c || "Unknown")

  defp class_badge_color("fighter"), do: "#4a6fa5"
  defp class_badge_color("wizard"), do: "#7b5ea7"
  defp class_badge_color("rogue"), do: "#6b4c38"
  defp class_badge_color(_), do: "#555"

  defp maybe_preserve(stats, source_stats, key) do
    case Map.get(source_stats, key) do
      nil -> stats
      value -> Map.put(stats, key, value)
    end
  end
end
