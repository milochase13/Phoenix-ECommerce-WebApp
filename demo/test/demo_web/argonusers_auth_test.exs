defmodule DemoWeb.ArgonusersAuthTest do
  use DemoWeb.ConnCase, async: true

  alias Phoenix.LiveView
  alias Demo.Accounts
  alias DemoWeb.ArgonusersAuth
  import Demo.AccountsFixtures

  @remember_me_cookie "_demo_web_argonusers_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, DemoWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{argonusers: argonusers_fixture(), conn: conn}
  end

  describe "log_in_argonusers/3" do
    test "stores the argonusers token in the session", %{conn: conn, argonusers: argonusers} do
      conn = ArgonusersAuth.log_in_argonusers(conn, argonusers)
      assert token = get_session(conn, :argonusers_token)
      assert get_session(conn, :live_socket_id) == "argonusers_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == ~p"/"
      assert Accounts.get_argonusers_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, argonusers: argonusers} do
      conn = conn |> put_session(:to_be_removed, "value") |> ArgonusersAuth.log_in_argonusers(argonusers)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, argonusers: argonusers} do
      conn = conn |> put_session(:argonusers_return_to, "/hello") |> ArgonusersAuth.log_in_argonusers(argonusers)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, argonusers: argonusers} do
      conn = conn |> fetch_cookies() |> ArgonusersAuth.log_in_argonusers(argonusers, %{"remember_me" => "true"})
      assert get_session(conn, :argonusers_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :argonusers_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_argonusers/1" do
    test "erases session and cookies", %{conn: conn, argonusers: argonusers} do
      argonusers_token = Accounts.generate_argonusers_session_token(argonusers)

      conn =
        conn
        |> put_session(:argonusers_token, argonusers_token)
        |> put_req_cookie(@remember_me_cookie, argonusers_token)
        |> fetch_cookies()
        |> ArgonusersAuth.log_out_argonusers()

      refute get_session(conn, :argonusers_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
      refute Accounts.get_argonusers_by_session_token(argonusers_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "argonusers_sessions:abcdef-token"
      DemoWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> ArgonusersAuth.log_out_argonusers()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if argonusers is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> ArgonusersAuth.log_out_argonusers()
      refute get_session(conn, :argonusers_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "fetch_current_argonusers/2" do
    test "authenticates argonusers from session", %{conn: conn, argonusers: argonusers} do
      argonusers_token = Accounts.generate_argonusers_session_token(argonusers)
      conn = conn |> put_session(:argonusers_token, argonusers_token) |> ArgonusersAuth.fetch_current_argonusers([])
      assert conn.assigns.current_argonusers.id == argonusers.id
    end

    test "authenticates argonusers from cookies", %{conn: conn, argonusers: argonusers} do
      logged_in_conn =
        conn |> fetch_cookies() |> ArgonusersAuth.log_in_argonusers(argonusers, %{"remember_me" => "true"})

      argonusers_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> ArgonusersAuth.fetch_current_argonusers([])

      assert conn.assigns.current_argonusers.id == argonusers.id
      assert get_session(conn, :argonusers_token) == argonusers_token

      assert get_session(conn, :live_socket_id) ==
               "argonusers_sessions:#{Base.url_encode64(argonusers_token)}"
    end

    test "does not authenticate if data is missing", %{conn: conn, argonusers: argonusers} do
      _ = Accounts.generate_argonusers_session_token(argonusers)
      conn = ArgonusersAuth.fetch_current_argonusers(conn, [])
      refute get_session(conn, :argonusers_token)
      refute conn.assigns.current_argonusers
    end
  end

  describe "on_mount: mount_current_argonusers" do
    test "assigns current_argonusers based on a valid argonusers_token ", %{conn: conn, argonusers: argonusers} do
      argonusers_token = Accounts.generate_argonusers_session_token(argonusers)
      session = conn |> put_session(:argonusers_token, argonusers_token) |> get_session()

      {:cont, updated_socket} =
        ArgonusersAuth.on_mount(:mount_current_argonusers, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_argonusers.id == argonusers.id
    end

    test "assigns nil to current_argonusers assign if there isn't a valid argonusers_token ", %{conn: conn} do
      argonusers_token = "invalid_token"
      session = conn |> put_session(:argonusers_token, argonusers_token) |> get_session()

      {:cont, updated_socket} =
        ArgonusersAuth.on_mount(:mount_current_argonusers, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_argonusers == nil
    end

    test "assigns nil to current_argonusers assign if there isn't a argonusers_token", %{conn: conn} do
      session = conn |> get_session()

      {:cont, updated_socket} =
        ArgonusersAuth.on_mount(:mount_current_argonusers, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_argonusers == nil
    end
  end

  describe "on_mount: ensure_authenticated" do
    test "authenticates current_argonusers based on a valid argonusers_token ", %{conn: conn, argonusers: argonusers} do
      argonusers_token = Accounts.generate_argonusers_session_token(argonusers)
      session = conn |> put_session(:argonusers_token, argonusers_token) |> get_session()

      {:cont, updated_socket} =
        ArgonusersAuth.on_mount(:ensure_authenticated, %{}, session, %LiveView.Socket{})

      assert updated_socket.assigns.current_argonusers.id == argonusers.id
    end

    test "redirects to login page if there isn't a valid argonusers_token ", %{conn: conn} do
      argonusers_token = "invalid_token"
      session = conn |> put_session(:argonusers_token, argonusers_token) |> get_session()

      socket = %LiveView.Socket{
        endpoint: DemoWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ArgonusersAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_argonusers == nil
    end

    test "redirects to login page if there isn't a argonusers_token ", %{conn: conn} do
      session = conn |> get_session()

      socket = %LiveView.Socket{
        endpoint: DemoWeb.Endpoint,
        assigns: %{__changed__: %{}, flash: %{}}
      }

      {:halt, updated_socket} = ArgonusersAuth.on_mount(:ensure_authenticated, %{}, session, socket)
      assert updated_socket.assigns.current_argonusers == nil
    end
  end

  describe "on_mount: :redirect_if_argonusers_is_authenticated" do
    test "redirects if there is an authenticated  argonusers ", %{conn: conn, argonusers: argonusers} do
      argonusers_token = Accounts.generate_argonusers_session_token(argonusers)
      session = conn |> put_session(:argonusers_token, argonusers_token) |> get_session()

      assert {:halt, _updated_socket} =
               ArgonusersAuth.on_mount(
                 :redirect_if_argonusers_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end

    test "Don't redirect is there is no authenticated argonusers", %{conn: conn} do
      session = conn |> get_session()

      assert {:cont, _updated_socket} =
               ArgonusersAuth.on_mount(
                 :redirect_if_argonusers_is_authenticated,
                 %{},
                 session,
                 %LiveView.Socket{}
               )
    end
  end

  describe "redirect_if_argonusers_is_authenticated/2" do
    test "redirects if argonusers is authenticated", %{conn: conn, argonusers: argonusers} do
      conn = conn |> assign(:current_argonusers, argonusers) |> ArgonusersAuth.redirect_if_argonusers_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == ~p"/"
    end

    test "does not redirect if argonusers is not authenticated", %{conn: conn} do
      conn = ArgonusersAuth.redirect_if_argonusers_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_argonusers/2" do
    test "redirects if argonusers is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> ArgonusersAuth.require_authenticated_argonusers([])
      assert conn.halted

      assert redirected_to(conn) == ~p"/argonusers/log_in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> ArgonusersAuth.require_authenticated_argonusers([])

      assert halted_conn.halted
      assert get_session(halted_conn, :argonusers_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> ArgonusersAuth.require_authenticated_argonusers([])

      assert halted_conn.halted
      assert get_session(halted_conn, :argonusers_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> ArgonusersAuth.require_authenticated_argonusers([])

      assert halted_conn.halted
      refute get_session(halted_conn, :argonusers_return_to)
    end

    test "does not redirect if argonusers is authenticated", %{conn: conn, argonusers: argonusers} do
      conn = conn |> assign(:current_argonusers, argonusers) |> ArgonusersAuth.require_authenticated_argonusers([])
      refute conn.halted
      refute conn.status
    end
  end
end
