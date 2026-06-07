defmodule Gibbering.Admin.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "support_audit_logs" do
    belongs_to :actor, Gibbering.Admin.SupportUser

    field :action, :string
    field :target_type, :string
    field :target_id, :string
    field :metadata, :map

    timestamps(updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:actor_id, :action, :target_type, :target_id, :metadata])
    |> validate_required([:actor_id, :action, :target_type, :target_id])
    |> foreign_key_constraint(:actor_id)
  end
end
