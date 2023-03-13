defmodule Demo.Accounts.ArgonusersNotifier do
  import Swoosh.Email

  alias Demo.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Demo", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(argonusers, url) do
    deliver(argonusers.email, "Confirmation instructions", """

    ==============================

    Hi #{argonusers.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a argonusers password.
  """
  def deliver_reset_password_instructions(argonusers, url) do
    deliver(argonusers.email, "Reset password instructions", """

    ==============================

    Hi #{argonusers.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a argonusers email.
  """
  def deliver_update_email_instructions(argonusers, url) do
    deliver(argonusers.email, "Update email instructions", """

    ==============================

    Hi #{argonusers.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
