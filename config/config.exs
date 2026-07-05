import Config

# Umbrella-root shared configuration.

# --- :gibbering (stub — empty after Phase 2d) ---

config :gibbering,
  ecto_repos: [],
  generators: [timestamp_type: :utc_datetime]

config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# --- :gibbering_engine ---

config :gibbering_engine, GibberingEngine.EventBus, adapter: GibberingEngine.EventBus.Local

config :gibbering_engine, GibberingEngine.Monitoring.MetricsStore,
  adapter: GibberingEngine.Monitoring.Stores.NoOp

# --- :gibbering_tales ---

config :gibbering_tales,
  ecto_repos: [GibberingTales.Repo],
  generators: [timestamp_type: :utc_datetime]

# --- :gibbering_tales_web ---

config :gibbering_tales_web, GibberingTalesWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: GibberingTalesWeb.ErrorHTML, json: GibberingTalesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GibberingTales.PubSub,
  live_view: [signing_salt: "JpFlCZDK"]

config :esbuild,
  version: "0.25.4",
  gibbering_tales_web: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../apps/gibbering_tales_web/assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

config :tailwind,
  version: "4.1.12",
  gibbering_tales_web: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("../apps/gibbering_tales_web", __DIR__)
  ]

# --- :gibbering_tales_admin ---

config :gibbering_tales_admin,
  ecto_repos: [GibberingTalesAdmin.Repo],
  generators: [timestamp_type: :utc_datetime]

config :gibbering_tales_admin, GibberingTalesAdmin.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: GibberingTalesAdmin.ErrorHTML, json: GibberingTalesAdmin.ErrorJSON],
    layout: false
  ],
  pubsub_server: GibberingTalesAdmin.PubSub,
  live_view: [signing_salt: "AdminSalt1"]

import_config "#{config_env()}.exs"
