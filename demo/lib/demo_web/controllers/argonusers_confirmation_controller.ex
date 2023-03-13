defmodule DemoWeb.ArgonusersConfirmationController do
  use DemoWeb, :controller

  alias Demo.Accounts

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(conn, %{"argonusers" => %{"email" => email}}) do
    if argonusers = Accounts.get_argonusers_by_email(email) do
      Accounts.deliver_argonusers_confirmation_instructions(
        argonusers,
        &url(~p"/argonusers/confirm/#{&1}")
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: ~p"/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, :edit, token: token)
  end

  # Do not log in the argonusers after confirmation to avoid a
  # leaked token giving the argonusers access to the account.
  def update(conn, %{"token" => token}) do
    case Accounts.confirm_argonusers(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Argonusers confirmed successfully.")
        |> redirect(to: ~p"/")

      :error ->
        # If there is a current argonusers and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the argonusers themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_argonusers: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: ~p"/")

          %{} ->
            conn
            |> put_flash(:error, "Argonusers confirmation link is invalid or it has expired.")
            |> redirect(to: ~p"/")
        end
    end
  end
end
