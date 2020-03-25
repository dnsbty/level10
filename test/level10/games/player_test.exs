defmodule Level10.Games.PlayerTest do
  use ExUnit.Case, async: true
  alias Level10.Games.Player

  describe "new/1" do
    test "creates a player with name" do
      player = Player.new("Some Player")

      assert player.name == "Some Player"
    end

    test "generates a random id for player" do
      player_one = Player.new("Other Player")
      player_two = Player.new("Other Player")

      assert player_one.id != player_two.id
    end
  end
end
