defmodule Gibbering.Catalogue.Appearance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appearances" do
    belongs_to :style, Gibbering.Catalogue.Style

    field :content_type, :string
    field :content_key, :string
    field :state, :string, default: "default"
    field :data, :map, default: %{}

    timestamps()
  end

  def changeset(appearance, attrs) do
    appearance
    |> cast(attrs, [:style_id, :content_type, :content_key, :state, :data])
    |> validate_required([:style_id, :content_type, :content_key, :state])
    |> unique_constraint([:style_id, :content_type, :content_key, :state])
  end
end
