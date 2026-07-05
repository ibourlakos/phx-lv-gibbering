defmodule GibberingTalesWeb.AccountsFixtures do
  @moduledoc "Factories for User records in tests."

  alias GibberingTales.Accounts

  def unique_username, do: "user#{System.unique_integer([:positive])}"

  def valid_user_attrs(attrs \\ %{}) do
    Map.merge(
      %{"username" => unique_username(), "password" => "valid_password"},
      attrs
    )
  end

  def register_user(attrs \\ %{}) do
    {:ok, user} = Accounts.register_user(valid_user_attrs(attrs))
    user
  end
end
