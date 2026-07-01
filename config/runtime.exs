import Config

if System.get_env("PHX_SERVER") do
  config :gibbering_tales_web, GibberingTalesWeb.Endpoint, server: true
end

config :gibbering_tales_web, GibberingTalesWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :gibbering_tales, GibberingTales.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  config :gibbering_tales_admin, GibberingTalesAdmin.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  admin_secret_key_base =
    System.get_env("ADMIN_SECRET_KEY_BASE") ||
      raise """
      environment variable ADMIN_SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  admin_host = System.get_env("ADMIN_PHX_HOST") || host

  config :gibbering_tales_web, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :gibbering_tales_web, GibberingTalesWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
    secret_key_base: secret_key_base

  config :gibbering_tales_admin, GibberingTalesAdmin.Endpoint,
    url: [host: admin_host, port: 4001],
    http: [ip: {0, 0, 0, 0}],
    secret_key_base: admin_secret_key_base
end
