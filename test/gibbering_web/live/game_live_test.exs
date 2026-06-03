defmodule GibberingWeb.GameLiveTest do
  # Full-stack: mounts a real LiveView, drives events, asserts rendered output.
  # Requires the DB (loads Campaign). async: false because GameServer is shared state.
  use GibberingWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Gibbering.GameFixtures

  alias Gibbering.Engine.{GameServer, State}

  defp mount_game(conn) do
    game_id = insert_campaign()
    # Pre-start the server so the LiveView mounts against an already-running game.
    start_supervised!({GameServer, game_id})
    {:ok, view, _html} = live(conn, "/game/#{game_id}")
    {view, game_id}
  end

  describe "mount" do
    test "renders the SVG game board", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      assert html =~ "<svg"
    end

    test "renders isometric polygon tiles for each map cell", %{conn: conn} do
      {view, _game_id} = mount_game(conn)
      html = render(view)
      # 5x5 grid = 25 tile polygons; move overlays add more when active.
      polygon_count = html |> String.split("<polygon") |> length() |> Kernel.-(1)
      assert polygon_count >= 25
    end
  end

  describe "select_entity event" do
    test "clicking the active hero highlights valid move tiles", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()

      html = render(view)
      # Move overlay tiles carry phx-click="move" — their presence means moves were rendered.
      assert html =~ "phx-click=\"move\""
    end
  end

  describe "end_turn event" do
    test "end_turn button clears move overlays", %{conn: conn} do
      {view, game_id} = mount_game(conn)
      state = GameServer.get_state(game_id)
      hero_id = State.active_hero_id(state)

      # Select hero to show moves, then end turn.
      view |> element("[phx-click='select_entity'][phx-value-id='#{hero_id}']") |> render_click()
      view |> element("[phx-click='end_turn']") |> render_click()

      html = render(view)
      refute html =~ "phx-click=\"move\""
    end
  end
end
