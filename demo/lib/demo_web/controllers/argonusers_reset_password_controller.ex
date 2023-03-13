defmodule DemoWeb.ArgonusersResetPasswordController do
  use DemoWeb, :controller

  alias Demo.Accounts

  plug :get_argonusers_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"argonusers" => %{"email" => email}}) do
    if argonusers = Accounts.get_argonusers_by_email(email) do
      Accounts.deliver_argonusers_reset_password_instructions(
        argonusers,
        &url(~p"/argonusers/reset_password/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, _params) do
    render(conn, :edit, changeset: Accounts.change_argonusers_password(conn.assigns.argonusers))
  end

  # Do not log in the argonusers after reset password to avoid a
  # leaked token giving the argonusers access to the account.
  def update(conn, %{"argonusers" => argonusers_params}) do
    case Accounts.reset_argonusers_password(conn.assigns.argonusers, argonusers_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: ~p"/argonusers/log_in")

      {:error, changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp get_argonusers_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if argonusers = Accounts.get_argonusers_by_reset_password_token(token) do
      conn |> assign(:argonusers, argonusers) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
