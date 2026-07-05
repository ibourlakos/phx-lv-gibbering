import Config

config :gibbering_tales, GibberingTales.Repo,
  username: "gibbering",
  password: "gibbering",
  hostname: "db",
  database: "gibbering_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :gibbering_tales_admin, GibberingTalesAdmin.Repo,
  username: "gibbering",
  password: "gibbering",
  hostname: "db",
  database: "gibbering_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :gibbering_tales_web, GibberingTalesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cw4I/Csxo1gQ8xYZGKvKIBaaRCWT1DR1pnLC7FGVPWMvJCrW07bNZAeJNt70w8UY",
  server: false

config :gibbering_tales_admin, GibberingTalesAdmin.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "test_admin_secret_key_base_not_for_prod_use_only_placeholder_abc123",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :phoenix,
  sort_verified_routes_query_params: true

config :pbkdf2_elixir, :rounds, 1

config :gibbering_engine, GibberingEngine.EventBus, adapter: GibberingTalesWeb.EventBus.PubSub

config :gibbering_engine, GibberingEngine.Monitoring.MetricsStore,
  adapter: GibberingEngine.Monitoring.Stores.NoOp
