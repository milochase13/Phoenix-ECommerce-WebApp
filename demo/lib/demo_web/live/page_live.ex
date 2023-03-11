defmodule DemoWeb.PageLive do
  use DemoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, number: 5)}
  end

  def render(assigns) do
    ~H"""
      <%= @number %>
      <.button phx-clock="add">Add</.button>
    """
  end

  def handle_event("add", _params, socket) do
    {:noreply, assign(socket, number: socket.assigns.number + 1)}
  end

end
