defmodule Level10.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Level10.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_username, do: "user#{String.slice("#{System.unique_integer()}", -11, 11)}"
  def valid_ip_address, do: {127, 0, 0, 1}
  def valid_user_password, do: "h3ll0 w0rld!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        ip_address: valid_ip_address(),
        password: valid_user_password(),
        username: unique_username()
      })
      |> Level10.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.text_body, "[TOKEN]")
    token
  end
end
