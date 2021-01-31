defmodule Level10.Accounts.UserNotifier do
  @moduledoc """
  For several actions, the user needs to be notified. This module is
  responsible for sending those notifications to the appropriate user.
  """

  use Bamboo.Phoenix, view: Level10Mailer.AccountsView
  import Bamboo.Email
  alias Level10Mailer, as: Mailer

  @from_address {"Dennis from Level 10", "dennis@level10.games"}

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    email =
      new_email()
      |> from(@from_address)
      |> to({user.username, user.email})
      |> subject("Confirm your Level 10 account")
      |> assign(:user, user)
      |> assign(:url, url)
      |> render(:confirm_email)
      |> Mailer.deliver_now()

    {:ok, email}
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    email =
      new_email()
      |> from(@from_address)
      |> to({user.username, user.email})
      |> subject("Reset your password for Level 10")
      |> assign(:user, user)
      |> assign(:url, url)
      |> render(:reset_password)
      |> Mailer.deliver_now()

    {:ok, email}
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    email =
      new_email()
      |> from(@from_address)
      |> to({user.username, user.email})
      |> subject("Change your email address for Level 10")
      |> assign(:user, user)
      |> assign(:url, url)
      |> render(:change_email)
      |> Mailer.deliver_now()

    {:ok, email}
  end
end
