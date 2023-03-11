defmodule DemoWeb.CartHTML do
  use DemoWeb, :html
  import Phoenix.HTML.Form

  alias Demo.ShoppingCart

  embed_templates "cart_html/*"

  def currency_to_str(%Decimal{} = val), do: "$#{Decimal.round(val, 2)}"

end
