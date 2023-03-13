defmodule DemoWeb.ArgonusersSessionController do
  use DemoWeb, :controller

  alias Demo.Accounts
  alias DemoWeb.ArgonusersAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"argonusers" => argonusers_params}) do
    %{"email" => email, "password" => password} = argonusers_params

    if argonusers = Accounts.get_argonusers_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> ArgonusersAuth.log_in_argonusers(argonusers, argonusers_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> ArgonusersAuth.log_out_argonusers()
  end
end
