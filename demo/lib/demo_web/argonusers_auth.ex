defmodule DemoWeb.ArgonusersAuth do
  use DemoWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias Demo.Accounts

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in ArgonusersToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_demo_web_argonusers_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the argonusers in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_argonusers(conn, argonusers, params \\ %{}) do
    token = Accounts.generate_argonusers_session_token(argonusers)
    argonusers_return_to = get_session(conn, :argonusers_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: argonusers_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the argonusers out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_argonusers(conn) do
    argonusers_token = get_session(conn, :argonusers_token)
    argonusers_token && Accounts.delete_argonusers_session_token(argonusers_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      DemoWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/")
  end

  @doc """
  Authenticates the argonusers by looking into the session
  and remember me token.
  """
  def fetch_current_argonusers(conn, _opts) do
    {argonusers_token, conn} = ensure_argonusers_token(conn)
    argonusers = argonusers_token && Accounts.get_argonusers_by_session_token(argonusers_token)
    assign(conn, :current_argonusers, argonusers)
  end

  defp ensure_argonusers_token(conn) do
    if token = get_session(conn, :argonusers_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_argonusers in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_argonusers` - Assigns current_argonusers
      to socket assigns based on argonusers_token, or nil if
      there's no argonusers_token or no matching argonusers.

    * `:ensure_authenticated` - Authenticates the argonusers from the session,
      and assigns the current_argonusers to socket assigns based
      on argonusers_token.
      Redirects to login page if there's no logged argonusers.

    * `:redirect_if_argonusers_is_authenticated` - Authenticates the argonusers from the session.
      Redirects to signed_in_path if there's a logged argonusers.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_argonusers:

      defmodule DemoWeb.PageLive do
        use DemoWeb, :live_view

        on_mount {DemoWeb.ArgonusersAuth, :mount_current_argonusers}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{DemoWeb.ArgonusersAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  def on_mount(:mount_current_argonusers, _params, session, socket) do
    {:cont, mount_current_argonusers(session, socket)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_argonusers(session, socket)

    if socket.assigns.current_argonusers do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "You must log in to access this page.")
        |> Phoenix.LiveView.redirect(to: ~p"/argonusers/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_argonusers_is_authenticated, _params, session, socket) do
    socket = mount_current_argonusers(session, socket)

    if socket.assigns.current_argonusers do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_argonusers(session, socket) do
    Phoenix.Component.assign_new(socket, :current_argonusers, fn ->
      if argonusers_token = session["argonusers_token"] do
        Accounts.get_argonusers_by_session_token(argonusers_token)
      end
    end)
  end

  @doc """
  Used for routes that require the argonusers to not be authenticated.
  """
  def redirect_if_argonusers_is_authenticated(conn, _opts) do
    if conn.assigns[:current_argonusers] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the argonusers to be authenticated.

  If you want to enforce the argonusers email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_argonusers(conn, _opts) do
    if conn.assigns[:current_argonusers] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/argonusers/log_in")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:argonusers_token, token)
    |> put_session(:live_socket_id, "argonusers_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :argonusers_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
