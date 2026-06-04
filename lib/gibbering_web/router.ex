defmodule GibberingWeb.Router do
  use GibberingWeb, :router

  import GibberingWeb.UserAuth, only: [fetch_current_user: 2]

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

  # Public routes (auth pages)
  scope "/", GibberingWeb do
    pipe_through :browser

    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  # Authenticated routes
  scope "/", GibberingWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :authenticated,
      on_mount: [{GibberingWeb.UserAuth, :ensure_authenticated}] do
      live "/game/:id", GameLive
      live "/lobby/:id", LobbyLive
    end
  end
end
