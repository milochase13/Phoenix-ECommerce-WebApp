defmodule DemoWeb.ProductHTML do
  use DemoWeb, :html
  import Phoenix.HTML.Form

  embed_templates "product_html/*"

  @doc """
  Renders a product form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def product_form(assigns)

  def category_select(f, changeset) do
    existing_ids =
      changeset
      |> Ecto.Changeset.get_change(:categories, [])
      |> Enum.map(& &1.data.id)

    category_opts =
      for cat <- Demo.Catalog.list_categories(),
          do: [key: cat.title, value: cat.id, selected: cat.id in existing_ids]

    multiple_select(f, :category_ids, category_opts)
  end
end
