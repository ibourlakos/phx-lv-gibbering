defmodule Gibbering.Engine.GameServerTest do
  # Requires DB (loads Campaign in init). Must be async: false so the sandbox
  # runs in shared mode, allowing the GameServer process to use the connection.
  use Gibbering.DataCase, async: false

  import Gibbering.GameFixtures
  alias Gibbering.Engine.{GameServer, State}

  # Start a GameServer backed by a real (sandbox) DB campaign.
  # Returns the game_id. The server is supervised by the test process
  # and stopped automatically when the test ends.
  defp start_server do
    game_id = insert_campaign()
    start_supervised!({GameServer, game_id})
    game_id
  end

  describe "get_state/1" do
    test "returns an initial State with entities from the DB" do
      game_id = start_server()
      state = GameServer.get_state(game_id)

      assert %State{} = state
      assert state.campaign_id == game_id
      assert map_size(state.entities) == 2
    end
  end

  describe "select_entity/2" do
    test "sets selected_id and populates valid_moves for the active hero" do
      game_id = start_server()
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      new_state = GameServer.select_entity(game_id, hero_id)

      assert new_state.selected_id == hero_id
      assert new_state.valid_moves != []
    end

    test "does not change state when selecting a non-active entity" do
      game_id = start_server()
      state = GameServer.get_state(game_id)

      # Find any entity id that is NOT the active hero.
      non_active = state.entities |> Map.keys() |> Enum.find(&(&1 != State.active_hero_id(state)))

      new_state = GameServer.select_entity(game_id, non_active)

      assert new_state.selected_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "move_entity/3" do
    test "moves the selected hero to a valid tile" do
      game_id = start_server()
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select the hero first to generate valid_moves.
      GameServer.select_entity(game_id, hero_id)

      # Pick any valid move.
      selected_state = GameServer.get_state(game_id)
      {tx, ty} = hd(selected_state.valid_moves)

      new_state = GameServer.move_entity(game_id, tx, ty)
      assert new_state.entities[hero_id].x == tx
      assert new_state.entities[hero_id].y == ty
    end

    test "ignores move to a tile not in valid_moves" do
      game_id = start_server()
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      original_x = state.entities[hero_id].x
      original_y = state.entities[hero_id].y

      # Move without selecting first — valid_moves is empty.
      new_state = GameServer.move_entity(game_id, 0, 0)

      assert new_state.entities[hero_id].x == original_x
      assert new_state.entities[hero_id].y == original_y
    end
  end

  describe "attack_entity/2" do
    test "reduces target hp" do
      game_id = start_server()
      state = GameServer.get_state(game_id)

      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)
      original_hp = state.entities[monster_id].hp

      hero_id = State.active_hero_id(state)
      GameServer.select_entity(game_id, hero_id)

      new_state = GameServer.attack_entity(game_id, monster_id)

      surviving_hp = get_in(new_state.entities, [monster_id, :hp])
      assert surviving_hp == nil or surviving_hp < original_hp
    end

    test "advances turn after attack" do
      game_id = start_server()
      state = GameServer.get_state(game_id)
      monster_id = state.entities |> Enum.find(fn {_, e} -> e.type == "monster" end) |> elem(0)

      GameServer.select_entity(game_id, State.active_hero_id(state))
      new_state = GameServer.attack_entity(game_id, monster_id)

      # With a single hero, turn wraps back to index 0 and selection is cleared.
      assert new_state.selected_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "end_turn/1" do
    test "clears selection and advances turn" do
      game_id = start_server()
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)
      GameServer.select_entity(game_id, hero_id)

      new_state = GameServer.end_turn(game_id)

      assert new_state.selected_id == nil
      assert new_state.valid_moves == []
    end
  end

  describe "PubSub broadcast" do
    test "broadcasts :state_updated after each mutation" do
      game_id = start_server()
      Phoenix.PubSub.subscribe(Gibbering.PubSub, GameServer.topic(game_id))

      state = GameServer.get_state(game_id)
      GameServer.select_entity(game_id, State.active_hero_id(state))

      assert_receive {:state_updated, %State{}}, 500
    end
  end
end
