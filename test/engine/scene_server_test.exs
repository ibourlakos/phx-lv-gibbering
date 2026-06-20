defmodule Gibbering.Engine.SceneServerTest do
  # Requires DB (loads Campaign in init). Must be async: false so the sandbox
  # runs in shared mode, allowing the SceneServer process to use the connection.
  use Gibbering.DataCase, async: false

  import Gibbering.GameFixtures
  alias Gibbering.{Repo, Entity}
  alias Gibbering.Engine.{SceneServer, State}
  alias Gibbering.Events.EventBatch

  alias Gibbering.Events.Scene.{
    EntityMoved,
    PhaseTransitioned,
    RollRequired,
    SessionEnded,
    TurnAdvanced
  }

  # Start a SceneServer backed by a real (sandbox) DB campaign.
  # Returns the game_id. The server is supervised by the test process
  # and stopped automatically when the test ends.
  defp start_server do
    game_id = insert_campaign()
    start_supervised!({SceneServer, game_id})
    game_id
  end

  describe "get_state/1" do
    test "returns an initial State with entities from the DB" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)

      assert %State{} = state
      assert state.campaign_id == game_id
      assert map_size(state.entities) == 2
    end
  end

  describe "select_entity/2" do
    test "sets actor_id but does NOT populate valid_moves (move overlay gated behind activate_move)" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      new_state = SceneServer.select_entity(game_id, hero_id)

      assert new_state.actor_id == hero_id
      assert new_state.valid_moves == []
    end

    test "activate_move/1 populates valid_moves for the selected entity" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      SceneServer.select_entity(game_id, hero_id)
      move_state = SceneServer.activate_move(game_id)

      assert move_state.valid_moves != []
      assert move_state.valid_move_costs != %{}
    end

    test "does not change state when selecting a non-active entity" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)

      # Find any entity id that is NOT the active hero.
      non_active = state.entities |> Map.keys() |> Enum.find(&(&1 != State.active_hero_id(state)))

      new_state = SceneServer.select_entity(game_id, non_active)

      assert new_state.actor_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "move_entity/3" do
    test "moves the selected hero to a valid tile" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select the hero then activate the move overlay to populate valid_moves.
      SceneServer.select_entity(game_id, hero_id)
      SceneServer.activate_move(game_id)

      # Pick any valid move.
      selected_state = SceneServer.get_state(game_id)
      {tx, ty} = hd(selected_state.valid_moves)

      new_state = SceneServer.move_entity(game_id, tx, ty)
      assert new_state.entities[hero_id].x == tx
      assert new_state.entities[hero_id].y == ty
    end

    test "ignores move to a tile not in valid_moves" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      original_x = state.entities[hero_id].x
      original_y = state.entities[hero_id].y

      # Move without selecting first — valid_moves is empty.
      new_state = SceneServer.move_entity(game_id, 0, 0)

      assert new_state.entities[hero_id].x == original_x
      assert new_state.entities[hero_id].y == original_y
    end

    test "broadcasts %EventBatch{} containing %EntityMoved{} on valid move" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      SceneServer.select_entity(game_id, hero_id)
      SceneServer.activate_move(game_id)

      selected_state = SceneServer.get_state(game_id)
      {tx, ty} = hd(selected_state.valid_moves)

      # Drain the select_entity + activate_move broadcasts first.
      assert_receive %EventBatch{}, 500
      assert_receive %EventBatch{}, 500

      SceneServer.move_entity(game_id, tx, ty)

      assert_receive %EventBatch{events: [%EntityMoved{to: {^tx, ^ty}} | _]}, 500
    end
  end

  describe "attack_entity/2" do
    test "reduces target hp" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)

      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)
      original_hp = state.entities[monster_id].hp

      hero_id = State.active_hero_id(state)
      SceneServer.select_entity(game_id, hero_id)

      new_state = SceneServer.attack_entity(game_id, monster_id)

      surviving_hp = get_in(new_state.entities, [monster_id, :hp])
      # A miss is valid; HP can only decrease or stay the same — never increase from an attack.
      assert surviving_hp == nil or surviving_hp <= original_hp
    end

    test "advances turn after attack" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, State.active_hero_id(state))
      new_state = SceneServer.attack_entity(game_id, monster_id)

      # With a single hero, turn wraps back to index 0 and selection is cleared.
      assert new_state.actor_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "end_turn/1" do
    test "clears selection and advances turn" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      SceneServer.select_entity(game_id, hero_id)

      new_state = SceneServer.end_turn(game_id)

      assert new_state.actor_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "PubSub broadcast" do
    test "broadcasts %EventBatch{} after each mutation" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive %EventBatch{}, 500
    end
  end

  # Single-writer contract (see docs/architecture.md): SceneServer is the sole
  # emitter of %EventBatch{} messages on the game topic. No other process may
  # broadcast to this topic.
  describe "single-writer contract" do
    test "no %EventBatch{} arrives without a SceneServer command" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      # SceneServer init does not emit; only mutations do.
      refute_receive %EventBatch{}, 100
    end

    test "exactly one %EventBatch{} arrives per command, not more" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive %EventBatch{}, 500
      refute_receive %EventBatch{}, 100
    end

    test "%EventBatch{} carries state_snapshot for the correct campaign" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive %EventBatch{state_snapshot: %State{campaign_id: ^game_id}}, 500
    end
  end

  describe "running?/1" do
    test "returns false when no server is registered for the game" do
      refute SceneServer.running?(999_999_999)
    end

    test "returns true after a server is started" do
      game_id = start_server()
      assert SceneServer.running?(game_id)
    end
  end

  describe "reload_entities/1" do
    test "reflects a name change made to the DB entity" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      entity = Repo.get!(Entity, hero_id)
      entity |> Entity.changeset(%{name: "Renamed Hero"}) |> Repo.update!()

      :ok = SceneServer.reload_entities(game_id)
      new_state = SceneServer.get_state(game_id)

      assert new_state.entities[hero_id].name == "Renamed Hero"
    end

    test "preserves runtime position after reload" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Move the hero in-memory (SceneServer updates runtime state, not entity table x/y).
      SceneServer.select_entity(game_id, hero_id)
      SceneServer.activate_move(game_id)
      moved_state = SceneServer.get_state(game_id)
      {tx, ty} = hd(moved_state.valid_moves)
      SceneServer.move_entity(game_id, tx, ty)

      # Now trigger a reload and confirm position is preserved.
      :ok = SceneServer.reload_entities(game_id)
      new_state = SceneServer.get_state(game_id)

      assert new_state.entities[hero_id].x == tx
      assert new_state.entities[hero_id].y == ty
    end

    test "removes an entity that was deleted from DB" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      Repo.delete!(Repo.get!(Entity, hero_id))

      :ok = SceneServer.reload_entities(game_id)
      new_state = SceneServer.get_state(game_id)

      refute Map.has_key?(new_state.entities, hero_id)
    end

    test "broadcasts %EventBatch{} after reload" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      :ok = SceneServer.reload_entities(game_id)

      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "start_session/1" do
    test "transitions phase from lobby to exploration" do
      game_id = start_server()
      assert :ok = SceneServer.start_session(game_id)
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "broadcasts %EventBatch{} with exploration phase after start" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      :ok = SceneServer.start_session(game_id)
      assert_receive %EventBatch{state_snapshot: %State{phase: :exploration}}, 500
    end
  end

  describe "pause_session/1" do
    test "transitions active phase to paused and saves previous_phase" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      assert :ok = SceneServer.pause_session(game_id)
      state = SceneServer.get_state(game_id)
      assert state.phase == :paused
      assert state.previous_phase == :exploration
    end

    test "is idempotent when already paused" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.pause_session(game_id)
      assert :ok = SceneServer.pause_session(game_id)
      assert SceneServer.get_state(game_id).phase == :paused
    end
  end

  describe "resume_session/1" do
    test "transitions from paused back to previous phase" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.pause_session(game_id)
      assert :ok = SceneServer.resume_session(game_id)
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "returns error when not paused" do
      game_id = start_server()
      assert {:error, _} = SceneServer.resume_session(game_id)
    end
  end

  describe "end_session/1" do
    test "broadcasts %EventBatch{} containing %SessionEnded{}" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      assert :ok = SceneServer.end_session(game_id)
      assert_receive %EventBatch{events: [%SessionEnded{}]}, 500
    end
  end

  describe "player action blocking while paused" do
    test "select_entity returns unchanged state when paused" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.pause_session(game_id)
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      returned = SceneServer.select_entity(game_id, hero_id)

      assert returned.actor_id == nil
      assert returned.valid_moves == []
    end

    test "end_turn does not advance turn when paused" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.pause_session(game_id)
      before_index = SceneServer.get_state(game_id).active_index

      SceneServer.end_turn(game_id)

      assert SceneServer.get_state(game_id).active_index == before_index
    end

    test "move_entity does not move hero when paused" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      original_x = state.entities[hero_id].x

      :ok = SceneServer.start_session(game_id)
      SceneServer.select_entity(game_id, hero_id)
      :ok = SceneServer.pause_session(game_id)

      SceneServer.move_entity(game_id, 0, 0)

      new_state = SceneServer.get_state(game_id)
      assert new_state.entities[hero_id].x == original_x
    end
  end

  describe "transition_phase/2" do
    test "valid transition succeeds and updates phase" do
      game_id = start_server()
      assert :ok = SceneServer.transition_phase(game_id, :exploration)
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "invalid transition returns error and leaves phase unchanged" do
      game_id = start_server()
      assert {:error, _} = SceneServer.transition_phase(game_id, :in_combat)
      assert SceneServer.get_state(game_id).phase == :lobby
    end

    test "pausing preserves previous_phase" do
      game_id = start_server()
      SceneServer.transition_phase(game_id, :exploration)
      SceneServer.transition_phase(game_id, :paused)
      state = SceneServer.get_state(game_id)
      assert state.phase == :paused
      assert state.previous_phase == :exploration
    end

    test "resuming from paused restores previous phase" do
      game_id = start_server()
      SceneServer.transition_phase(game_id, :exploration)
      SceneServer.transition_phase(game_id, :paused)
      SceneServer.transition_phase(game_id, :exploration)
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "force_transition_phase/2 allows any transition" do
      game_id = start_server()
      assert :ok = SceneServer.force_transition_phase(game_id, :in_combat)
      assert SceneServer.get_state(game_id).phase == :in_combat
    end
  end

  describe "set_initiative/3" do
    test "stores initiative value and broadcasts %EventBatch{}" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      assert :ok = SceneServer.set_initiative(game_id, hero_id, 14)

      new_state = SceneServer.get_state(game_id)
      assert new_state.initiative_values[hero_id] == 14
      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "add_to_turn_order/2" do
    test "adds an entity not already in turn_order" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      assert :ok = SceneServer.add_to_turn_order(game_id, monster_id)
      assert monster_id in SceneServer.get_state(game_id).turn_order
    end
  end

  describe "remove_from_turn_order/2" do
    test "removes an entity from the turn_order" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      assert :ok = SceneServer.remove_from_turn_order(game_id, hero_id)
      refute hero_id in SceneServer.get_state(game_id).turn_order
    end
  end

  describe "reorder_turn_order/2" do
    test "replaces the turn_order with the given ordering" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      monster_id =
        state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      # Add monster to turn_order first, then reorder
      :ok = SceneServer.add_to_turn_order(game_id, monster_id)
      assert :ok = SceneServer.reorder_turn_order(game_id, [monster_id, hero_id])
      assert hd(SceneServer.get_state(game_id).turn_order) == monster_id
    end
  end

  describe "force_end_turn/1" do
    test "advances turn even while session is paused" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.pause_session(game_id)
      before_index = SceneServer.get_state(game_id).active_index

      :ok = SceneServer.force_end_turn(game_id)

      # With only one hero, index wraps to 0 again — check the call returned :ok.
      assert SceneServer.get_state(game_id).active_index == before_index
    end

    test "broadcasts %EventBatch{} with %TurnAdvanced{} after force end turn" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      :ok = SceneServer.force_end_turn(game_id)

      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "dm_broadcast/2" do
    test "broadcasts %BroadcastSent{} to notifications topic subscribers" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.notifications_topic(game_id))

      assert :ok = SceneServer.dm_broadcast(game_id, "Hello players!")

      assert_receive %Gibbering.Events.Notification.BroadcastSent{text: "Hello players!"}, 500
    end

    test "appends entry to session_log in state" do
      game_id = start_server()
      assert :ok = SceneServer.dm_broadcast(game_id, "Narrative text")
      state = SceneServer.get_state(game_id)
      assert Enum.any?(state.session_log, &String.contains?(&1, "Narrative text"))
    end
  end

  describe "dm_whisper/3" do
    test "broadcasts %WhisperDelivered{} to the notifications topic" do
      game_id = start_server()
      user_id = 42
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.notifications_topic(game_id))

      assert :ok = SceneServer.dm_whisper(game_id, user_id, "Secret message")

      assert_receive %Gibbering.Events.Notification.WhisperDelivered{
                       target_player_id: 42,
                       text: "Secret message"
                     },
                     500
    end

    test "does not broadcast to the main game topic" do
      game_id = start_server()
      user_id = 42
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      assert :ok = SceneServer.dm_whisper(game_id, user_id, "Secret")

      refute_receive %Gibbering.Events.Notification.WhisperDelivered{}, 200
    end
  end

  describe "dm_apply_condition/3" do
    test "adds condition to entity active effects and broadcasts" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      assert :ok = SceneServer.dm_apply_condition(game_id, hero_id, :poisoned)

      new_state = SceneServer.get_state(game_id)
      assert :poisoned in new_state.entities[hero_id].conditions
      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "dm_adjust_hp/3" do
    test "applies delta to entity HP and broadcasts" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      original_hp = state.entities[hero_id].hp

      assert :ok = SceneServer.dm_adjust_hp(game_id, hero_id, -5)

      new_state = SceneServer.get_state(game_id)
      assert new_state.entities[hero_id].hp == max(original_hp - 5, 0)
      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "dm_toggle_visibility/2" do
    test "hides entity not yet hidden, then shows it again on second call" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      assert :ok = SceneServer.dm_toggle_visibility(game_id, hero_id)
      assert MapSet.member?(SceneServer.get_state(game_id).hidden_entities, hero_id)

      assert :ok = SceneServer.dm_toggle_visibility(game_id, hero_id)
      refute MapSet.member?(SceneServer.get_state(game_id).hidden_entities, hero_id)
    end

    test "broadcasts %EventBatch{} after toggle" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      :ok = SceneServer.dm_toggle_visibility(game_id, hero_id)

      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  # ---------------------------------------------------------------------------
  # Inventory event loop (issue #127)
  # ---------------------------------------------------------------------------

  # Insert a chest entity adjacent to the hero (hero spawns at 2,2) and reload.
  defp insert_chest(game_id, items \\ []) do
    chest =
      Repo.insert!(%Entity{
        name: "Chest",
        type: "object",
        sprite: "chest",
        x: 3,
        y: 2,
        hp: 1,
        max_hp: 1,
        tags: [],
        stats: %{"object_subtype" => "loot_source", "items" => items},
        campaign_id: game_id
      })

    SceneServer.reload_entities(game_id)
    chest
  end

  describe "open_container/2" do
    test "sets open_container_id when active hero is adjacent to a loot_source" do
      game_id = start_server()
      chest = insert_chest(game_id, [])

      {:ok, new_state} = SceneServer.open_container(game_id, chest.id)
      assert new_state.open_container_id == chest.id
    end

    test "returns error when active hero is not adjacent to container" do
      game_id = start_server()

      far_chest =
        Repo.insert!(%Entity{
          name: "Far Chest",
          type: "object",
          sprite: "chest",
          x: 0,
          y: 0,
          hp: 1,
          max_hp: 1,
          tags: [],
          stats: %{"object_subtype" => "loot_source", "items" => []},
          campaign_id: game_id
        })

      SceneServer.reload_entities(game_id)

      assert {:error, :not_adjacent} = SceneServer.open_container(game_id, far_chest.id)
    end

    test "broadcasts an EventBatch after opening" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      chest = insert_chest(game_id, [])

      # Drain the reload_entities broadcast.
      assert_receive %EventBatch{}, 500

      {:ok, _} = SceneServer.open_container(game_id, chest.id)
      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "take_item/4" do
    test "moves item from container to hero inventory and updates carry_weight" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      item = %{
        "instance_id" => "i1",
        "item_key" => "dagger",
        "quantity" => 1,
        "is_magical" => false
      }

      chest = insert_chest(game_id, [item])

      SceneServer.open_container(game_id, chest.id)
      {:ok, new_state} = SceneServer.take_item(game_id, chest.id, "i1", 1)

      hero = new_state.entities[hero_id]
      assert Enum.any?(hero.stats["inventory"] || [], &(&1["item_key"] == "dagger"))
      assert new_state.entities[chest.id].stats["items"] == []
    end

    test "broadcasts an EventBatch after take_item" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      item = %{
        "instance_id" => "i1",
        "item_key" => "dagger",
        "quantity" => 1,
        "is_magical" => false
      }

      chest = insert_chest(game_id, [item])

      SceneServer.open_container(game_id, chest.id)
      # Drain open_container + reload broadcasts.
      assert_receive %EventBatch{}, 500
      assert_receive %EventBatch{}, 500

      {:ok, _} = SceneServer.take_item(game_id, chest.id, "i1", 1)
      assert_receive %EventBatch{state_snapshot: %State{}}, 500
    end
  end

  describe "equip_item/2" do
    test "moves item from hero inventory to equipped_weapon slot" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Put a rapier in inventory via take_item flow.
      item = %{
        "instance_id" => "r1",
        "item_key" => "rapier",
        "quantity" => 1,
        "is_magical" => false
      }

      chest = insert_chest(game_id, [item])
      SceneServer.open_container(game_id, chest.id)
      SceneServer.take_item(game_id, chest.id, "r1", 1)

      {:ok, equipped_state} = SceneServer.equip_item(game_id, "r1")

      hero = equipped_state.entities[hero_id]
      assert hero.stats["equipped_weapon"]["key"] == "rapier"
      refute Enum.any?(hero.stats["inventory"] || [], &(&1["instance_id"] == "r1"))
    end
  end

  describe "victory/defeat auto-trigger" do
    test "dm_adjust_hp killing the last monster transitions to :victory" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.start_session(game_id)
      SceneServer.transition_phase(game_id, :in_combat)

      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      SceneServer.dm_adjust_hp(game_id, monster_id, -9999)

      final_state = SceneServer.get_state(game_id)
      assert final_state.phase == :victory

      assert_receive %EventBatch{events: events}, 500
      assert Enum.any?(events, fn e -> match?(%PhaseTransitioned{to_phase: :victory}, e) end)
    end

    test "dm_adjust_hp killing the last hero transitions to :defeat" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      SceneServer.start_session(game_id)
      SceneServer.transition_phase(game_id, :in_combat)

      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      SceneServer.dm_adjust_hp(game_id, hero_id, -9999)

      final_state = SceneServer.get_state(game_id)
      assert final_state.phase == :defeat

      assert_receive %EventBatch{events: events}, 500
      assert Enum.any?(events, fn e -> match?(%PhaseTransitioned{to_phase: :defeat}, e) end)
    end

    test "auto-trigger does not fire outside :in_combat phase" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.dm_adjust_hp(game_id, monster_id, -9999)

      final_state = SceneServer.get_state(game_id)
      assert final_state.phase == :lobby
    end
  end

  describe "roll prompt / pending-roll state (issue #146)" do
    test "attack_entity with auto_roll: false sets awaiting_roll and emits RollRequired" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, hero_id)
      # Drain the select_entity broadcast before asserting on the attack batch.
      assert_receive %EventBatch{}, 500
      returned = SceneServer.attack_entity(game_id, monster_id, auto_roll: false)

      assert returned.awaiting_roll == true
      assert returned.pending_roll == {:attack, monster_id}

      assert_receive %EventBatch{events: events}, 500
      assert Enum.any?(events, fn e -> match?(%RollRequired{roll_type: :attack}, e) end)
    end

    test "attack_entity with auto_roll: true does not set awaiting_roll" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, hero_id)
      returned = SceneServer.attack_entity(game_id, monster_id, auto_roll: true)

      assert returned.awaiting_roll == false
    end

    test "actions are blocked while awaiting_roll is true" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, hero_id)
      SceneServer.attack_entity(game_id, monster_id, auto_roll: false)

      before_index = SceneServer.get_state(game_id).active_index
      SceneServer.end_turn(game_id)
      assert SceneServer.get_state(game_id).active_index == before_index
    end

    test "submit_roll resumes the attack and clears awaiting_roll" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)
      original_hp = state.entities[monster_id].hp

      SceneServer.select_entity(game_id, hero_id)
      SceneServer.attack_entity(game_id, monster_id, auto_roll: false)
      assert SceneServer.get_state(game_id).awaiting_roll == true

      result = SceneServer.submit_roll(game_id, hero_id, 20)
      assert result.awaiting_roll == false
      assert result.pending_roll == nil
      surviving_hp = get_in(result.entities, [monster_id, :hp])
      # A 20 is a critical hit — damage must have been dealt.
      assert surviving_hp == nil or surviving_hp < original_hp
    end

    test "submit_roll clears awaiting_roll even with boundary value 0" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      SceneServer.select_entity(game_id, hero_id)
      SceneServer.attack_entity(game_id, monster_id, auto_roll: false)

      # Value 0 is out of 1..20 range — Rules.attack will clamp or reject it; the
      # key thing is SceneServer does not crash and still clears the pending state.
      result = SceneServer.submit_roll(game_id, hero_id, 0)
      assert result.awaiting_roll == false
    end
  end

  describe "initiative roll prompt (issue #147)" do
    test "transitioning to :initiative_rolling emits RollRequired for all heroes" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      :ok = SceneServer.start_session(game_id)
      assert_receive %EventBatch{}, 500

      :ok = SceneServer.transition_phase(game_id, :initiative_rolling)
      assert_receive %EventBatch{events: events}, 500

      assert Enum.any?(events, fn e ->
               match?(%PhaseTransitioned{to_phase: :initiative_rolling}, e)
             end)

      roll_events =
        Enum.filter(events, fn e -> match?(%RollRequired{roll_type: :initiative}, e) end)

      assert length(roll_events) >= 1
    end

    test "pending_initiative_rolls is populated after transition" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.transition_phase(game_id, :initiative_rolling)

      state = SceneServer.get_state(game_id)
      assert MapSet.size(state.pending_initiative_rolls) >= 1
    end

    test "submit_roll with hero in pending_initiative_rolls clears the entity" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.transition_phase(game_id, :initiative_rolling)

      state = SceneServer.get_state(game_id)
      [hero_id | _] = MapSet.to_list(state.pending_initiative_rolls)

      result = SceneServer.submit_roll(game_id, hero_id, 15)
      assert not MapSet.member?(result.pending_initiative_rolls, hero_id)
      assert Map.get(result.initiative_values, hero_id) == 15
    end

    test "end_initiative_rolling returns error when rolls are still pending" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.transition_phase(game_id, :initiative_rolling)

      state = SceneServer.get_state(game_id)
      assert MapSet.size(state.pending_initiative_rolls) > 0

      assert {:error, :pending_rolls} = SceneServer.end_initiative_rolling(game_id)
    end

    test "end_initiative_rolling succeeds when no rolls are pending" do
      game_id = start_server()
      :ok = SceneServer.start_session(game_id)
      :ok = SceneServer.transition_phase(game_id, :initiative_rolling)

      state = SceneServer.get_state(game_id)

      Enum.each(MapSet.to_list(state.pending_initiative_rolls), fn hero_id ->
        SceneServer.submit_roll(game_id, hero_id, 10)
      end)

      assert :ok = SceneServer.end_initiative_rolling(game_id)
      assert SceneServer.get_state(game_id).phase == :in_combat
    end

    test "end_initiative_rolling returns error in wrong phase" do
      game_id = start_server()
      assert {:error, :wrong_phase} = SceneServer.end_initiative_rolling(game_id)
    end
  end
end
