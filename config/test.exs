import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :gibbering, Gibbering.Repo,
  username: "gibbering",
  password: "gibbering",
  hostname: "db",
  database: "gibbering_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gibbering, GibberingWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cw4I/Csxo1gQ8xYZGKvKIBaaRCWT1DR1pnLC7FGVPWMvJCrW07bNZAeJNt70w8UY",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Use minimal rounds in tests so password hashing doesn't saturate CPU under parallel load
config :pbkdf2_elixir, :rounds, 1
