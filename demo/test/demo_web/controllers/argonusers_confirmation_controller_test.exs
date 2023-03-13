defmodule DemoWeb.ArgonusersConfirmationControllerTest do
  use DemoWeb.ConnCase, async: true

  alias Demo.Accounts
  alias Demo.Repo
  import Demo.AccountsFixtures

  setup do
    %{argonusers: argonusers_fixture()}
  end

  describe "GET /argonusers/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/argonusers/confirm")
      response = html_response(conn, 200)
      assert response =~ "Resend confirmation instructions"
    end
  end

  describe "POST /argonusers/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, argonusers: argonusers} do
      conn =
        post(conn, ~p"/argonusers/confirm", %{
          "argonusers" => %{"email" => argonusers.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.ArgonusersToken, argonusers_id: argonusers.id).context == "confirm"
    end

    test "does not send confirmation token if Argonusers is confirmed", %{conn: conn, argonusers: argonusers} do
      Repo.update!(Accounts.Argonusers.confirm_changeset(argonusers))

      conn =
        post(conn, ~p"/argonusers/confirm", %{
          "argonusers" => %{"email" => argonusers.email}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/argonusers/confirm", %{
          "argonusers" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.ArgonusersToken) == []
    end
  end

  describe "GET /argonusers/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      token_path = ~p"/argonusers/confirm/some-token"
      conn = get(conn, token_path)
      response = html_response(conn, 200)
      assert response =~ "Confirm account"

      assert response =~ "action=\"#{token_path}\""
    end
  end

  describe "POST /argonusers/confirm/:token" do
    test "confirms the given token once", %{conn: conn, argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_confirmation_instructions(argonusers, url)
        end)

      conn = post(conn, ~p"/argonusers/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Argonusers confirmed successfully"

      assert Accounts.get_argonusers!(argonusers.id).confirmed_at
      refute get_session(conn, :argonusers_token)
      assert Repo.all(Accounts.ArgonusersToken) == []

      # When not logged in
      conn = post(conn, ~p"/argonusers/confirm/#{token}")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Argonusers confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_argonusers(argonusers)
        |> post(~p"/argonusers/confirm/#{token}")

      assert redirected_to(conn) == ~p"/"
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, argonusers: argonusers} do
      conn = post(conn, ~p"/argonusers/confirm/oops")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Argonusers confirmation link is invalid or it has expired"

      refute Accounts.get_argonusers!(argonusers.id).confirmed_at
    end
  end
end
