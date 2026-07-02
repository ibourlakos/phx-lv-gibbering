defmodule GibberingTales.Catalogue.Style do
  use Ecto.Schema
  import Ecto.Changeset

  schema "styles" do
    field :slug, :string
    field :name, :string
    field :description, :string

    has_many :appearances, GibberingTales.Catalogue.Appearance

    timestamps()
  end

  def changeset(style, attrs) do
    style
    |> cast(attrs, [:slug, :name, :description])
    |> validate_required([:slug, :name])
    |> unique_constraint(:slug)
  end
end
