defmodule GibberingWeb.Router do
  use GibberingWeb, :router

  import GibberingWeb.UserAuth, only: [fetch_current_user: 2]

  alias GibberingWeb.Plugs.RequireSupportUser

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GibberingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug RequireSupportUser
  end

  # Public routes (auth pages)
  scope "/", GibberingWeb do
    pipe_through :browser

    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
    post "/campaigns/:campaign_id/join", PageController, :join
  end

  # Admin routes — public (login/logout)
  scope "/admin", GibberingWeb do
    pipe_through :browser

    get "/login", AdminSessionController, :new
    post "/login", AdminSessionController, :create
    delete "/logout", AdminSessionController, :delete
  end

  # Admin routes — require support user auth
  scope "/admin", GibberingWeb do
    pipe_through [:browser, :admin]

    get "/", AdminController, :index
    get "/audit_log", AdminAuditLogController, :index
    get "/users", AdminUsersController, :index
    get "/users/:id", AdminUsersController, :show
    post "/users/:id/suspend", AdminUsersController, :suspend
    post "/users/:id/unsuspend", AdminUsersController, :unsuspend
    get "/campaigns", AdminCampaignsController, :index
    get "/campaigns/:id", AdminCampaignsController, :show
    post "/campaigns/:id/force_close", AdminCampaignsController, :force_close
    post "/campaigns/:id/remove_member", AdminCampaignsController, :remove_member
  end

  # Authenticated routes
  scope "/", GibberingWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :authenticated,
      on_mount: [{GibberingWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive
      live "/characters", CharactersLive
      live "/game/:id", GameLive
      live "/lobby/:id", LobbyLive
      live "/campaigns/:id/prep", CampaignPrepLive
    end

    live_session :invite,
      on_mount: [{GibberingWeb.UserAuth, :ensure_authenticated_with_return}] do
      live "/invites/:token", InviteLive
    end
  end
end
