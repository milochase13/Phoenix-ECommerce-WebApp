defmodule DemoWeb.ArgonusersSessionControllerTest do
  use DemoWeb.ConnCase, async: true

  import Demo.AccountsFixtures

  setup do
    %{argonusers: argonusers_fixture()}
  end

  describe "GET /argonusers/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, ~p"/argonusers/log_in")
      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ ~p"/users/register"
      assert response =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn, argonusers: argonusers} do
      conn = conn |> log_in_argonusers(argonusers) |> get(~p"/argonusers/log_in")
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "POST /argonusers/log_in" do
    test "logs the argonusers in", %{conn: conn, argonusers: argonusers} do
      conn =
        post(conn, ~p"/argonusers/log_in", %{
          "argonusers" => %{"email" => argonusers.email, "password" => valid_argonusers_password()}
        })

      assert get_session(conn, :argonusers_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ argonusers.email
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log_out"
    end

    test "logs the argonusers in with remember me", %{conn: conn, argonusers: argonusers} do
      conn =
        post(conn, ~p"/argonusers/log_in", %{
          "argonusers" => %{
            "email" => argonusers.email,
            "password" => valid_argonusers_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_demo_web_argonusers_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the argonusers in with return to", %{conn: conn, argonusers: argonusers} do
      conn =
        conn
        |> init_test_session(argonusers_return_to: "/foo/bar")
        |> post(~p"/argonusers/log_in", %{
          "argonusers" => %{
            "email" => argonusers.email,
            "password" => valid_argonusers_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "emits error message with invalid credentials", %{conn: conn, argonusers: argonusers} do
      conn =
        post(conn, ~p"/argonusers/log_in", %{
          "argonusers" => %{"email" => argonusers.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Log in"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /argonusers/log_out" do
    test "logs the argonusers out", %{conn: conn, argonusers: argonusers} do
      conn = conn |> log_in_argonusers(argonusers) |> delete(~p"/argonusers/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :argonusers_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the argonusers is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/argonusers/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :argonusers_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
