defmodule GibberingTalesAdmin.Endpoint do
  use Phoenix.Endpoint, otp_app: :gibbering_tales_admin

  @session_options [
    store: :cookie,
    key: "_gibbering_tales_admin_key",
    signing_salt: "AdminSalt9",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :gibbering_tales_admin,
    gzip: not code_reloading?,
    only: GibberingTalesAdmin.static_paths(),
    raise_on_missing_only: false

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :gibbering_tales_admin
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug GibberingTalesAdmin.Router
end
