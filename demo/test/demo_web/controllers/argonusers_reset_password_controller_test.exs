defmodule DemoWeb.ArgonusersResetPasswordControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  alias Demo.Repo
  import Demo.AccountsFixtures

  setup do
    %{argonusers: argonusers_fixture()}
  end

  describe "GET /argonusers/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, ~p"/argonusers/reset_password")
      response = html_response(conn, 200)
      assert response =~ "Forgot your password?"
    end
  end

  describe "POST /argonusers/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, argonusers: argonusers} do
      conn =
        post(conn, ~p"/argonusers/reset_password", %{
          "argonusers" => %{"email" => argonusers.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.ArgonusersToken, argonusers_id: argonusers.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/argonusers/reset_password", %{
          "argonusers" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.ArgonusersToken) == []
    end
  end

  describe "GET /argonusers/reset_password/:token" do
    setup %{argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_reset_password_instructions(argonusers, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, ~p"/argonusers/reset_password/#{token}")
      assert html_response(conn, 200) =~ "Reset password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/argonusers/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /argonusers/reset_password/:token" do
    setup %{argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_reset_password_instructions(argonusers, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, argonusers: argonusers, token: token} do
      conn =
        put(conn, ~p"/argonusers/reset_password/#{token}", %{
          "argonusers" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/argonusers/log_in"
      refute get_session(conn, :argonusers_token)

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Password reset successfully"

      assert Accounts.get_argonusers_by_email_and_password(argonusers.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/argonusers/reset_password/#{token}", %{
          "argonusers" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert html_response(conn, 200) =~ "something went wrong"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/argonusers/reset_password/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Reset password link is invalid or it has expired"
    end
  end
end
