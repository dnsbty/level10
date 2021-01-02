defmodule Level10.Accounts.UserNotifier do
  @moduledoc """
  For several actions, the user needs to be notified. This module is
  responsible for sending those notifications to the appropriate user.

  For simplicity, this module simply logs messages to the terminal.
  You should replace it by a proper email or notification tool, such as:

    * Swoosh - https://hexdocs.pm/swoosh
    * Bamboo - https://hexdocs.pm/bamboo
  """

  import Bamboo.Email
  alias Level10.Mailer

  @from_address "dennis@level10.games"

  defp deliver(to, subject, text_body, html_body) do
    email =
      new_email(
        to: to,
        from: @from_address,
        subject: subject,
        text_body: text_body,
        html_body: html_body
      )
      |> Mailer.deliver_now()

    {:ok, email}
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.username},

    You can confirm your account by visiting the url below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.username},<br/></br/>
    You can confirm your account by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't create an account with us, please ignore this.
    """

    deliver(user.email, "Confirm your Level 10 account", text_body, html_body)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.username},

    You can reset your password by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.username},<br/></br/>
    You can reset your password by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't request this change, please ignore this.
    """

    deliver(user.email, "Reset your password for Level 10", text_body, html_body)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    text_body = """

    ==============================

    Hi #{user.username},

    You can change your e-mail by visiting the url below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """

    html_body = """
    Hi #{user.username},<br/></br/>
    You can change your e-mail by visiting the url below:<br/></br/>
    <a href="#{url}" target="_blank">#{url}</a><br/></br/>
    If you didn't request this change, please ignore this.
    """

    deliver(user.email, "Please confirm your email change request", text_body, html_body)
  end
end
