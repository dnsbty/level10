defmodule Level10.Games.PlayerTest do
  use ExUnit.Case, async: true

  alias Level10.Accounts.User
  alias Level10.Games.Player

  describe "new/1" do
    test "creates a player from a user" do
      user = %User{uid: "1aff8c69-3cdd-49ae-a944-8ee25ff41a9d", username: "username"}
      player = Player.new(user)

      assert player.name == "username"
      assert player.id == "1aff8c69-3cdd-49ae-a944-8ee25ff41a9d"
    end

    test "uses a user's display name when one is present" do
      user = %User{
        display_name: "Display name",
        uid: "1aff8c69-3cdd-49ae-a944-8ee25ff41a9d",
        username: "username"
      }

      player = Player.new(user)

      assert player.name == "Display name"
    end
  end
end
