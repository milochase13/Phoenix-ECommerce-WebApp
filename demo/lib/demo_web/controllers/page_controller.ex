defmodule DemoWeb.PageController do
  use DemoWeb, :controller

  def blank(conn, _params) do
    # conn
    # |> put_resp_content_type("text/plain")
    # |> send_resp(201, "")
    redirect(conn, to: ~p"/redirect_test")
  end

  def redirect_test(conn, _params) do
    render(conn, :home, layout: false)
  end

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    render(conn, :home, layout: false)
    # conn
    # #|> put_root_layout(false)
    # |> render(:home)
  end

end
