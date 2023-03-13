defmodule Demo.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Demo.Accounts` context.
  """

  def unique_argonusers_email, do: "argonusers#{System.unique_integer()}@example.com"
  def valid_argonusers_password, do: "hello world!"

  def valid_argonusers_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_argonusers_email(),
      password: valid_argonusers_password()
    })
  end

  def argonusers_fixture(attrs \\ %{}) do
    {:ok, argonusers} =
      attrs
      |> valid_argonusers_attributes()
      |> Demo.Accounts.register_argonusers()

    argonusers
  end

  def extract_argonusers_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
