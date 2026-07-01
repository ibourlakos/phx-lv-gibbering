defmodule GibberingTalesWeb.Router do
  use GibberingTalesWeb, :router

  import GibberingTalesWeb.UserAuth, only: [fetch_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GibberingTalesWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes (auth pages)
  scope "/", GibberingTalesWeb do
    pipe_through :browser

    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    post "/campaigns/:campaign_id/join", PageController, :join
  end

  # Authenticated routes
  scope "/", GibberingTalesWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :authenticated,
      on_mount: [{GibberingTalesWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive
      live "/characters", CharactersLive
      live "/lobby/:id", LobbyLive
      live "/campaigns/:id/prep", CampaignPrepLive
    end

    live_session :game,
      root_layout: {GibberingTalesWeb.Layouts, :game_root},
      on_mount: [{GibberingTalesWeb.UserAuth, :ensure_authenticated}] do
      live "/game/:id", GameLive
    end

    live_session :invite,
      on_mount: [{GibberingTalesWeb.UserAuth, :ensure_authenticated_with_return}] do
      live "/invites/:token", InviteLive
    end
  end
end
