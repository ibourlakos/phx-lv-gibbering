defmodule GibberingWeb.GameLive do
  use GibberingWeb, :live_view

  alias Gibbering.Engine.{SceneServer, State, Rules, SpriteCompositor}
  alias Gibbering.{Campaigns, CampaignCharacters, EventBus}
  alias Gibbering.Events.{EventBatch}
  alias Gibbering.Events.Notification.{BroadcastSent, WhisperDelivered}
  alias Gibbering.Events.Scene.{RollRequired, SessionEnded, TurnAdvanced}
  alias Gibbering.Catalogue
  alias Gibbering.Data.Spells

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

          appearances =
            Catalogue.appearances_for_style(Catalogue.default_style_slug())

          campaign_character =
            if is_dm, do: nil, else: CampaignCharacters.get_active_for_player(game_id, user.id)

          {:ok,
           socket
           |> assign(:game_id, game_id)
           |> assign(:game_state, state)
           |> assign(:is_dm, is_dm)
           |> assign(:appearances, appearances)
           |> assign(:show_end_confirm, false)
           |> assign(:valid_targets, [])
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
           |> assign(:dm_intervene_entity_id, nil)}

        {:error, reason} ->
          {:ok,
           socket
           |> put_flash(:error, "Game #{game_id} could not be loaded: #{inspect(reason)}")
           |> redirect(to: "/")}
      end
    end
  end

  @impl true
  def handle_event("select_entity", %{"id" => id}, socket) do
    id = String.to_integer(id)
    new_state = SceneServer.select_entity(socket.assigns.game_id, id)

    {:noreply,
     assign(socket,
       game_state: new_state,
       valid_targets: new_state.valid_targets,
       panel_subject: {:entity, id}
     )}
  end

  @impl true
  def handle_event("deselect", _, socket) do
    new_state = SceneServer.deselect_entity(socket.assigns.game_id)
    {:noreply, assign(socket, game_state: new_state, valid_targets: [])}
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
    event = Enum.find(socket.assigns.event_log, &(&1.event_id == event_id))
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
      {:noreply, assign(socket, game_state: new_state)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("activate_move", _, socket) do
    new_state = SceneServer.activate_move(socket.assigns.game_id)
    {:noreply, assign(socket, game_state: new_state)}
  end

  @impl true
  def handle_event("cancel_move", _, socket) do
    new_state = SceneServer.cancel_move(socket.assigns.game_id)
    {:noreply, assign(socket, game_state: new_state)}
  end

  @impl true
  def handle_event("move", %{"x" => x, "y" => y}, socket) do
    new_state =
      SceneServer.move_entity(socket.assigns.game_id, String.to_integer(x), String.to_integer(y))

    {:noreply, assign(socket, game_state: new_state, valid_targets: new_state.valid_targets)}
  end

  @impl true
  def handle_event("inspect_tile", %{"x" => x, "y" => y}, socket) do
    game_state = socket.assigns.game_state

    if game_state.valid_moves != [] do
      new_state = SceneServer.cancel_move(socket.assigns.game_id)
      {:noreply, assign(socket, game_state: new_state)}
    else
      {:noreply,
       assign(socket, panel_subject: {:tile, String.to_integer(x), String.to_integer(y)})}
    end
  end

  @impl true
  def handle_event("attack", %{"id" => target_id}, socket) do
    target_id = String.to_integer(target_id)
    state = socket.assigns.game_state
    target_name = state.entities[target_id].name

    attacker_id = state.actor_id
    attacker_name = if attacker_id, do: state.entities[attacker_id].name, else: "?"

    new_state =
      SceneServer.attack_entity(socket.assigns.game_id, target_id,
        auto_roll: socket.assigns.auto_roll
      )

    if new_state.awaiting_roll do
      {:noreply, assign(socket, game_state: new_state)}
    else
      damage =
        if Map.has_key?(new_state.entities, target_id) do
          state.entities[target_id].hp - new_state.entities[target_id].hp
        else
          state.entities[target_id].hp
        end

      dice_result = max(min(damage, 6), 1)

      log_entry =
        if Map.has_key?(new_state.entities, target_id) do
          hp = new_state.entities[target_id].hp
          "#{attacker_name} hits #{target_name} for #{damage}! (#{hp} HP left)"
        else
          "#{target_name} destroyed!"
        end

      {:noreply,
       socket
       |> assign(game_state: new_state, valid_targets: [])
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
     assign(socket, selected_spell: spell_key, spell_targets: spell_targets, valid_targets: [])}
  end

  @impl true
  def handle_event("cast_spell", %{"id" => target_id}, socket) do
    target_id = String.to_integer(target_id)
    state = socket.assigns.game_state
    spell_key = socket.assigns.selected_spell

    caster_id = state.actor_id
    caster_name = if caster_id, do: state.entities[caster_id].name, else: "?"
    target_name = state.entities[target_id].name
    spell = Spells.get(spell_key)
    spell_name = if spell, do: spell.name, else: spell_key

    new_state =
      SceneServer.cast_spell(socket.assigns.game_id, spell_key, target_id,
        auto_roll: socket.assigns.auto_roll
      )

    if new_state.awaiting_roll do
      {:noreply, assign(socket, game_state: new_state)}
    else
      {damage, log_entry} =
        if Map.has_key?(new_state.entities, target_id) do
          dmg = state.entities[target_id].hp - new_state.entities[target_id].hp
          hp = new_state.entities[target_id].hp

          {max(dmg, 0),
           "#{caster_name} casts #{spell_name} → #{target_name} for #{dmg}! (#{hp} HP left)"}
        else
          {state.entities[target_id].hp,
           "#{caster_name} casts #{spell_name} → #{target_name} destroyed!"}
        end

      dice_result = max(min(damage, 6), 1)

      {:noreply,
       socket
       |> assign(
         game_state: new_state,
         valid_targets: [],
         selected_spell: nil,
         spell_targets: []
       )
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
     assign(socket,
       game_state: new_state,
       valid_targets: [],
       selected_spell: nil,
       spell_targets: []
     )}
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
    entity = socket.assigns.game_state.entities[id]
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
          if batch.state_snapshot, do: assign(s, game_state: batch.state_snapshot), else: s
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
        if batch.state_snapshot && !batch.state_snapshot.awaiting_roll &&
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

  defp ruleset_action_buttons(nil, _state), do: []
  defp ruleset_action_buttons(entity, state), do: state.ruleset.action_buttons(entity, state)

  defp ruleset_conditions(state), do: state.ruleset.available_conditions()

  # ---------------------------------------------------------------------------
  # Inspection panel helpers
  # ---------------------------------------------------------------------------

  defp inspect_content(nil, _state, _is_dm), do: nil

  defp inspect_content({:entity, entity_id}, state, is_dm) do
    case Map.get(state.entities, entity_id) do
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
  # Appearance helpers — delegate to the active style's DB records.
  # Fallback colours ensure graceful degradation when no record exists.
  # ---------------------------------------------------------------------------

  defp tile_fill(appearances, texture) do
    (appearances[{"tile", texture, "default"}] || %{})["fill"] || "#7f8c8d"
  end

  defp tile_stroke(appearances, texture) do
    (appearances[{"tile", texture, "default"}] || %{})["stroke"] || "#5d6d7e"
  end

  defp entity_body_color(appearances, sprite) do
    (appearances[{"entity", sprite, "default"}] || %{})["body_color"] || "#7f8c8d"
  end

  # ---------------------------------------------------------------------------
  # Event log helpers
  # ---------------------------------------------------------------------------

  defp event_label(%Gibbering.Events.Scene.AttackResolved{} = e) do
    if e.hit?,
      do: "#{e.attacker_name} hits #{e.target_name} (roll #{e.roll})",
      else: "#{e.attacker_name} misses #{e.target_name} (roll #{e.roll})"
  end

  defp event_label(%Gibbering.Events.Scene.DamageDealt{} = e) do
    "#{e.target_name} takes #{e.amount} damage (#{e.new_hp} HP left)"
  end

  defp event_label(%Gibbering.Events.Scene.SpellCast{} = e) do
    "#{e.caster_name} casts #{e.spell_key} → #{e.target_name}: #{e.outcome}"
  end

  defp event_label(%Gibbering.Events.Scene.EntityMoved{} = e) do
    {fx, fy} = e.from
    {tx, ty} = e.to
    "#{e.entity_name} moves (#{fx},#{fy})→(#{tx},#{ty})"
  end

  defp event_label(%Gibbering.Events.Scene.ConditionApplied{} = e) do
    "#{e.entity_name}: #{e.condition_id} applied"
  end

  defp event_label(%Gibbering.Events.Scene.ConditionRemoved{} = e) do
    "#{e.entity_name}: #{e.condition_id} removed"
  end

  defp event_label(%Gibbering.Events.Scene.TurnAdvanced{} = e) do
    "Turn → #{e.to_entity_name || "end of round"}"
  end

  defp event_label(%Gibbering.Events.Scene.PhaseTransitioned{} = e) do
    "Phase: #{e.from_phase} → #{e.to_phase}"
  end

  defp event_label(%Gibbering.Events.Scene.ItemTaken{} = e) do
    "Item taken: #{e.item_key} (×#{e.quantity})"
  end

  defp event_label(%Gibbering.Events.Scene.ItemEquipped{} = e) do
    "Item equipped: #{e.item_key} in #{e.slot}"
  end

  defp event_label(%Gibbering.Events.Scene.HPAdjusted{} = e) do
    "#{e.entity_name} HP: #{e.old_hp} → #{e.new_hp}"
  end

  defp event_label(%Gibbering.Events.Scene.ContainerOpened{}), do: "Container opened"

  defp event_label(%Gibbering.Events.Scene.ResourceConsumed{} = e) do
    "#{e.entity_name}: #{e.resource_key} −#{e.amount_used} (#{e.remaining} left)"
  end

  defp event_label(%Gibbering.Events.Scene.LogEntryRevealed{}), do: nil
  defp event_label(%Gibbering.Events.Scene.LogEntryHidden{}), do: nil
  defp event_label(_), do: nil

  # Returns structured parts for a feed entry: lists of
  # {:text, str} | {:entity_link, id, name} | {:tile_link, x, y, label} | {:spell_link, event_id, key}
  # Used by the right panel to render clickable inline elements.

  defp event_parts(%Gibbering.Events.Scene.AttackResolved{} = e) do
    verb = if e.hit?, do: " hits ", else: " misses "

    [
      {:entity_link, e.attacker_id, e.attacker_name},
      {:text, verb},
      {:entity_link, e.target_id, e.target_name},
      {:text, " (roll #{e.roll})"}
    ]
  end

  defp event_parts(%Gibbering.Events.Scene.DamageDealt{} = e) do
    [
      {:entity_link, e.target_id, e.target_name},
      {:text, " takes #{e.amount} damage (#{e.new_hp} HP left)"}
    ]
  end

  defp event_parts(%Gibbering.Events.Scene.SpellCast{} = e) do
    [
      {:entity_link, e.caster_id, e.caster_name},
      {:text, " casts "},
      {:spell_link, e.event_id, e.spell_key},
      {:text, " → "},
      {:entity_link, e.target_id, e.target_name},
      {:text, ": #{e.outcome}"}
    ]
  end

  defp event_parts(%Gibbering.Events.Scene.EntityMoved{} = e) do
    {fx, fy} = e.from
    {tx, ty} = e.to

    [
      {:entity_link, e.entity_id, e.entity_name},
      {:tile_link, tx, ty, " moves (#{fx},#{fy})→(#{tx},#{ty})"}
    ]
  end

  defp event_parts(%Gibbering.Events.Scene.ConditionApplied{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, ": #{e.condition_id} applied"}]
  end

  defp event_parts(%Gibbering.Events.Scene.ConditionRemoved{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, ": #{e.condition_id} removed"}]
  end

  defp event_parts(%Gibbering.Events.Scene.TurnAdvanced{to_entity_id: id, to_entity_name: name})
       when not is_nil(id) do
    [{:text, "Turn → "}, {:entity_link, id, name}]
  end

  defp event_parts(%Gibbering.Events.Scene.TurnAdvanced{}), do: [{:text, "Turn → end of round"}]

  defp event_parts(%Gibbering.Events.Scene.ItemTaken{} = e) do
    [{:entity_link, e.actor_id, "actor"}, {:text, " takes #{e.item_key} ×#{e.quantity}"}]
  end

  defp event_parts(%Gibbering.Events.Scene.ItemEquipped{} = e) do
    [{:entity_link, e.actor_id, "actor"}, {:text, " equips #{e.item_key} (#{e.slot})"}]
  end

  defp event_parts(%Gibbering.Events.Scene.HPAdjusted{} = e) do
    [{:entity_link, e.entity_id, e.entity_name}, {:text, " HP: #{e.old_hp} → #{e.new_hp}"}]
  end

  defp event_parts(event) do
    label = event_label(event)
    if label, do: [{:text, label}], else: []
  end

  # ---------------------------------------------------------------------------
  # Entity sprite components — inline SVG, DST-style ink aesthetic.
  # Each sprite is a 64×64 box; feet/shadow sit at local y≈60.
  # ---------------------------------------------------------------------------

  # Legacy sprites kept for backwards compat
  def entity_sprite(%{sprite: "warrior"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="18" ry="6" fill="rgba(0,0,0,0.4)" />
      <rect x="20" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="35" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="17" y="22" width="30" height="24" rx="3" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <rect x="17" y="42" width="30" height="4" fill="#8b6020" stroke="#111" stroke-width="1" />
      <ellipse cx="13" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <ellipse cx="51" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="14" rx="11" ry="11" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path d="M21,15 Q32,2 43,15" fill="#3a5075" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
    </g>
    """
  end

  def entity_sprite(%{sprite: "wizard"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <path d="M26,22 L20,58 L44,58 L38,22 Z" fill="#6040a0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="26" x2="30" y2="54" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#7b5ea7"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
      <ellipse cx="32" cy="8" rx="14" ry="3" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <polygon points="32,0 19,9 45,9" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <line x1="47" y1="10" x2="45" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <circle cx="47" cy="8" r="5" fill="#c090e8" stroke="#111" stroke-width="1.5" />
    </g>
    """
  end

  # Human Fighter — stocky build, blue plate armour, brown hair, sword+shield
  def entity_sprite(%{sprite: "human_fighter"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="18" ry="6" fill="rgba(0,0,0,0.4)" />
      <%!-- legs --%>
      <rect x="20" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="35" y="44" width="9" height="16" rx="2" fill="#3a5075" stroke="#111" stroke-width="2" />
      <%!-- torso plate --%>
      <rect x="17" y="22" width="30" height="24" rx="3" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <line x1="32" y1="22" x2="32" y2="46" stroke="#3a5075" stroke-width="1.5" />
      <rect x="17" y="42" width="30" height="4" fill="#8b6020" stroke="#111" stroke-width="1" />
      <%!-- shield arm left --%>
      <rect x="7" y="22" width="11" height="16" rx="3" fill="#3a5075" stroke="#111" stroke-width="2" />
      <rect x="8" y="23" width="9" height="14" rx="2" fill="#c5a028" stroke="#111" stroke-width="1" />
      <line x1="12" y1="26" x2="12" y2="36" stroke="#8b6020" stroke-width="1" />
      <line x1="9" y1="30" x2="16" y2="30" stroke="#8b6020" stroke-width="1" />
      <%!-- sword arm right --%>
      <ellipse cx="51" cy="27" rx="6" ry="8" fill="#3a5075" stroke="#111" stroke-width="2" />
      <line x1="55" y1="15" x2="55" y2="52" stroke="#a0a8b0" stroke-width="3" stroke-linecap="round" />
      <rect x="51" y="30" width="8" height="3" rx="1" fill="#a0a8b0" stroke="#111" stroke-width="1" />
      <%!-- head --%>
      <ellipse cx="32" cy="14" rx="11" ry="11" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path d="M21,15 Q32,2 43,15" fill="#4a6fa5" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="5" rx="8" ry="4" fill="#3a5075" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
    </g>
    """
  end

  # Human Wizard — robes, tall hat, warm skin, oak staff
  def entity_sprite(%{sprite: "human_wizard"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <path d="M26,22 L20,58 L44,58 L38,22 Z" fill="#6040a0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="26" x2="30" y2="54" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#7b5ea7"
        stroke="#111"
        stroke-width="1.5"
      />
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <%!-- brown hair showing --%>
      <path d="M22,14 Q24,8 32,7 Q40,8 42,14" fill="#6b3a1f" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="14" r="1.5" fill="#111" />
      <circle cx="36" cy="14" r="1.5" fill="#111" />
      <ellipse cx="32" cy="8" rx="14" ry="3" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <polygon points="32,0 19,9 45,9" fill="#3b2060" stroke="#111" stroke-width="1.5" />
      <line x1="47" y1="10" x2="45" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <circle cx="47" cy="8" r="5" fill="#c090e8" stroke="#111" stroke-width="1.5" />
    </g>
    """
  end

  # Human Rogue — leather armour, hood, twin daggers, dark tones
  def entity_sprite(%{sprite: "human_rogue"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.4)" />
      <%!-- legs --%>
      <rect
        x="21"
        y="44"
        width="8"
        height="15"
        rx="2"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="35"
        y="44"
        width="8"
        height="15"
        rx="2"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- leather torso --%>
      <rect x="19" y="22" width="26" height="24" rx="3" fill="#6b4c38" stroke="#111" stroke-width="2" />
      <line x1="32" y1="22" x2="32" y2="46" stroke="#4a3020" stroke-width="1" />
      <%!-- arms --%>
      <ellipse cx="14" cy="30" rx="5" ry="8" fill="#5a3d28" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="30" rx="5" ry="8" fill="#5a3d28" stroke="#111" stroke-width="1.5" />
      <%!-- daggers --%>
      <line
        x1="10"
        y1="20"
        x2="12"
        y2="44"
        stroke="#b0b8c0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <rect x="8" y="28" width="6" height="2" rx="1" fill="#888" stroke="#111" stroke-width="1" />
      <line
        x1="53"
        y1="20"
        x2="51"
        y2="44"
        stroke="#b0b8c0"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <rect x="49" y="28" width="6" height="2" rx="1" fill="#888" stroke="#111" stroke-width="1" />
      <%!-- head with hood --%>
      <ellipse cx="32" cy="14" rx="10" ry="10" fill="#c9a87c" stroke="#111" stroke-width="2" />
      <path
        d="M22,14 Q22,4 32,3 Q42,4 42,14 L42,18 Q36,16 32,16 Q28,16 22,18 Z"
        fill="#3d2a1a"
        stroke="#111"
        stroke-width="1.5"
      />
      <circle cx="28" cy="15" r="1.5" fill="#111" />
      <circle cx="36" cy="15" r="1.5" fill="#111" />
    </g>
    """
  end

  # Elf Fighter — slender plate, high cheekbones, pointed ears, silver-green armour
  def entity_sprite(%{sprite: "elf_fighter"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="16" ry="5" fill="rgba(0,0,0,0.4)" />
      <%!-- slender legs --%>
      <rect x="22" y="44" width="8" height="16" rx="2" fill="#3a6050" stroke="#111" stroke-width="2" />
      <rect x="34" y="44" width="8" height="16" rx="2" fill="#3a6050" stroke="#111" stroke-width="2" />
      <%!-- elegant torso plate --%>
      <rect x="19" y="22" width="26" height="24" rx="4" fill="#5a8f6a" stroke="#111" stroke-width="2" />
      <path d="M32,22 L32,46" stroke="#3a6050" stroke-width="1.5" />
      <rect x="19" y="42" width="26" height="4" fill="#4a7860" stroke="#111" stroke-width="1" />
      <%!-- shield --%>
      <ellipse cx="12" cy="30" rx="7" ry="9" fill="#3a6050" stroke="#111" stroke-width="2" />
      <path d="M8,25 Q12,22 16,25 L16,35 Q12,38 8,35 Z" fill="#5a8f6a" stroke="none" />
      <%!-- spear arm --%>
      <ellipse cx="51" cy="27" rx="5" ry="8" fill="#3a6050" stroke="#111" stroke-width="1.5" />
      <line x1="54" y1="4" x2="52" y2="58" stroke="#a0a8b0" stroke-width="2.5" stroke-linecap="round" />
      <polygon points="54,4 51,12 57,12" fill="#d0d8e0" stroke="#111" stroke-width="1" />
      <%!-- elven head: taller, angular, pointed ears --%>
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <%!-- silver hair --%>
      <path d="M23,12 Q32,2 41,12" fill="#c0c8d0" stroke="#111" stroke-width="1.5" />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
    </g>
    """
  end

  # Elf Wizard — flowing silver-purple robes, long silver hair, arcane staff with gem
  def entity_sprite(%{sprite: "elf_wizard"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="14" ry="5" fill="rgba(0,0,0,0.4)" />
      <%!-- flowing robe, more elegant silhouette --%>
      <path d="M24,22 L16,58 L48,58 L40,22 Z" fill="#5030a0" stroke="#111" stroke-width="2" />
      <path d="M24,22 L20,58" stroke="#7050c0" stroke-width="1" />
      <path d="M40,22 L44,58" stroke="#7050c0" stroke-width="1" />
      <line x1="32" y1="26" x2="32" y2="58" stroke="#7a55b8" stroke-width="1.5" />
      <rect
        x="26"
        y="19"
        width="12"
        height="6"
        rx="2"
        fill="#8060c0"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- elven face: tall, pale, pointed ears --%>
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <%!-- silver hair flowing back --%>
      <path d="M23,12 Q32,0 41,12" fill="#c8d0e0" stroke="#111" stroke-width="1.5" />
      <path d="M41,12 Q46,18 44,26" stroke="#c8d0e0" stroke-width="2" fill="none" />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
      <%!-- arcane staff with floating gem --%>
      <line x1="48" y1="8" x2="46" y2="58" stroke="#8a6828" stroke-width="2.5" stroke-linecap="round" />
      <ellipse cx="48" cy="6" rx="6" ry="7" fill="#60e0ff" stroke="#111" stroke-width="1.5" />
      <ellipse cx="48" cy="6" rx="3" ry="4" fill="#a0f0ff" stroke="none" />
    </g>
    """
  end

  # Elf Rogue — shadow cloak, curved blades, graceful posture
  def entity_sprite(%{sprite: "elf_rogue"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="14" ry="4" fill="rgba(0,0,0,0.4)" />
      <%!-- long legs --%>
      <rect
        x="22"
        y="44"
        width="7"
        height="16"
        rx="2"
        fill="#2a3a30"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="35"
        y="44"
        width="7"
        height="16"
        rx="2"
        fill="#2a3a30"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- shadow cloak body --%>
      <path d="M20,22 L14,58 L50,58 L44,22 Z" fill="#1e2e28" stroke="#111" stroke-width="2" />
      <path d="M20,22 L16,58" stroke="#2e4038" stroke-width="1" />
      <path d="M44,22 L48,58" stroke="#2e4038" stroke-width="1" />
      <%!-- arms --%>
      <ellipse cx="14" cy="30" rx="4" ry="7" fill="#2a3a30" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="30" rx="4" ry="7" fill="#2a3a30" stroke="#111" stroke-width="1.5" />
      <%!-- curved elven blades --%>
      <path
        d="M10,44 Q8,32 12,20"
        stroke="#c8d8e0"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <path
        d="M54,44 Q56,32 52,20"
        stroke="#c8d8e0"
        stroke-width="2.5"
        fill="none"
        stroke-linecap="round"
      />
      <%!-- elven head with hood --%>
      <ellipse cx="32" cy="13" rx="9" ry="12" fill="#dbbf8a" stroke="#111" stroke-width="2" />
      <polygon points="23,10 20,4 25,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <polygon points="41,10 44,4 39,10" fill="#dbbf8a" stroke="#111" stroke-width="1.5" />
      <path
        d="M23,10 Q23,2 32,1 Q41,2 41,10 L42,16 Q36,14 32,14 Q28,14 22,16 Z"
        fill="#1e2e28"
        stroke="#111"
        stroke-width="1.5"
      />
      <circle cx="28" cy="13" r="1.5" fill="#111" />
      <circle cx="36" cy="13" r="1.5" fill="#111" />
    </g>
    """
  end

  # Gnome Fighter — very short, round head, big helm, oversized axes
  def entity_sprite(%{sprite: "gnome_fighter"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="15" ry="5" fill="rgba(0,0,0,0.4)" />
      <%!-- short stubby legs --%>
      <rect x="22" y="48" width="8" height="12" rx="2" fill="#5c3a1a" stroke="#111" stroke-width="2" />
      <rect x="34" y="48" width="8" height="12" rx="2" fill="#5c3a1a" stroke="#111" stroke-width="2" />
      <%!-- wide stocky torso --%>
      <rect x="16" y="30" width="32" height="20" rx="4" fill="#8b4513" stroke="#111" stroke-width="2" />
      <line x1="32" y1="30" x2="32" y2="50" stroke="#5c2a08" stroke-width="1.5" />
      <%!-- big arms --%>
      <ellipse cx="11" cy="38" rx="6" ry="9" fill="#6b3510" stroke="#111" stroke-width="2" />
      <ellipse cx="53" cy="38" rx="6" ry="9" fill="#6b3510" stroke="#111" stroke-width="2" />
      <%!-- battle axe right --%>
      <line x1="56" y1="15" x2="54" y2="58" stroke="#7a5820" stroke-width="3" stroke-linecap="round" />
      <path d="M56,15 Q65,10 62,22 Q59,28 54,26 Z" fill="#b0b8c0" stroke="#111" stroke-width="1.5" />
      <path d="M56,15 Q60,8 64,18 Q61,24 56,22 Z" fill="#9090a0" stroke="none" />
      <%!-- round gnome head with big helm --%>
      <ellipse cx="32" cy="26" rx="12" ry="12" fill="#d4956a" stroke="#111" stroke-width="2" />
      <circle cx="28" cy="26" r="1.5" fill="#111" />
      <circle cx="36" cy="26" r="1.5" fill="#111" />
      <path d="M22,22 L22,14 Q32,8 42,14 L42,22" fill="#8b4513" stroke="#111" stroke-width="2" />
      <rect
        x="20"
        y="13"
        width="24"
        height="6"
        rx="2"
        fill="#7a3a10"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- cheeks --%>
      <circle cx="26" cy="28" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="38" cy="28" r="2.5" fill="#e8706a" fill-opacity="0.5" />
    </g>
    """
  end

  # Gnome Wizard — tiny pointy hat, big eyes, oversized robes, elaborate staff
  def entity_sprite(%{sprite: "gnome_wizard"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="12" ry="4" fill="rgba(0,0,0,0.4)" />
      <%!-- tiny legs hidden under robe --%>
      <path d="M24,38 L20,60 L44,60 L40,38 Z" fill="#7040c0" stroke="#111" stroke-width="2" />
      <line x1="32" y1="40" x2="32" y2="60" stroke="#8050d0" stroke-width="1.5" />
      <rect
        x="24"
        y="35"
        width="16"
        height="6"
        rx="2"
        fill="#9060d0"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- big round head --%>
      <ellipse cx="32" cy="26" rx="12" ry="12" fill="#d4956a" stroke="#111" stroke-width="2" />
      <%!-- oversized eyes --%>
      <circle cx="27" cy="26" r="3" fill="white" stroke="#111" stroke-width="1.5" />
      <circle cx="37" cy="26" r="3" fill="white" stroke="#111" stroke-width="1.5" />
      <circle cx="27" cy="26" r="1.5" fill="#3060c0" />
      <circle cx="37" cy="26" r="1.5" fill="#3060c0" />
      <%!-- cheeks --%>
      <circle cx="24" cy="29" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="40" cy="29" r="2.5" fill="#e8706a" fill-opacity="0.5" />
      <%!-- tall gnome wizard hat --%>
      <polygon points="32,2 20,20 44,20" fill="#4020a0" stroke="#111" stroke-width="2" />
      <ellipse cx="32" cy="20" rx="13" ry="4" fill="#5030b0" stroke="#111" stroke-width="1.5" />
      <circle cx="32" cy="2" r="3" fill="#f0d060" stroke="#111" stroke-width="1" />
      <%!-- tiny elaborate staff --%>
      <line
        x1="48"
        y1="20"
        x2="46"
        y2="62"
        stroke="#6a4810"
        stroke-width="2.5"
        stroke-linecap="round"
      />
      <ellipse cx="48" cy="18" rx="5" ry="5" fill="#f0c060" stroke="#111" stroke-width="1.5" />
      <circle cx="48" cy="18" r="2" fill="white" />
    </g>
    """
  end

  # Gnome Rogue — tiny figure, big goggles, pack of gadgets, short knives
  def entity_sprite(%{sprite: "gnome_rogue"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="12" ry="4" fill="rgba(0,0,0,0.4)" />
      <%!-- short legs --%>
      <rect
        x="23"
        y="48"
        width="7"
        height="12"
        rx="2"
        fill="#3a2a20"
        stroke="#111"
        stroke-width="1.5"
      />
      <rect
        x="34"
        y="48"
        width="7"
        height="12"
        rx="2"
        fill="#3a2a20"
        stroke="#111"
        stroke-width="1.5"
      />
      <%!-- gnome body with packs and gadgets --%>
      <rect x="19" y="30" width="26" height="20" rx="3" fill="#5d4037" stroke="#111" stroke-width="2" />
      <rect x="23" y="30" width="6" height="8" rx="1" fill="#4a3020" stroke="#111" stroke-width="1" />
      <rect x="35" y="30" width="6" height="8" rx="1" fill="#4a3020" stroke="#111" stroke-width="1" />
      <%!-- arms --%>
      <ellipse cx="14" cy="38" rx="5" ry="7" fill="#4a3020" stroke="#111" stroke-width="1.5" />
      <ellipse cx="50" cy="38" rx="5" ry="7" fill="#4a3020" stroke="#111" stroke-width="1.5" />
      <%!-- short knives --%>
      <line x1="10" y1="44" x2="12" y2="30" stroke="#b8c0c8" stroke-width="2" stroke-linecap="round" />
      <line x1="54" y1="44" x2="52" y2="30" stroke="#b8c0c8" stroke-width="2" stroke-linecap="round" />
      <%!-- big round head --%>
      <ellipse cx="32" cy="25" rx="11" ry="11" fill="#d4956a" stroke="#111" stroke-width="2" />
      <%!-- goggles --%>
      <ellipse cx="27" cy="25" rx="4" ry="3.5" fill="#2a2a2a" stroke="#111" stroke-width="1.5" />
      <ellipse cx="37" cy="25" rx="4" ry="3.5" fill="#2a2a2a" stroke="#111" stroke-width="1.5" />
      <circle cx="27" cy="25" r="2" fill="#40c060" fill-opacity="0.7" />
      <circle cx="37" cy="25" r="2" fill="#40c060" fill-opacity="0.7" />
      <rect x="31" y="24" width="2" height="2" rx="1" fill="#2a2a2a" />
      <%!-- cheeks --%>
      <circle cx="24" cy="28" r="2" fill="#e8706a" fill-opacity="0.5" />
      <circle cx="40" cy="28" r="2" fill="#e8706a" fill-opacity="0.5" />
    </g>
    """
  end

  def entity_sprite(%{sprite: "rock"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      <ellipse cx="32" cy="60" rx="22" ry="7" fill="rgba(0,0,0,0.4)" />
      <polygon
        points="12,56 8,36 16,20 34,14 52,20 56,38 48,56"
        fill="#787878"
        stroke="#111"
        stroke-width="2.5"
      />
      <polygon points="20,52 16,36 24,24 40,22 48,34 44,52" fill="#6a6a6a" stroke="none" />
      <path
        d="M26,24 L22,40 L26,52"
        stroke="#505050"
        stroke-width="2"
        fill="none"
        stroke-linecap="round"
      />
      <polygon points="44,56 42,46 54,44 56,54" fill="#888" stroke="#111" stroke-width="2" />
    </g>
    """
  end

  def entity_sprite(assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
      {Phoenix.HTML.raw(Gibbering.Engine.AppearanceArchetype.render_body(@entity, @appearances))}
    </g>
    """
  end

  # ---------------------------------------------------------------------------
  # Tile decoration components
  # ---------------------------------------------------------------------------

  defp decoration_sprite(%{decoration: "dead_tree"} = assigns) do
    ~H"""
    <g transform={"translate(#{@x}, #{@y})"}>
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
    <g transform={"translate(#{@x}, #{@y})"}>
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
    <g transform={"translate(#{@x}, #{@y})"}>
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
    <g transform={"translate(#{@x}, #{@y})"}>
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
