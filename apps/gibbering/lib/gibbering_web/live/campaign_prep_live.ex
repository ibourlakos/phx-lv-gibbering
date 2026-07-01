defmodule GibberingWeb.CampaignPrepLive do
  use GibberingWeb, :live_view

  alias Gibbering.{Campaigns, CampaignCharacters, CampaignInviteLinks}

  @ability_keys ~w(strength dexterity constitution intelligence wisdom charisma)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    campaign_id = String.to_integer(id)
    user = socket.assigns.current_user
    campaign = Campaigns.get(campaign_id)

    cond do
      is_nil(campaign) ->
        {:ok, socket |> put_flash(:error, "Campaign not found.") |> redirect(to: "/")}

      campaign.dm_id != user.id ->
        {:ok,
         socket
         |> put_flash(:error, "Only the DM can access campaign prep.")
         |> redirect(to: "/")}

      true ->
        invite_link = invite_link_or_nil(campaign_id)

        {:ok,
         socket
         |> assign(:campaign, campaign)
         |> assign(:members, Campaigns.list_members(campaign_id))
         |> assign(
           :campaign_characters,
           CampaignCharacters.list_for_campaign_preloaded(campaign_id)
         )
         |> assign(:invite_link, invite_link)
         |> assign(:invite_url, invite_url(invite_link))}
    end
  end

  @impl true
  def handle_event("generate_invite_link", _params, socket) do
    campaign = socket.assigns.campaign

    case CampaignInviteLinks.create_for_campaign(campaign.id, socket.assigns.current_user.id) do
      {:ok, link} ->
        {:noreply,
         socket
         |> assign(:invite_link, link)
         |> assign(:invite_url, invite_url(link))
         |> put_flash(:info, "Invite link generated.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to generate invite link.")}
    end
  end

  @impl true
  def handle_event("revoke_invite_link", _params, socket) do
    case socket.assigns.invite_link do
      nil ->
        {:noreply, socket}

      link ->
        CampaignInviteLinks.revoke(link)

        {:noreply,
         socket
         |> assign(:invite_link, nil)
         |> assign(:invite_url, nil)
         |> put_flash(:info, "Invite link revoked.")}
    end
  end

  @impl true
  def handle_event("save_cc", %{"cc_id" => id, "cc" => params}, socket) do
    id = String.to_integer(id)

    case Enum.find(socket.assigns.campaign_characters, &(&1.id == id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Character not found.")}

      cc ->
        attrs = %{
          active: params["active"] == "true",
          controller_id: parse_int(params["controller_id"]),
          override_level: parse_int(params["override_level"]),
          override_ability_scores: parse_ability_scores(params),
          override_background_key: blank_to_nil(params["override_background_key"]),
          override_bonus_proficiencies: parse_list(params["override_bonus_proficiencies"]),
          override_starting_items: parse_items(params["override_starting_items"])
        }

        case CampaignCharacters.update(cc, attrs) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(:campaign_characters, reload_ccs(socket))
             |> put_flash(:info, "#{cc.character.name} saved.")}

          {:error, changeset} ->
            {:noreply, put_flash(socket, :error, "Save failed: #{format_errors(changeset)}")}
        end
    end
  end

  @impl true
  def handle_event("add_life_event", %{"cc_id" => id, "event_text" => text}, socket) do
    text = String.trim(text)

    if text == "" do
      {:noreply, put_flash(socket, :error, "Life event text cannot be blank.")}
    else
      id = String.to_integer(id)

      case Enum.find(socket.assigns.campaign_characters, &(&1.id == id)) do
        nil ->
          {:noreply, put_flash(socket, :error, "Character not found.")}

        cc ->
          event = %{"text" => text, "added_at" => DateTime.utc_now() |> DateTime.to_iso8601()}

          case CampaignCharacters.update(cc, %{dm_life_events: cc.dm_life_events ++ [event]}) do
            {:ok, _} ->
              {:noreply,
               socket
               |> assign(:campaign_characters, reload_ccs(socket))
               |> put_flash(:info, "Life event added.")}

            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Failed to add life event.")}
          end
      end
    end
  end

  # ---------------------------------------------------------------------------

  defp reload_ccs(socket),
    do: CampaignCharacters.list_for_campaign_preloaded(socket.assigns.campaign.id)

  defp invite_link_or_nil(campaign_id) do
    case CampaignInviteLinks.active_for_campaign(campaign_id) do
      {:ok, link} -> link
      {:error, :none} -> nil
    end
  end

  defp invite_url(nil), do: nil

  defp invite_url(link) do
    GibberingWeb.Endpoint.url() <> "/invites/#{link.token}"
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(s) do
    t = String.trim(s)
    if t == "", do: nil, else: t
  end

  defp parse_ability_scores(params) do
    scores =
      Enum.reduce(@ability_keys, %{}, fn key, acc ->
        case parse_int(params["override_#{key}"]) do
          nil -> acc
          n -> Map.put(acc, key, n)
        end
      end)

    if map_size(scores) == 0, do: nil, else: scores
  end

  defp parse_list(nil), do: []
  defp parse_list(""), do: []

  defp parse_list(s) do
    s |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  defp parse_items(nil), do: []
  defp parse_items(""), do: []

  defp parse_items(s) do
    s
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&%{"key" => &1})
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join(", ", fn {field, errs} -> "#{field}: #{Enum.join(errs, ", ")}" end)
  end
end
