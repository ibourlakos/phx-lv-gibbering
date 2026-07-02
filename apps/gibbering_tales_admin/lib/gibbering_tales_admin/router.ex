defmodule GibberingTalesAdmin.Router do
  use GibberingTalesAdmin, :router

  import Phoenix.LiveDashboard.Router

  alias GibberingTalesAdmin.Plugs.RequireSupportUser

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GibberingTalesAdmin.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    plug RequireSupportUser
  end

  # Admin routes — public (login/logout)
  scope "/", GibberingTalesAdmin do
    pipe_through :browser

    get "/login", AdminSessionController, :new
    post "/login", AdminSessionController, :create
    delete "/logout", AdminSessionController, :delete
  end

  # Admin routes — require support user auth
  scope "/", GibberingTalesAdmin do
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
    get "/characters", AdminCharactersController, :index
    get "/characters/:id", AdminCharactersController, :show

    live_dashboard "/dashboard",
      metrics: GibberingTalesAdmin.Telemetry,
      additional_pages: [
        campaigns: {GibberingTalesAdmin.Admin.CampaignMonitoringPage, []}
      ]
  end
end
