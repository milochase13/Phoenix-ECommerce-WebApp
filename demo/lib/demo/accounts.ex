defmodule Demo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Demo.Repo

  alias Demo.Accounts.{Argonusers, ArgonusersToken, ArgonusersNotifier}

  ## Database getters

  @doc """
  Gets a argonusers by email.

  ## Examples

      iex> get_argonusers_by_email("foo@example.com")
      %Argonusers{}

      iex> get_argonusers_by_email("unknown@example.com")
      nil

  """
  def get_argonusers_by_email(email) when is_binary(email) do
    Repo.get_by(Argonusers, email: email)
  end

  @doc """
  Gets a argonusers by email and password.

  ## Examples

      iex> get_argonusers_by_email_and_password("foo@example.com", "correct_password")
      %Argonusers{}

      iex> get_argonusers_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_argonusers_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    argonusers = Repo.get_by(Argonusers, email: email)
    if Argonusers.valid_password?(argonusers, password), do: argonusers
  end

  @doc """
  Gets a single argonusers.

  Raises `Ecto.NoResultsError` if the Argonusers does not exist.

  ## Examples

      iex> get_argonusers!(123)
      %Argonusers{}

      iex> get_argonusers!(456)
      ** (Ecto.NoResultsError)

  """
  def get_argonusers!(id), do: Repo.get!(Argonusers, id)

  ## Argonusers registration

  @doc """
  Registers a argonusers.

  ## Examples

      iex> register_argonusers(%{field: value})
      {:ok, %Argonusers{}}

      iex> register_argonusers(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_argonusers(attrs) do
    %Argonusers{}
    |> Argonusers.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking argonusers changes.

  ## Examples

      iex> change_argonusers_registration(argonusers)
      %Ecto.Changeset{data: %Argonusers{}}

  """
  def change_argonusers_registration(%Argonusers{} = argonusers, attrs \\ %{}) do
    Argonusers.registration_changeset(argonusers, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the argonusers email.

  ## Examples

      iex> change_argonusers_email(argonusers)
      %Ecto.Changeset{data: %Argonusers{}}

  """
  def change_argonusers_email(argonusers, attrs \\ %{}) do
    Argonusers.email_changeset(argonusers, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_argonusers_email(argonusers, "valid password", %{email: ...})
      {:ok, %Argonusers{}}

      iex> apply_argonusers_email(argonusers, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_argonusers_email(argonusers, password, attrs) do
    argonusers
    |> Argonusers.email_changeset(attrs)
    |> Argonusers.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the argonusers email using the given token.

  If the token matches, the argonusers email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_argonusers_email(argonusers, token) do
    context = "change:#{argonusers.email}"

    with {:ok, query} <- ArgonusersToken.verify_change_email_token_query(token, context),
         %ArgonusersToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(argonusers_email_multi(argonusers, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp argonusers_email_multi(argonusers, email, context) do
    changeset =
      argonusers
      |> Argonusers.email_changeset(%{email: email})
      |> Argonusers.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:argonusers, changeset)
    |> Ecto.Multi.delete_all(:tokens, ArgonusersToken.argonusers_and_contexts_query(argonusers, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given argonusers.

  ## Examples

      iex> deliver_argonusers_update_email_instructions(argonusers, current_email, &url(~p"/argonusers/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_argonusers_update_email_instructions(%Argonusers{} = argonusers, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, argonusers_token} = ArgonusersToken.build_email_token(argonusers, "change:#{current_email}")

    Repo.insert!(argonusers_token)
    ArgonusersNotifier.deliver_update_email_instructions(argonusers, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the argonusers password.

  ## Examples

      iex> change_argonusers_password(argonusers)
      %Ecto.Changeset{data: %Argonusers{}}

  """
  def change_argonusers_password(argonusers, attrs \\ %{}) do
    Argonusers.password_changeset(argonusers, attrs, hash_password: false)
  end

  @doc """
  Updates the argonusers password.

  ## Examples

      iex> update_argonusers_password(argonusers, "valid password", %{password: ...})
      {:ok, %Argonusers{}}

      iex> update_argonusers_password(argonusers, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_argonusers_password(argonusers, password, attrs) do
    changeset =
      argonusers
      |> Argonusers.password_changeset(attrs)
      |> Argonusers.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:argonusers, changeset)
    |> Ecto.Multi.delete_all(:tokens, ArgonusersToken.argonusers_and_contexts_query(argonusers, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{argonusers: argonusers}} -> {:ok, argonusers}
      {:error, :argonusers, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_argonusers_session_token(argonusers) do
    {token, argonusers_token} = ArgonusersToken.build_session_token(argonusers)
    Repo.insert!(argonusers_token)
    token
  end

  @doc """
  Gets the argonusers with the given signed token.
  """
  def get_argonusers_by_session_token(token) do
    {:ok, query} = ArgonusersToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_argonusers_session_token(token) do
    Repo.delete_all(ArgonusersToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given argonusers.

  ## Examples

      iex> deliver_argonusers_confirmation_instructions(argonusers, &url(~p"/argonusers/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_argonusers_confirmation_instructions(confirmed_argonusers, &url(~p"/argonusers/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_argonusers_confirmation_instructions(%Argonusers{} = argonusers, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if argonusers.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, argonusers_token} = ArgonusersToken.build_email_token(argonusers, "confirm")
      Repo.insert!(argonusers_token)
      ArgonusersNotifier.deliver_confirmation_instructions(argonusers, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a argonusers by the given token.

  If the token matches, the argonusers account is marked as confirmed
  and the token is deleted.
  """
  def confirm_argonusers(token) do
    with {:ok, query} <- ArgonusersToken.verify_email_token_query(token, "confirm"),
         %Argonusers{} = argonusers <- Repo.one(query),
         {:ok, %{argonusers: argonusers}} <- Repo.transaction(confirm_argonusers_multi(argonusers)) do
      {:ok, argonusers}
    else
      _ -> :error
    end
  end

  defp confirm_argonusers_multi(argonusers) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:argonusers, Argonusers.confirm_changeset(argonusers))
    |> Ecto.Multi.delete_all(:tokens, ArgonusersToken.argonusers_and_contexts_query(argonusers, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given argonusers.

  ## Examples

      iex> deliver_argonusers_reset_password_instructions(argonusers, &url(~p"/argonusers/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_argonusers_reset_password_instructions(%Argonusers{} = argonusers, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, argonusers_token} = ArgonusersToken.build_email_token(argonusers, "reset_password")
    Repo.insert!(argonusers_token)
    ArgonusersNotifier.deliver_reset_password_instructions(argonusers, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the argonusers by reset password token.

  ## Examples

      iex> get_argonusers_by_reset_password_token("validtoken")
      %Argonusers{}

      iex> get_argonusers_by_reset_password_token("invalidtoken")
      nil

  """
  def get_argonusers_by_reset_password_token(token) do
    with {:ok, query} <- ArgonusersToken.verify_email_token_query(token, "reset_password"),
         %Argonusers{} = argonusers <- Repo.one(query) do
      argonusers
    else
      _ -> nil
    end
  end

  @doc """
  Resets the argonusers password.

  ## Examples

      iex> reset_argonusers_password(argonusers, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Argonusers{}}

      iex> reset_argonusers_password(argonusers, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_argonusers_password(argonusers, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:argonusers, Argonusers.password_changeset(argonusers, attrs))
    |> Ecto.Multi.delete_all(:tokens, ArgonusersToken.argonusers_and_contexts_query(argonusers, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{argonusers: argonusers}} -> {:ok, argonusers}
      {:error, :argonusers, changeset, _} -> {:error, changeset}
    end
  end
end
