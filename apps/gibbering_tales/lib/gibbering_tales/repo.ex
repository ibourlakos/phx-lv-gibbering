defmodule GibberingTales.Repo do
  use Ecto.Repo,
    otp_app: :gibbering_tales,
    adapter: Ecto.Adapters.Postgres
end
