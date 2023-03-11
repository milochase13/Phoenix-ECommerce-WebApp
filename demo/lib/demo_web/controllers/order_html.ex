defmodule DemoWeb.OrderHTML do
  use DemoWeb, :html
  import Phoenix.HTML.Form

  embed_templates "order_html/*"

  @doc """
  Renders a order form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def order_form(assigns)
end
