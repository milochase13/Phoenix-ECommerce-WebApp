defmodule Demo.AccountsTest do
  use Demo.DataCase

  alias Demo.Accounts

  import Demo.AccountsFixtures
  alias Demo.Accounts.{Argonusers, ArgonusersToken}

  describe "get_argonusers_by_email/1" do
    test "does not return the argonusers if the email does not exist" do
      refute Accounts.get_argonusers_by_email("unknown@example.com")
    end

    test "returns the argonusers if the email exists" do
      %{id: id} = argonusers = argonusers_fixture()
      assert %Argonusers{id: ^id} = Accounts.get_argonusers_by_email(argonusers.email)
    end
  end

  describe "get_argonusers_by_email_and_password/2" do
    test "does not return the argonusers if the email does not exist" do
      refute Accounts.get_argonusers_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the argonusers if the password is not valid" do
      argonusers = argonusers_fixture()
      refute Accounts.get_argonusers_by_email_and_password(argonusers.email, "invalid")
    end

    test "returns the argonusers if the email and password are valid" do
      %{id: id} = argonusers = argonusers_fixture()

      assert %Argonusers{id: ^id} =
               Accounts.get_argonusers_by_email_and_password(argonusers.email, valid_argonusers_password())
    end
  end

  describe "get_argonusers!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_argonusers!(-1)
      end
    end

    test "returns the argonusers with the given id" do
      %{id: id} = argonusers = argonusers_fixture()
      assert %Argonusers{id: ^id} = Accounts.get_argonusers!(argonusers.id)
    end
  end

  describe "register_argonusers/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_argonusers(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_argonusers(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_argonusers(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = argonusers_fixture()
      {:error, changeset} = Accounts.register_argonusers(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_argonusers(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers argonusers with a hashed password" do
      email = unique_argonusers_email()
      {:ok, argonusers} = Accounts.register_argonusers(valid_argonusers_attributes(email: email))
      assert argonusers.email == email
      assert is_binary(argonusers.hashed_password)
      assert is_nil(argonusers.confirmed_at)
      assert is_nil(argonusers.password)
    end
  end

  describe "change_argonusers_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_argonusers_registration(%Argonusers{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_argonusers_email()
      password = valid_argonusers_password()

      changeset =
        Accounts.change_argonusers_registration(
          %Argonusers{},
          valid_argonusers_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_argonusers_email/2" do
    test "returns a argonusers changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_argonusers_email(%Argonusers{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_argonusers_email/3" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "requires email to change", %{argonusers: argonusers} do
      {:error, changeset} = Accounts.apply_argonusers_email(argonusers, valid_argonusers_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{argonusers: argonusers} do
      {:error, changeset} =
        Accounts.apply_argonusers_email(argonusers, valid_argonusers_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{argonusers: argonusers} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_argonusers_email(argonusers, valid_argonusers_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{argonusers: argonusers} do
      %{email: email} = argonusers_fixture()
      password = valid_argonusers_password()

      {:error, changeset} = Accounts.apply_argonusers_email(argonusers, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{argonusers: argonusers} do
      {:error, changeset} =
        Accounts.apply_argonusers_email(argonusers, "invalid", %{email: unique_argonusers_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{argonusers: argonusers} do
      email = unique_argonusers_email()
      {:ok, argonusers} = Accounts.apply_argonusers_email(argonusers, valid_argonusers_password(), %{email: email})
      assert argonusers.email == email
      assert Accounts.get_argonusers!(argonusers.id).email != email
    end
  end

  describe "deliver_argonusers_update_email_instructions/3" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "sends token through notification", %{argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_update_email_instructions(argonusers, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert argonusers_token = Repo.get_by(ArgonusersToken, token: :crypto.hash(:sha256, token))
      assert argonusers_token.argonusers_id == argonusers.id
      assert argonusers_token.sent_to == argonusers.email
      assert argonusers_token.context == "change:current@example.com"
    end
  end

  describe "update_argonusers_email/2" do
    setup do
      argonusers = argonusers_fixture()
      email = unique_argonusers_email()

      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_update_email_instructions(%{argonusers | email: email}, argonusers.email, url)
        end)

      %{argonusers: argonusers, token: token, email: email}
    end

    test "updates the email with a valid token", %{argonusers: argonusers, token: token, email: email} do
      assert Accounts.update_argonusers_email(argonusers, token) == :ok
      changed_argonusers = Repo.get!(Argonusers, argonusers.id)
      assert changed_argonusers.email != argonusers.email
      assert changed_argonusers.email == email
      assert changed_argonusers.confirmed_at
      assert changed_argonusers.confirmed_at != argonusers.confirmed_at
      refute Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not update email with invalid token", %{argonusers: argonusers} do
      assert Accounts.update_argonusers_email(argonusers, "oops") == :error
      assert Repo.get!(Argonusers, argonusers.id).email == argonusers.email
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not update email if argonusers email changed", %{argonusers: argonusers, token: token} do
      assert Accounts.update_argonusers_email(%{argonusers | email: "current@example.com"}, token) == :error
      assert Repo.get!(Argonusers, argonusers.id).email == argonusers.email
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not update email if token expired", %{argonusers: argonusers, token: token} do
      {1, nil} = Repo.update_all(ArgonusersToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_argonusers_email(argonusers, token) == :error
      assert Repo.get!(Argonusers, argonusers.id).email == argonusers.email
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end
  end

  describe "change_argonusers_password/2" do
    test "returns a argonusers changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_argonusers_password(%Argonusers{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_argonusers_password(%Argonusers{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_argonusers_password/3" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "validates password", %{argonusers: argonusers} do
      {:error, changeset} =
        Accounts.update_argonusers_password(argonusers, valid_argonusers_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{argonusers: argonusers} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_argonusers_password(argonusers, valid_argonusers_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{argonusers: argonusers} do
      {:error, changeset} =
        Accounts.update_argonusers_password(argonusers, "invalid", %{password: valid_argonusers_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{argonusers: argonusers} do
      {:ok, argonusers} =
        Accounts.update_argonusers_password(argonusers, valid_argonusers_password(), %{
          password: "new valid password"
        })

      assert is_nil(argonusers.password)
      assert Accounts.get_argonusers_by_email_and_password(argonusers.email, "new valid password")
    end

    test "deletes all tokens for the given argonusers", %{argonusers: argonusers} do
      _ = Accounts.generate_argonusers_session_token(argonusers)

      {:ok, _} =
        Accounts.update_argonusers_password(argonusers, valid_argonusers_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end
  end

  describe "generate_argonusers_session_token/1" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "generates a token", %{argonusers: argonusers} do
      token = Accounts.generate_argonusers_session_token(argonusers)
      assert argonusers_token = Repo.get_by(ArgonusersToken, token: token)
      assert argonusers_token.context == "session"

      # Creating the same token for another argonusers should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%ArgonusersToken{
          token: argonusers_token.token,
          argonusers_id: argonusers_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_argonusers_by_session_token/1" do
    setup do
      argonusers = argonusers_fixture()
      token = Accounts.generate_argonusers_session_token(argonusers)
      %{argonusers: argonusers, token: token}
    end

    test "returns argonusers by token", %{argonusers: argonusers, token: token} do
      assert session_argonusers = Accounts.get_argonusers_by_session_token(token)
      assert session_argonusers.id == argonusers.id
    end

    test "does not return argonusers for invalid token" do
      refute Accounts.get_argonusers_by_session_token("oops")
    end

    test "does not return argonusers for expired token", %{token: token} do
      {1, nil} = Repo.update_all(ArgonusersToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_argonusers_by_session_token(token)
    end
  end

  describe "delete_argonusers_session_token/1" do
    test "deletes the token" do
      argonusers = argonusers_fixture()
      token = Accounts.generate_argonusers_session_token(argonusers)
      assert Accounts.delete_argonusers_session_token(token) == :ok
      refute Accounts.get_argonusers_by_session_token(token)
    end
  end

  describe "deliver_argonusers_confirmation_instructions/2" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "sends token through notification", %{argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_confirmation_instructions(argonusers, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert argonusers_token = Repo.get_by(ArgonusersToken, token: :crypto.hash(:sha256, token))
      assert argonusers_token.argonusers_id == argonusers.id
      assert argonusers_token.sent_to == argonusers.email
      assert argonusers_token.context == "confirm"
    end
  end

  describe "confirm_argonusers/1" do
    setup do
      argonusers = argonusers_fixture()

      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_confirmation_instructions(argonusers, url)
        end)

      %{argonusers: argonusers, token: token}
    end

    test "confirms the email with a valid token", %{argonusers: argonusers, token: token} do
      assert {:ok, confirmed_argonusers} = Accounts.confirm_argonusers(token)
      assert confirmed_argonusers.confirmed_at
      assert confirmed_argonusers.confirmed_at != argonusers.confirmed_at
      assert Repo.get!(Argonusers, argonusers.id).confirmed_at
      refute Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not confirm with invalid token", %{argonusers: argonusers} do
      assert Accounts.confirm_argonusers("oops") == :error
      refute Repo.get!(Argonusers, argonusers.id).confirmed_at
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not confirm email if token expired", %{argonusers: argonusers, token: token} do
      {1, nil} = Repo.update_all(ArgonusersToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_argonusers(token) == :error
      refute Repo.get!(Argonusers, argonusers.id).confirmed_at
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end
  end

  describe "deliver_argonusers_reset_password_instructions/2" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "sends token through notification", %{argonusers: argonusers} do
      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_reset_password_instructions(argonusers, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert argonusers_token = Repo.get_by(ArgonusersToken, token: :crypto.hash(:sha256, token))
      assert argonusers_token.argonusers_id == argonusers.id
      assert argonusers_token.sent_to == argonusers.email
      assert argonusers_token.context == "reset_password"
    end
  end

  describe "get_argonusers_by_reset_password_token/1" do
    setup do
      argonusers = argonusers_fixture()

      token =
        extract_argonusers_token(fn url ->
          Accounts.deliver_argonusers_reset_password_instructions(argonusers, url)
        end)

      %{argonusers: argonusers, token: token}
    end

    test "returns the argonusers with valid token", %{argonusers: %{id: id}, token: token} do
      assert %Argonusers{id: ^id} = Accounts.get_argonusers_by_reset_password_token(token)
      assert Repo.get_by(ArgonusersToken, argonusers_id: id)
    end

    test "does not return the argonusers with invalid token", %{argonusers: argonusers} do
      refute Accounts.get_argonusers_by_reset_password_token("oops")
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end

    test "does not return the argonusers if token expired", %{argonusers: argonusers, token: token} do
      {1, nil} = Repo.update_all(ArgonusersToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_argonusers_by_reset_password_token(token)
      assert Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end
  end

  describe "reset_argonusers_password/2" do
    setup do
      %{argonusers: argonusers_fixture()}
    end

    test "validates password", %{argonusers: argonusers} do
      {:error, changeset} =
        Accounts.reset_argonusers_password(argonusers, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{argonusers: argonusers} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_argonusers_password(argonusers, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{argonusers: argonusers} do
      {:ok, updated_argonusers} = Accounts.reset_argonusers_password(argonusers, %{password: "new valid password"})
      assert is_nil(updated_argonusers.password)
      assert Accounts.get_argonusers_by_email_and_password(argonusers.email, "new valid password")
    end

    test "deletes all tokens for the given argonusers", %{argonusers: argonusers} do
      _ = Accounts.generate_argonusers_session_token(argonusers)
      {:ok, _} = Accounts.reset_argonusers_password(argonusers, %{password: "new valid password"})
      refute Repo.get_by(ArgonusersToken, argonusers_id: argonusers.id)
    end
  end

  describe "inspect/2 for the Argonusers module" do
    test "does not include password" do
      refute inspect(%Argonusers{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
