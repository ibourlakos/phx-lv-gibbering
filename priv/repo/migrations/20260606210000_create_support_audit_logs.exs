defmodule Gibbering.Repo.Migrations.CreateSupportAuditLogs do
  use Ecto.Migration

  def change do
    create table(:support_audit_logs) do
      add :actor_id, references(:support_users, on_delete: :restrict), null: false
      add :action, :string, null: false
      add :target_type, :string, null: false
      add :target_id, :string, null: false
      add :metadata, :map

      timestamps(updated_at: false)
    end

    create index(:support_audit_logs, [:actor_id])
    create index(:support_audit_logs, [:action])
    create index(:support_audit_logs, [:inserted_at])
  end
end
