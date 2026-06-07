defmodule GibberingWeb.AdminAuditLogController do
  use GibberingWeb, :controller

  alias Gibbering.Admin

  def index(conn, params) do
    filters =
      []
      |> maybe_add_filter(params, "actor_id", :actor_id, &String.to_integer/1)
      |> maybe_add_filter(params, "action", :action, & &1)

    entries = Admin.list_audit_log(filters)
    render(conn, :index, entries: entries, params: params)
  end

  defp maybe_add_filter(acc, params, key, opt_key, cast) do
    case Map.get(params, key) do
      val when val not in [nil, ""] -> Keyword.put(acc, opt_key, cast.(val))
      _ -> acc
    end
  end
end
