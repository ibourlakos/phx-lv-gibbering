defmodule GibberingTalesAdmin.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias GibberingTalesAdmin.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import GibberingTalesAdmin.DataCase
    end
  end

  setup tags do
    GibberingTalesAdmin.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid1 = Ecto.Adapters.SQL.Sandbox.start_owner!(GibberingTalesAdmin.Repo, shared: not tags[:async])
    pid2 = Ecto.Adapters.SQL.Sandbox.start_owner!(GibberingTales.Repo, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid1)
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid2)
    end)
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_atom(key), key) |> to_string()
      end)
    end)
  end
end
