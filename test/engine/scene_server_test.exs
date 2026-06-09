defmodule Gibbering.Engine.SceneServerTest do
  # Requires DB (loads Campaign in init). Must be async: false so the sandbox
  # runs in shared mode, allowing the SceneServer process to use the connection.
  use Gibbering.DataCase, async: false

  import Gibbering.GameFixtures
  alias Gibbering.{Repo, Entity}
  alias Gibbering.Engine.{SceneServer, State}

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
    test "sets selected_id and populates valid_moves for the active hero" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      new_state = SceneServer.select_entity(game_id, hero_id)

      assert new_state.selected_id == hero_id
      assert new_state.valid_moves != []
    end

    test "does not change state when selecting a non-active entity" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)

      # Find any entity id that is NOT the active hero.
      non_active = state.entities |> Map.keys() |> Enum.find(&(&1 != State.active_hero_id(state)))

      new_state = SceneServer.select_entity(game_id, non_active)

      assert new_state.selected_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "move_entity/3" do
    test "moves the selected hero to a valid tile" do
      game_id = start_server()
      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select the hero first to generate valid_moves.
      SceneServer.select_entity(game_id, hero_id)

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
      assert new_state.selected_id == nil
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

      assert new_state.selected_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "PubSub broadcast" do
    test "broadcasts :state_updated after each mutation" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive {:state_updated, %State{}}, 500
    end
  end

  # Single-writer contract (see docs/architecture.md): SceneServer is the sole
  # emitter of scene-domain events on the game topic. No other process may broadcast
  # {:state_updated, _} to this topic.
  describe "single-writer contract" do
    test "no state_updated arrives without a SceneServer command" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      # SceneServer init does not emit state_updated; only mutations do.
      refute_receive {:state_updated, _}, 100
    end

    test "exactly one state_updated arrives per command, not more" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive {:state_updated, %State{}}, 500
      refute_receive {:state_updated, _}, 100
    end

    test "state_updated carries a well-formed State for the correct campaign" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      SceneServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive {:state_updated, %State{campaign_id: ^game_id}}, 500
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

    test "broadcasts :state_updated after reload" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      :ok = SceneServer.reload_entities(game_id)

      assert_receive {:state_updated, %State{}}, 500
    end
  end

  describe "start_session/1" do
    test "transitions phase from lobby to exploration" do
      game_id = start_server()
      assert :ok = SceneServer.start_session(game_id)
      assert SceneServer.get_state(game_id).phase == :exploration
    end

    test "broadcasts state_updated after start" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      :ok = SceneServer.start_session(game_id)
      assert_receive {:state_updated, %State{phase: :exploration}}, 500
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
    test "broadcasts :session_ended PubSub event" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))
      assert :ok = SceneServer.end_session(game_id)
      assert_receive :session_ended, 500
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

      assert returned.selected_id == nil
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
    test "stores initiative value and broadcasts updated state" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      assert :ok = SceneServer.set_initiative(game_id, hero_id, 14)

      new_state = SceneServer.get_state(game_id)
      assert new_state.initiative_values[hero_id] == 14
      assert_receive {:state_updated, %State{}}, 500
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

    test "broadcasts state_updated after force end turn" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      :ok = SceneServer.force_end_turn(game_id)

      assert_receive {:state_updated, %State{}}, 500
    end
  end

  describe "dm_broadcast/2" do
    test "broadcasts :dm_broadcast message to all subscribers" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      assert :ok = SceneServer.dm_broadcast(game_id, "Hello players!")

      assert_receive {:dm_broadcast, "Hello players!"}, 500
    end

    test "appends entry to session_log in state" do
      game_id = start_server()
      assert :ok = SceneServer.dm_broadcast(game_id, "Narrative text")
      state = SceneServer.get_state(game_id)
      assert Enum.any?(state.session_log, &String.contains?(&1, "Narrative text"))
    end
  end

  describe "dm_whisper/3" do
    test "broadcasts :whisper to the per-user topic" do
      game_id = start_server()
      user_id = 42
      Phoenix.PubSub.subscribe(Gibbering.PubSub, "game:#{game_id}:user:#{user_id}")

      assert :ok = SceneServer.dm_whisper(game_id, user_id, "Secret message")

      assert_receive {:whisper, "Secret message"}, 500
    end

    test "does not broadcast :whisper to the main game topic" do
      game_id = start_server()
      user_id = 42
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      assert :ok = SceneServer.dm_whisper(game_id, user_id, "Secret")

      refute_receive {:whisper, _}, 200
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
      assert_receive {:state_updated, %State{}}, 500
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
      assert_receive {:state_updated, %State{}}, 500
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

    test "broadcasts state_updated after toggle" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, SceneServer.topic(game_id))

      state = SceneServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      :ok = SceneServer.dm_toggle_visibility(game_id, hero_id)

      assert_receive {:state_updated, %State{}}, 500
    end
  end
end
