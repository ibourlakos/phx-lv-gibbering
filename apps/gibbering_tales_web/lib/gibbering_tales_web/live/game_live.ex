defmodule GibberingTalesWeb.GameLive do
  use GibberingTalesWeb, :live_view

  import GibberingTalesWeb.Components.EntitySprites

  alias GibberingTalesWeb.Engine.{SceneServer, State, Rules}
  alias GibberingTalesWeb.HUD
  alias GibberingEngine.SpriteCompositor
  alias GibberingTales.{Campaigns, CampaignCharacters}
  alias GibberingEngine.EventBus
  alias GibberingEngine.Events.EventBatch
  alias GibberingTalesWeb.Events.{EventFeedProjection, FreeformRolled}
  alias GibberingTales.Events.Notification.{BroadcastSent, WhisperDelivered}
  alias GibberingEngine.Events.{RollRequired, SessionEnded, TurnAdvanced}
  alias GibberingTales.Rulesets.DnD5e.RulesetState

  @dice_faces %{
    "d4" => 4,
    "d6" => 6,
    "d8" => 8,
    "d10" => 10,
    "d12" => 12,
    "d20" => 20,
    "d100" => 100
  }
  @dice_order ~w(d4 d6 d8 d10 d12 d20 d100)
  @empty_freeform_dice Map.new(@dice_order, &{&1, 0})
  alias GibberingTales.Catalogue
  alias GibberingTales.Data.Spells

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game_id = String.to_integer(game_id)
    user = socket.assigns.current_user

    if not Campaigns.member?(game_id, user.id) do
      {:ok,
       socket
       |> put_flash(:error, "You are not a member of that campaign.")
       |> redirect(to: "/")}
    else
      case ensure_game_server(game_id) do
        :ok ->
          if connected?(socket) do
            EventBus.subscribe(SceneServer.topic(game_id))
            EventBus.subscribe(SceneServer.notifications_topic(game_id))
            EventBus.subscribe("game:#{game_id}:user:#{user.id}")
          end

          campaign = Campaigns.get!(game_id)
          state = SceneServer.get_state(game_id)
          is_dm = campaign.dm_id == user.id
          viewer_role = if is_dm, do: :dm, else: :player

          appearances =
            Catalogue.appearances_for_style(Catalogue.default_style_slug())

          campaign_character =
            if is_dm, do: nil, else: CampaignCharacters.get_active_for_player(game_id, user.id)

          {:ok,
           socket
           |> assign(:game_id, game_id)
           |> assign(:game_state, state)
           |> assign(:viewer_role, viewer_role)
           |> assign(:is_dm, is_dm)
           |> assign(:style_slug, Catalogue.default_style_slug())
           |> assign(:appearances, appearances)
           |> assign(:show_end_confirm, false)
           |> assign(:selected_spell, nil)
           |> assign(:spell_targets, [])
           |> assign(:log, [])
           |> assign(:event_log, [])
           |> assign(:dm_broadcasts, [])
           |> assign(:dm_whispers, [])
           |> assign(:dm_panel, nil)
           |> assign(:panel_subject, nil)
           |> assign(:round, 0)
           |> assign(:campaign_character, campaign_character)
           |> assign(
             :auto_roll,
             if(campaign_character, do: campaign_character.auto_roll, else: true)
           )
           |> assign(:roll_prompt, nil)
           |> assign(:active_tab, :events)
           |> assign(:unread_count, 0)
           |> assign(:dm_intervene_entity_id, nil)
           |> assign(:freeform_dice, @empty_freeform_dice)
           |> assign_hud_and_dm_state(state, viewer_role)}

        {:error, reason} ->
          {:ok,
           socket
           |> put_flash(:error, "Game #{game_id} could not be loaded: #{inspect(reason)}")
           |> redirect(to: "/")}
      end
    end
  end

  # Dev-only style switch: ?style=<slug> overrides the campaign default for local
  # preview/testing. Falls back to Catalogue.default_style_slug/0 for anything absent
  # or unrecognized.
  @impl true
  def handle_params(params, _uri, socket) do
    style_slug = resolve_style_slug(params["style"])

    {:noreply,
     socket
     |> assign(:style_slug, style_slug)
     |> assign(:appearances, Catalogue.appearances_for_style(style_slug))}
  end

  defp resolve_style_slug(nil), do: Catalogue.default_style_slug()

  defp resolve_style_slug(slug) do
    if Catalogue.style_slug_valid?(slug), do: slug, else: Catalogue.default_style_slug()
  end

  @impl true
  def handle_event("select_entity", %{"id" => id}, socket) do
    id = String.to_integer(id)
    new_state = SceneServer.select_entity(socket.assigns.game_id, id)

    {:noreply,
     socket
     |> assign(game_state: new_state, panel_subject: {:entity, id})
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("deselect", _, socket) do
    new_state = SceneServer.deselect_entity(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(:game_state, new_state)
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("dismiss_panel", _, socket) do
    {:noreply, assign(socket, panel_subject: nil)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    tab_atom =
      case tab do
        "events" -> :events
        "dm" -> :dm
        "catalogue" -> :catalogue
        _ -> socket.assigns.active_tab
      end

    socket =
      socket
      |> assign(:active_tab, tab_atom)
      |> then(fn s -> if tab_atom == :events, do: assign(s, :unread_count, 0), else: s end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_dm_intervene", %{"id" => id}, socket) do
    {:noreply, assign(socket, dm_intervene_entity_id: String.to_integer(id))}
  end

  @impl true
  def handle_event("close_dm_intervene", _, socket) do
    {:noreply, assign(socket, dm_intervene_entity_id: nil)}
  end

  @impl true
  def handle_event("inspect_entity", %{"id" => id}, socket) do
    {:noreply, assign(socket, panel_subject: {:entity, String.to_integer(id)})}
  end

  @impl true
  def handle_event("inspect_spell_cast", %{"event_id" => event_id}, socket) do
    overrides = EventFeedProjection.fold(socket.assigns.event_log)

    event =
      Enum.find(socket.assigns.event_log, fn e ->
        e.event_id == event_id and
          (socket.assigns.is_dm or
             EventFeedProjection.effective_visibility(e, overrides) in [:public, :revealed])
      end)

    subject = if event, do: {:spell_cast, event}, else: nil
    {:noreply, assign(socket, panel_subject: subject)}
  end

  @impl true
  def handle_event("deselect_spell", _, socket) do
    {:noreply, assign(socket, selected_spell: nil, spell_targets: [])}
  end

  @impl true
  def handle_event("escape_pressed", _, socket) do
    socket =
      socket
      |> assign(selected_spell: nil, spell_targets: [])

    if socket.assigns.game_state.valid_moves != [] do
      new_state = SceneServer.cancel_move(socket.assigns.game_id)

      {:noreply,
       socket
       |> assign(:game_state, new_state)
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("activate_move", _, socket) do
    new_state = SceneServer.activate_move(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(:game_state, new_state)
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("cancel_move", _, socket) do
    new_state = SceneServer.cancel_move(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(:game_state, new_state)
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("move", %{"x" => x, "y" => y}, socket) do
    new_state =
      SceneServer.move_entity(socket.assigns.game_id, String.to_integer(x), String.to_integer(y))

    {:noreply,
     socket
     |> assign(:game_state, new_state)
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("inspect_tile", %{"x" => x, "y" => y}, socket) do
    game_state = socket.assigns.game_state

    if game_state.valid_moves != [] do
      new_state = SceneServer.cancel_move(socket.assigns.game_id)

      {:noreply,
       socket
       |> assign(:game_state, new_state)
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
    else
      {:noreply,
       assign(socket, panel_subject: {:tile, String.to_integer(x), String.to_integer(y)})}
    end
  end

  @impl true
  def handle_event("attack", %{"id" => target_id}, socket) do
    target_id = String.to_integer(target_id)
    state = socket.assigns.game_state
    target_name = state.actors[target_id].name

    attacker_id = state.actor_id
    attacker_name = if attacker_id, do: state.actors[attacker_id].name, else: "?"

    new_state =
      SceneServer.attack_entity(socket.assigns.game_id, target_id,
        auto_roll: socket.assigns.auto_roll
      )

    if State.awaiting_roll?(new_state) do
      {:noreply,
       socket
       |> assign(:game_state, new_state)
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
    else
      damage =
        if Map.has_key?(new_state.actors, target_id) do
          state.actors[target_id].hp - new_state.actors[target_id].hp
        else
          state.actors[target_id].hp
        end

      dice_result = max(min(damage, 6), 1)

      log_entry =
        if Map.has_key?(new_state.actors, target_id) do
          hp = new_state.actors[target_id].hp
          "#{attacker_name} hits #{target_name} for #{damage}! (#{hp} HP left)"
        else
          "#{target_name} destroyed!"
        end

      {:noreply,
       socket
       |> assign(:game_state, new_state)
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)
       |> update(:log, fn log -> [log_entry | Enum.take(log, 9)] end)
       |> push_event("roll_dice", %{result: dice_result, label: "#{attacker_name} attacks!"})}
    end
  end

  @impl true
  def handle_event("select_spell", %{"key" => spell_key}, socket) do
    state = socket.assigns.game_state
    caster_id = state.actor_id || State.active_hero_id(state)

    spell_targets =
      if caster_id,
        do: Rules.valid_spell_targets(state, caster_id, spell_key),
        else: []

    {:noreply,
     assign(socket, selected_spell: spell_key, spell_targets: spell_targets)}
  end

  @impl true
  def handle_event("cast_spell", %{"id" => target_id}, socket) do
    target_id = String.to_integer(target_id)
    state = socket.assigns.game_state
    spell_key = socket.assigns.selected_spell

    caster_id = state.actor_id
    caster_name = if caster_id, do: state.actors[caster_id].name, else: "?"
    target_name = state.actors[target_id].name
    spell = Spells.get(spell_key)
    spell_name = if spell, do: spell.name, else: spell_key

    new_state =
      SceneServer.cast_spell(socket.assigns.game_id, spell_key, target_id,
        auto_roll: socket.assigns.auto_roll
      )

    if State.awaiting_roll?(new_state) do
      {:noreply,
       socket
       |> assign(:game_state, new_state)
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
    else
      {damage, log_entry} =
        if Map.has_key?(new_state.actors, target_id) do
          dmg = state.actors[target_id].hp - new_state.actors[target_id].hp
          hp = new_state.actors[target_id].hp

          {max(dmg, 0),
           "#{caster_name} casts #{spell_name} → #{target_name} for #{dmg}! (#{hp} HP left)"}
        else
          {state.actors[target_id].hp,
           "#{caster_name} casts #{spell_name} → #{target_name} destroyed!"}
        end

      dice_result = max(min(damage, 6), 1)

      {:noreply,
       socket
       |> assign(game_state: new_state, selected_spell: nil, spell_targets: [])
       |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)
       |> update(:log, fn log -> [log_entry | Enum.take(log, 9)] end)
       |> push_event("roll_dice", %{
         result: dice_result,
         label: "#{caster_name} casts #{spell_name}!"
       })}
    end
  end

  @impl true
  def handle_event("end_turn", _, socket) do
    new_state = SceneServer.end_turn(socket.assigns.game_id)

    {:noreply,
     socket
     |> assign(game_state: new_state, selected_spell: nil, spell_targets: [])
     |> assign_hud_and_dm_state(new_state, socket.assigns.viewer_role)}
  end

  @impl true
  def handle_event("dm_start", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.start_session(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_pause", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.pause_session(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_resume", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.resume_session(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_end_confirm", _, %{assigns: %{is_dm: true}} = socket) do
    {:noreply, assign(socket, show_end_confirm: true)}
  end

  @impl true
  def handle_event("dm_end_cancel", _, socket) do
    {:noreply, assign(socket, show_end_confirm: false)}
  end

  @impl true
  def handle_event("dm_end", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.end_session(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_return_to_lobby", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.force_transition_phase(socket.assigns.game_id, :lobby)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_roll_initiative", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    id = String.to_integer(id)
    entity = socket.assigns.game_state.actors[id]
    dex = get_in(entity, [:stats, "dexterity"]) || 10
    dex_mod = div(dex - 10, 2)
    value = :rand.uniform(20) + dex_mod
    SceneServer.set_initiative(socket.assigns.game_id, id, value)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_add_to_order", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.add_to_turn_order(socket.assigns.game_id, String.to_integer(id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_remove_from_order", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.remove_from_turn_order(socket.assigns.game_id, String.to_integer(id))
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_move_up", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    id = String.to_integer(id)
    order = socket.assigns.game_state.turn_order
    idx = Enum.find_index(order, &(&1 == id))

    if idx && idx > 0 do
      new_order = order |> List.delete_at(idx) |> List.insert_at(idx - 1, id)
      SceneServer.reorder_turn_order(socket.assigns.game_id, new_order)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_move_down", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    id = String.to_integer(id)
    order = socket.assigns.game_state.turn_order
    idx = Enum.find_index(order, &(&1 == id))

    if idx && idx < length(order) - 1 do
      new_order = order |> List.delete_at(idx) |> List.insert_at(idx + 1, id)
      SceneServer.reorder_turn_order(socket.assigns.game_id, new_order)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_end_initiative_rolling", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.end_initiative_rolling(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_force_end_turn", _, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.force_end_turn(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_open_broadcast", _, %{assigns: %{is_dm: true}} = socket) do
    {:noreply, assign(socket, dm_panel: :broadcast)}
  end

  @impl true
  def handle_event("dm_open_whisper", _, %{assigns: %{is_dm: true}} = socket) do
    {:noreply, assign(socket, dm_panel: :whisper)}
  end

  @impl true
  def handle_event("dm_close_panel", _, socket) do
    {:noreply, assign(socket, dm_panel: nil)}
  end

  @impl true
  def handle_event("dm_broadcast", %{"text" => text}, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.dm_broadcast(socket.assigns.game_id, text)
    {:noreply, assign(socket, dm_panel: nil)}
  end

  @impl true
  def handle_event(
        "dm_whisper",
        %{"user_id" => uid, "text" => text},
        %{assigns: %{is_dm: true}} = socket
      ) do
    user_id = String.to_integer(uid)
    SceneServer.dm_whisper(socket.assigns.game_id, user_id, text)
    {:noreply, assign(socket, dm_panel: nil)}
  end

  @impl true
  def handle_event(
        "dm_apply_condition",
        %{"entity_id" => eid, "condition" => cond_str},
        %{assigns: %{is_dm: true}} = socket
      ) do
    entity_id = String.to_integer(eid)
    condition_id = String.to_existing_atom(cond_str)
    SceneServer.dm_apply_condition(socket.assigns.game_id, entity_id, condition_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "dm_adjust_hp",
        %{"entity_id" => eid, "delta" => delta_str},
        %{assigns: %{is_dm: true}} = socket
      ) do
    entity_id = String.to_integer(eid)
    delta = String.to_integer(delta_str)
    SceneServer.dm_adjust_hp(socket.assigns.game_id, entity_id, delta)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_toggle_visibility", %{"id" => id}, %{assigns: %{is_dm: true}} = socket) do
    SceneServer.dm_toggle_visibility(socket.assigns.game_id, String.to_integer(id))
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "reveal_log_entry",
        %{"event_id" => event_id},
        %{assigns: %{is_dm: true}} = socket
      ) do
    SceneServer.reveal_log_entry(socket.assigns.game_id, event_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "hide_log_entry",
        %{"event_id" => event_id},
        %{assigns: %{is_dm: true}} = socket
      ) do
    SceneServer.hide_log_entry(socket.assigns.game_id, event_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("dm_dismiss_broadcast", _, socket) do
    {:noreply, update(socket, :dm_broadcasts, fn [_ | rest] -> rest end)}
  end

  @impl true
  def handle_event("dm_dismiss_whisper", _, socket) do
    {:noreply, update(socket, :dm_whispers, fn [_ | rest] -> rest end)}
  end

  @impl true
  def handle_event("open_container", %{"id" => id}, socket) do
    container_id = String.to_integer(id)

    case SceneServer.open_container(socket.assigns.game_id, container_id) do
      {:ok, _state} -> {:noreply, socket}
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "take_item",
        %{"container_id" => cid, "instance_id" => iid, "quantity" => q},
        socket
      ) do
    quantity = if is_binary(q), do: String.to_integer(q), else: q

    case SceneServer.take_item(socket.assigns.game_id, String.to_integer(cid), iid, quantity) do
      {:ok, _state} -> {:noreply, socket}
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("take_all", %{"container_id" => cid}, socket) do
    SceneServer.take_all_items(socket.assigns.game_id, String.to_integer(cid))
    {:noreply, socket}
  end

  @impl true
  def handle_event("equip_item", %{"instance_id" => iid}, socket) do
    case SceneServer.equip_item(socket.assigns.game_id, iid) do
      {:ok, _state} -> {:noreply, socket}
      {:error, _} -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_container", _, socket) do
    SceneServer.close_container(socket.assigns.game_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("roll_submit", _, %{assigns: %{roll_prompt: prompt}} = socket)
      when not is_nil(prompt) do
    value = Enum.random(1..20)
    entity_id = prompt.entity_id
    SceneServer.submit_roll(socket.assigns.game_id, entity_id, value)

    {:noreply,
     socket
     |> push_event("roll_dice", %{result: rem(value - 1, 6) + 1, label: prompt.context_label})}
  end

  @impl true
  def handle_event(
        "roll_manual_submit",
        %{"value" => raw},
        %{assigns: %{roll_prompt: prompt}} = socket
      )
      when not is_nil(prompt) do
    case Integer.parse(raw) do
      {value, ""} when value >= 1 and value <= 20 ->
        SceneServer.submit_roll(socket.assigns.game_id, prompt.entity_id, value)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_auto_roll", _, %{assigns: %{campaign_character: cc}} = socket)
      when not is_nil(cc) do
    new_value = !socket.assigns.auto_roll

    case CampaignCharacters.set_auto_roll(cc, new_value) do
      {:ok, updated_cc} ->
        {:noreply, assign(socket, campaign_character: updated_cc, auto_roll: new_value)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("freeform_dice_inc", %{"die" => die}, socket)
      when is_map_key(@dice_faces, die) and not socket.assigns.is_dm do
    count = Map.get(socket.assigns.freeform_dice, die, 0)
    updated = Map.put(socket.assigns.freeform_dice, die, min(count + 1, 10))
    {:noreply, assign(socket, freeform_dice: updated)}
  end

  @impl true
  def handle_event("freeform_dice_dec", %{"die" => die}, socket)
      when is_map_key(@dice_faces, die) and not socket.assigns.is_dm do
    count = Map.get(socket.assigns.freeform_dice, die, 0)
    updated = Map.put(socket.assigns.freeform_dice, die, max(count - 1, 0))
    {:noreply, assign(socket, freeform_dice: updated)}
  end

  @impl true
  def handle_event("freeform_dice_clear", _, %{assigns: %{is_dm: false}} = socket) do
    {:noreply, assign(socket, freeform_dice: @empty_freeform_dice)}
  end

  @impl true
  def handle_event("freeform_roll", _, %{assigns: %{is_dm: false}} = socket) do
    dice = socket.assigns.freeform_dice
    active_dice = Enum.filter(dice, fn {_die, count} -> count > 0 end)

    if active_dice == [] do
      {:noreply, socket}
    else
      results =
        Map.new(active_dice, fn {die, count} ->
          faces = @dice_faces[die]
          {die, Enum.map(1..count, fn _ -> Enum.random(1..faces) end)}
        end)

      total = results |> Map.values() |> List.flatten() |> Enum.sum()

      roller_name =
        case socket.assigns.campaign_character do
          nil -> socket.assigns.current_user.email
          cc -> cc.character_name || socket.assigns.current_user.email
        end

      event = %FreeformRolled{
        roller_name: roller_name,
        dice_map: Map.new(active_dice),
        results: results,
        total: total
      }

      EventBus.broadcast(SceneServer.topic(socket.assigns.game_id), event)

      # animate up to 3 dice (pick the most numerous die type first)
      dice_for_anim =
        active_dice
        |> Enum.sort_by(fn {_die, count} -> -count end)
        |> Enum.flat_map(fn {die, _count} -> results[die] end)
        |> Enum.take(3)

      animation_payload =
        dice_for_anim
        |> Enum.with_index()
        |> Enum.map(fn {result, i} ->
          %{
            result: min(result, 6),
            label: "#{roller_name} rolled #{die_expression(active_dice)}",
            delay: i * 300
          }
        end)

      {:noreply,
       socket
       |> assign(freeform_dice: @empty_freeform_dice)
       |> push_event("roll_dice_sequence", %{dice: animation_payload})}
    end
  end

  @impl true
  def handle_event(event, _, socket)
      when event in [
             "dm_start",
             "dm_pause",
             "dm_resume",
             "dm_end_confirm",
             "dm_end",
             "dm_roll_initiative",
             "dm_add_to_order",
             "dm_remove_from_order",
             "dm_move_up",
             "dm_move_down",
             "dm_end_initiative_rolling",
             "dm_force_end_turn",
             "dm_open_broadcast",
             "dm_open_whisper",
             "dm_close_panel",
             "dm_broadcast",
             "dm_whisper",
             "dm_apply_condition",
             "dm_adjust_hp",
             "dm_toggle_visibility",
             "dm_dismiss_broadcast",
             "dm_dismiss_whisper",
             "dm_return_to_lobby"
           ] do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%EventBatch{events: events} = batch, socket) do
    if Enum.any?(events, &match?(%SessionEnded{}, &1)) do
      {:noreply, redirect(socket, to: "/dashboard")}
    else
      new_socket =
        socket
        |> then(fn s ->
          if batch.state_snapshot do
            s
            |> assign(:game_state, batch.state_snapshot)
            |> assign_hud_and_dm_state(batch.state_snapshot, s.assigns.viewer_role)
          else
            s
          end
        end)
        |> update(:event_log, fn log -> log ++ events end)

      round =
        Enum.reduce(events, socket.assigns.round, fn
          %TurnAdvanced{round_number: n}, acc -> max(acc, n)
          _, acc -> acc
        end)

      {roll_prompt, auto_submit_initiatives} =
        Enum.reduce(events, {socket.assigns.roll_prompt, []}, fn
          %RollRequired{roll_type: :initiative} = e, {prompt, inits} ->
            if socket.assigns.auto_roll do
              {prompt, [e.entity_id | inits]}
            else
              {e, inits}
            end

          %RollRequired{} = e, {_prompt, inits} ->
            {e, inits}

          _, acc ->
            acc
        end)

      # Clear prompt when state_snapshot shows awaiting_roll is now false
      roll_prompt =
        if batch.state_snapshot && !State.awaiting_roll?(batch.state_snapshot) &&
             (roll_prompt == nil or roll_prompt.roll_type != :initiative),
           do: nil,
           else: roll_prompt

      unread_delta =
        if socket.assigns.active_tab != :events do
          Enum.count(events, fn e -> event_label(e) != nil end)
        else
          0
        end

      socket_after_events =
        assign(new_socket,
          round: round,
          roll_prompt: roll_prompt,
          unread_count: socket.assigns.unread_count + unread_delta
        )

      final_socket =
        Enum.reduce(auto_submit_initiatives, socket_after_events, fn entity_id, s ->
          value = Enum.random(1..20)
          SceneServer.submit_roll(s.assigns.game_id, entity_id, value)
          s
        end)

      {:noreply, final_socket}
    end
  end

  @impl true
  def handle_info(%BroadcastSent{text: text}, socket) do
    {:noreply, update(socket, :dm_broadcasts, fn msgs -> [text | Enum.take(msgs, 4)] end)}
  end

  @impl true
  def handle_info(%WhisperDelivered{text: text, target_player_id: target_id}, socket) do
    if target_id == socket.assigns.current_user.id do
      {:noreply, update(socket, :dm_whispers, fn msgs -> [text | Enum.take(msgs, 4)] end)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%FreeformRolled{} = event, socket) do
    unread_delta = if socket.assigns.active_tab != :events, do: 1, else: 0

    {:noreply,
     socket
     |> update(:event_log, fn log -> log ++ [event] end)
     |> assign(unread_count: socket.assigns.unread_count + unread_delta)}
  end

  def handle_info({:ejected, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "You have been removed from this campaign: #{reason}")
     |> push_navigate(to: "/dashboard")}
  end

  # ---------------------------------------------------------------------------
  # SceneServer lifecycle
  # ---------------------------------------------------------------------------

  defp ensure_game_server(game_id), do: SceneServer.ensure_started(game_id)

  # Rebuilds the HUD and DM-specific assigns derived from engine state.
  # Called after every game_state update so templates never read ruleset_state directly.
  defp assign_hud_and_dm_state(socket, state, viewer_role) do
    rs = state.ruleset_state

    socket
    |> assign(:hud, HUD.build(state, viewer_role))
    |> assign(:hidden_entity_ids, RulesetState.hidden_entities(rs))
    |> assign(:initiative_values, RulesetState.initiative_values(rs))
    |> assign(:pending_initiative_rolls, RulesetState.pending_initiative_rolls(rs))
  end

  defp ruleset_conditions(state), do: state.ruleset.available_conditions()

  # ---------------------------------------------------------------------------
  # Inspection panel helpers
  # ---------------------------------------------------------------------------

  defp inspect_content(nil, _state, _is_dm), do: nil

  defp inspect_content({:entity, entity_id}, state, is_dm) do
    case Map.get(state.actors, entity_id) do
      nil -> {:fallen_entity, entity_id}
      entity -> {:entity, entity, is_dm}
    end
  end

  defp inspect_content({:tile, x, y}, state, _is_dm) do
    case Map.get(state.grid_tiles, {x, y}) do
      nil -> nil
      tile -> {:tile, x, y, tile}
    end
  end

  defp inspect_content({:spell_cast, event}, _state, _is_dm) do
    {:spell_cast, event}
  end

  defp hp_percent(hp, max_hp) when is_integer(max_hp) and max_hp > 0,
    do: round(hp / max_hp * 100)

  defp hp_percent(_, _), do: 0

  defp hp_bar_color(hp, max_hp) do
    case hp_percent(hp, max_hp) do
      n when n > 50 -> "#22c55e"
      n when n > 25 -> "#eab308"
      _ -> "#ef4444"
    end
  end

  defp ability_modifier(score) when is_integer(score), do: div(score - 10, 2)
  defp ability_modifier(_), do: 0

  defp format_modifier(n) when n >= 0, do: "+#{n}"
  defp format_modifier(n), do: "#{n}"

  defp prof_bonus(level) when is_integer(level) do
    cond do
      level >= 17 -> 6
      level >= 13 -> 5
      level >= 9 -> 4
      level >= 5 -> 3
      true -> 2
    end
  end

  defp prof_bonus(_), do: 2

  defp monster_type_label(entity) do
    (entity.stats || %{})["monster_type"] ||
      (entity.race && String.capitalize(entity.race)) ||
      "Creature"
  end

  def dm_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-0.5 text-[10px] text-amber-400 bg-amber-900/40 border border-amber-700/60 rounded px-1 py-0 leading-4">
      <svg class="w-2.5 h-2.5" viewBox="0 0 20 20" fill="currentColor">
        <path d="M10 12a2 2 0 100-4 2 2 0 000 4z" />
        <path
          fill-rule="evenodd"
          d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z"
          clip-rule="evenodd"
        />
      </svg>
      DM
    </span>
    """
  end

  # ---------------------------------------------------------------------------
  # Event log helpers
  # ---------------------------------------------------------------------------

  defp event_label(%GibberingTales.Events.DnD5e.AttackResolved{} = e) do
    if e.hit?,
      do: "#{e.attacker_name} hits #{e.target_name} (roll #{e.roll})",
      else: "#{e.attacker_name} misses #{e.target_name} (roll #{e.roll})"
  end

  defp event_label(%GibberingTales.Events.DnD5e.DamageDealt{} = e) do
    "#{e.target_name} takes #{e.amount} damage (#{e.new_hp} HP left)"
  end

  defp event_label(%GibberingTales.Events.DnD5e.SpellCast{} = e) do
    "#{e.caster_name} casts #{e.spell_key} → #{e.target_name}: #{e.outcome}"
  end

  defp event_label(%GibberingEngine.Events.EntityMoved{} = e) do
    {fx, fy} = e.from
    {tx, ty} = e.to
    "#{e.entity_name} moves (#{fx},#{fy})→(#{tx},#{ty})"
  end

  defp event_label(%GibberingTales.Events.DnD5e.ConditionApplied{} = e) do
    "#{e.entity_name}: #{e.condition_id} applied"
  end

  defp event_label(%GibberingTales.Events.DnD5e.ConditionRemoved{} = e) do
    "#{e.entity_name}: #{e.condition_id} removed"
  end

  defp event_label(%GibberingEngine.Events.TurnAdvanced{} = e) do
    "Turn → #{e.to_entity_name || "end of round"}"
  end

  defp event_label(%GibberingEngine.Events.PhaseTransitioned{} = e) do
    "Phase: #{e.from_phase} → #{e.to_phase}"
  end

  defp event_label(%GibberingTales.Events.DnD5e.ItemTaken{} = e) do
    "Item taken: #{e.item_key} (×#{e.quantity})"
  end

  defp event_label(%GibberingTales.Events.DnD5e.ItemEquipped{} = e) do
    "Item equipped: #{e.item_key} in #{e.slot}"
  end

  defp event_label(%GibberingEngine.Events.HPAdjusted{} = e) do
    "#{e.entity_name} HP: #{e.old_hp} → #{e.new_hp}"
  end

  defp event_label(%GibberingEngine.Events.ContainerOpened{}), do: "Container opened"

  defp event_label(%GibberingEngine.Events.ResourceConsumed{} = e) do
    "#{e.entity_name}: #{e.resource_key} −#{e.amount_used} (#{e.remaining} left)"
  end

  defp event_label(%GibberingEngine.Events.LogEntryRevealed{}), do: nil
  defp event_label(%GibberingEngine.Events.LogEntryHidden{}), do: nil

  defp event_label(%FreeformRolled{} = e) do
    results_str =
      @dice_order
      |> Enum.filter(&Map.has_key?(e.results, &1))
      |> Enum.map_join(" + ", fn die ->
        vals = e.results[die] |> Enum.join(", ")
        "[#{vals}]"
      end)

    "#{e.roller_name} rolled #{die_expression(Map.to_list(e.dice_map))} → #{results_str} = #{e.total}"
  end

  defp event_label(_), do: nil

  # Returns structured parts for a feed entry: lists of
  # {:text, str} | {:entity_link, id, name} | {:tile_link, x, y, label} | {:spell_link, event_id, key}
  # Used by the right panel to render clickable inline elements.

  defp event_parts(%GibberingTales.Events.DnD5e.AttackResolved{} = e) do
    verb = if e.hit?, do: " hits ", else: " misses "

    [
      {:entity_link, e.attacker_id, e.attacker_name},
      {:text, verb},
      {:entity_link, e.target_id, e.target_name},
      {:text, " (roll #{e.roll})"}
    ]
  end

  defp event_parts(%GibberingTales.Events.DnD5e.DamageDealt{} = e) do
    [
      {:entity_link, e.target_id, e.target_name},
      {:text, " takes #{e.amount} damage (#{e.new_hp} HP left)"}
    ]
  end

  defp event_parts(%GibberingTales.Events.DnD5e.SpellCast{} = e) do
    [
      {:entity_link, e.caster_id, e.caster_name},
      {:text, " casts "},
      {:spell_link, e.event_id, e.spell_key},
      {:text, " → "},
      {:entity_link, e.target_id, e.target_name},
      {:text, ": #{e.outcome}"}
    ]
  end

  defp event_parts(%GibberingEngine.Events.EntityMoved{} = e) do
    {fx, fy} = e.from
    {tx, ty} = e.to

    [
      {:entity_link, e.entity_id, e.entity_name},
      {:tile_link, tx, ty, " moves (#{fx},#{fy})→(#{tx},#{ty})"}
    ]
  end

  defp event_parts(%GibberingTales.Events.DnD5e.ConditionApplied{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, ": #{e.condition_id} applied"}]
  end

  defp event_parts(%GibberingTales.Events.DnD5e.ConditionRemoved{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, ": #{e.condition_id} removed"}]
  end

  defp event_parts(%GibberingEngine.Events.TurnAdvanced{to_entity_id: id, to_entity_name: name})
       when not is_nil(id) do
    [{:text, "Turn → "}, {:entity_link, id, name}]
  end

  defp event_parts(%GibberingEngine.Events.TurnAdvanced{}), do: [{:text, "Turn → end of round"}]

  defp event_parts(%GibberingTales.Events.DnD5e.ItemTaken{} = e) do
    [{:entity_link, e.actor_id, "actor"}, {:text, " takes #{e.item_key} ×#{e.quantity}"}]
  end

  defp event_parts(%GibberingTales.Events.DnD5e.ItemEquipped{} = e) do
    [{:entity_link, e.actor_id, "actor"}, {:text, " equips #{e.item_key} (#{e.slot})"}]
  end

  defp event_parts(%GibberingEngine.Events.HPAdjusted{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, " HP: #{e.old_hp} → #{e.new_hp}"}]
  end

  defp event_parts(%FreeformRolled{} = e) do
    [{:text, event_label(e)}]
  end

  defp event_parts(event) do
    label = event_label(event)
    if label, do: [{:text, label}], else: []
  end

  # ---------------------------------------------------------------------------
  # Freeform dice helpers
  # ---------------------------------------------------------------------------

  defp die_expression(active_dice) do
    active_dice
    |> Enum.sort_by(fn {die, _} -> Enum.find_index(@dice_order, &(&1 == die)) end)
    |> Enum.map_join(" + ", fn {die, count} -> "#{count}#{die}" end)
  end

  # ---------------------------------------------------------------------------
  # Tile decoration components
  # ---------------------------------------------------------------------------

  defp decoration_sprite(%{decoration: "dead_tree"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"} data-decoration={@decoration}>
      <ellipse cx="32" cy="60" rx="10" ry="3" fill="rgba(0,0,0,0.3)" />
      <rect
        x="29"
        y="28"
        width="6"
        height="32"
        rx="2"
        fill="#4a3018"
        stroke="#111"
        stroke-width="1.5"
      />
      <path
        d="M29,58 Q20,62 16,60"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M35,58 Q44,62 48,60"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M31,35 Q17,28 11,20"
        stroke="#4a3018"
        stroke-width="4"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M11,20 Q7,13 9,9"
        stroke="#4a3018"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M33,38 Q47,30 53,22"
        stroke="#4a3018"
        stroke-width="3.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M53,22 Q57,15 55,11"
        stroke="#4a3018"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M32,30 Q27,22 25,15"
        stroke="#4a3018"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "rock_cluster"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"} data-decoration={@decoration}>
      <ellipse cx="30" cy="60" rx="18" ry="5" fill="rgba(0,0,0,0.3)" />
      <polygon
        points="16,56 12,42 22,32 38,32 46,42 42,56"
        fill="#787878"
        stroke="#111"
        stroke-width="2"
      />
      <polygon points="38,56 36,46 48,42 52,52" fill="#888" stroke="#111" stroke-width="1.5" />
      <ellipse cx="18" cy="56" rx="5" ry="3" fill="#6a6a6a" stroke="#111" stroke-width="1" />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "bones"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"} data-decoration={@decoration}>
      <ellipse cx="26" cy="52" rx="7" ry="6" fill="#d8d0b0" stroke="#111" stroke-width="1.5" />
      <rect x="23" y="56" width="6" height="5" rx="1" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <line x1="24" y1="50" x2="48" y2="44" stroke="#d8d0b0" stroke-width="3" stroke-linecap="round" />
      <circle cx="24" cy="50" r="3" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <circle cx="48" cy="44" r="3" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <line
        x1="30"
        y1="58"
        x2="50"
        y2="56"
        stroke="#d8d0b0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <circle cx="30" cy="58" r="2.5" fill="#d8d0b0" stroke="#111" stroke-width="1" />
      <circle cx="50" cy="56" r="2.5" fill="#d8d0b0" stroke="#111" stroke-width="1" />
    </g>
    """
  end

  defp decoration_sprite(%{decoration: "grass_tuft"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"} data-decoration={@decoration}>
      <path
        d="M22,58 Q18,50 16,42"
        stroke="#4a7830"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M27,58 Q23,48 21,38"
        stroke="#5a8a40"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M32,58 Q31,46 32,34"
        stroke="#6a9a4a"
        stroke-width="3"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M37,58 Q41,47 43,38"
        stroke="#5a8a40"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M42,58 Q46,50 48,42"
        stroke="#4a7830"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
    </g>
    """
  end

  defp decoration_sprite(assigns), do: ~H""
end
