defmodule GibberingTalesAdmin.Repo do
  use Ecto.Repo,
    otp_app: :gibbering_tales_admin,
    adapter: Ecto.Adapters.Postgres
end
