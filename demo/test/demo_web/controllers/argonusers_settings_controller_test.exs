defmodule DemoWeb.ArgonusersSettingsControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  import Demo.AccountsFixtures

  setup :register_and_log_in_argonusers

  describe "GET /argonusers/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/argonusers/settings")
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if argonusers is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/argonusers/settings")
      assert redirected_to(conn) == ~p"/argonusers/log_in"
    end
  end

  describe "PUT /argonusers/settings (change password form)" do
    test "updates the argonusers password and resets tokens", %{conn: conn, argonusers: argonusers} do
      new_password_conn =
        put(conn, ~p"/argonusers/settings", %{
          "action" => "update_password",
          "current_password" => valid_argonusers_password(),
          "argonusers" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/argonusers/settings"

      assert get_session(new_password_conn, :argonusers_token) != get_session(conn, :argonusers_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_argonusers_by_email_and_password(argonusers.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/argonusers/settings", %{
          "action" => "update_password",
          "current_password" => "invalid",
          "argonusers" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Settings"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :argonusers_token) == get_session(conn, :argonusers_token)
    end
  end

  describe "PUT /argonusers/settings (change email form)" do
    @tag :capture_log
    test "updates the argonusers email", %{conn: conn, argonusers: argonusers} do
      conn =
        put(conn, ~p"/argonusers/settings", %{
          "action" => "update_email",
          "current_password" => valid_argonusers_password(),
          "argonusers" => %{"email" => unique_argonusers_email()}
        })

      assert redirected_to(conn) == ~p"/argonusers/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_argonusers_by_email(argonusers.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/argonusers/settings", %{
          "action" => "update_email",
          "current_password" => "invalid",
          "argonusers" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /argonusers/settings/confirm_email/:token" do
    setup %{argonusers: argonusers} do
      email = unique_argonusers_email()

      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_update_email_instructions(%{argonusers | email: email}, argonusers.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the argonusers email once", %{conn: conn, argonusers: argonusers, token: token, email: email} do
      conn = get(conn, ~p"/argonusers/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/argonusers/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_argonusers_by_email(argonusers.email)
      assert Accounts.get_argonusers_by_email(email)

      conn = get(conn, ~p"/argonusers/settings/confirm_email/#{token}")

      assert redirected_to(conn) == ~p"/argonusers/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, argonusers: argonusers} do
      conn = get(conn, ~p"/argonusers/settings/confirm_email/oops")
      assert redirected_to(conn) == ~p"/argonusers/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_argonusers_by_email(argonusers.email)
    end

    test "redirects if argonusers is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/argonusers/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/argonusers/log_in"
    end
  end
end
