defmodule DemoWeb.ArgonusersSettingsController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.ArgonusersAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "argonusers" => argonusers_params} = params
    argonusers = conn.assigns.current_argonusers

    case Accounts.apply_argonusers_email(argonusers, password, argonusers_params) do
      {:ok, applied_argonusers} ->
        Accounts.deliver_argonusers_update_email_instructions(
          applied_argonusers,
          argonusers.email,
          &url(~p"/argonusers/settings/confirm_email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/argonusers/settings")

      {:error, changeset} ->
        render(conn, :edit, email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "argonusers" => argonusers_params} = params
    argonusers = conn.assigns.current_argonusers

    case Accounts.update_argonusers_password(argonusers, password, argonusers_params) do
      {:ok, argonusers} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:argonusers_return_to, ~p"/argonusers/settings")
        |> ArgonusersAuth.log_in_argonusers(argonusers)

      {:error, changeset} ->
        render(conn, :edit, password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_argonusers_email(conn.assigns.current_argonusers, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/argonusers/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/argonusers/settings")
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    argonusers = conn.assigns.current_argonusers

    conn
    |> assign(:email_changeset, Accounts.change_argonusers_email(argonusers))
    |> assign(:password_changeset, Accounts.change_argonusers_password(argonusers))
  end
end
