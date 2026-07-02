defmodule GibberingTales.CatalogueAppearancesTest do
  use GibberingTales.DataCase, async: true

  alias GibberingTales.Catalogue
  alias GibberingTales.Catalogue.{Style, Appearance}
  alias GibberingTales.Repo

  setup do
    {:ok, style} =
      Repo.insert(%Style{slug: "test_style", name: "Test Style"})

    Repo.insert!(%Appearance{
      style_id: style.id,
      content_type: "tile",
      content_key: "grass",
      data: %{"fill" => "#aabbcc", "stroke" => "#112233"}
    })

    Repo.insert!(%Appearance{
      style_id: style.id,
      content_type: "entity",
      content_key: "warrior",
      data: %{"body_color" => "#336699"}
    })

    {:ok, style: style}
  end

  describe "appearances_for_style/1" do
    test "returns a map keyed by {content_type, content_key, state}", %{style: style} do
      result = Catalogue.appearances_for_style(style.slug)
      assert result[{"tile", "grass", "default"}]["fill"] == "#aabbcc"
      assert result[{"tile", "grass", "default"}]["stroke"] == "#112233"
      assert result[{"entity", "warrior", "default"}]["body_color"] == "#336699"
    end

    test "returns empty map for unknown style slug" do
      assert Catalogue.appearances_for_style("nonexistent") == %{}
    end

    test "does not include records from other styles" do
      {:ok, other} = Repo.insert(%Style{slug: "other_style", name: "Other"})

      Repo.insert!(%Appearance{
        style_id: other.id,
        content_type: "tile",
        content_key: "grass",
        data: %{"fill" => "#ffffff"}
      })

      result = Catalogue.appearances_for_style("test_style")
      assert result[{"tile", "grass", "default"}]["fill"] == "#aabbcc"
    end

    test "returns all records for the requested style" do
      result = Catalogue.appearances_for_style("test_style")
      assert map_size(result) == 2
    end
  end

  describe "default_style_slug/0" do
    test "returns dst" do
      assert Catalogue.default_style_slug() == "dst"
    end
  end
end
