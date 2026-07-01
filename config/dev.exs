import Config

config :gibbering, Gibbering.Repo,
  username: "gibbering",
  password: "gibbering",
  hostname: "db",
  database: "gibbering_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :gibbering, GibberingWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "ceKQC67+nr7cxp3K9ZT0kmb5ofz3YiKqZtJeaxSXTed6t1TfH+VOO/5G2rCIjTTJ",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:gibbering, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:gibbering, ~w(--watch)]}
  ]

config :gibbering, GibberingWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"apps/gibbering/priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"apps/gibbering/priv/gettext/.*\.po$",
      ~r"apps/gibbering/lib/gibbering_web/(controllers|live|components)/.*\.(ex|heex)$"
    ]
  ]

config :gibbering, dev_routes: true

# --- :gibbering_tales_admin (stub — receives its own port in Phase 2d) ---
config :gibbering_tales_admin, GibberingTalesAdmin.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4001],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_admin_secret_key_base_changeme_not_for_prod_use_only"

config :logger, :default_formatter, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  debug_heex_annotations: true,
  debug_attributes: true,
  enable_expensive_runtime_checks: true
