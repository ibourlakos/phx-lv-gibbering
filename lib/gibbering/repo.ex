defmodule Gibbering.Repo do
  use Ecto.Repo,
    otp_app: :gibbering,
    adapter: Ecto.Adapters.Postgres
end
