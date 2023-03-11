defmodule DemoWeb.Layouts do
  use DemoWeb, :html

  def title(assigns) do
    ~H"""
    Welcome to HelloWeb! <%= 1+1 %>
    """
  end

  embed_templates "layouts/*"
end
