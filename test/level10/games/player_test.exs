defmodule Level10.Games.PlayerTest do
  use ExUnit.Case, async: true

  alias Level10.Games.Player

  describe "new/1" do
    test "creates a player from a user" do
      user = %{id: "1aff8c69-3cdd-49ae-a944-8ee25ff41a9d", name: "username"}
      player = Player.new(user)

      assert player.name == "username"
      assert player.id == "1aff8c69-3cdd-49ae-a944-8ee25ff41a9d"
    end
  end
end
