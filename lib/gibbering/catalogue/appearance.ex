defmodule Gibbering.Catalogue.Appearance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appearances" do
    belongs_to :style, Gibbering.Catalogue.Style

    field :content_type, :string
    field :content_key, :string
    field :data, :map, default: %{}

    timestamps()
  end

  def changeset(appearance, attrs) do
    appearance
    |> cast(attrs, [:style_id, :content_type, :content_key, :data])
    |> validate_required([:style_id, :content_type, :content_key])
    |> unique_constraint([:style_id, :content_type, :content_key])
  end
end
