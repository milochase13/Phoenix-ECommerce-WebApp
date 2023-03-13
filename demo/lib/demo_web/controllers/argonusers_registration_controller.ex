defmodule DemoWeb.ArgonusersRegistrationController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias Demo.Accounts.Argonusers
  alias DemoWeb.ArgonusersAuth

  def new(conn, _params) do
    changeset = Accounts.change_argonusers_registration(%Argonusers{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"argonusers" => argonusers_params}) do
    case Accounts.register_argonusers(argonusers_params) do
      {:ok, argonusers} ->
        {:ok, _} =
          Accounts.deliver_argonusers_confirmation_instructions(
            argonusers,
            &url(~p"/argonusers/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Argonusers created successfully.")
        |> ArgonusersAuth.log_in_argonusers(argonusers)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end
end
