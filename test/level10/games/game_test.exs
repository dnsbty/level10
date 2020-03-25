defmodule Level10.Games.GameTest do
  use ExUnit.Case, async: true
  alias Level10.Games.{Card, Game, Player}

  describe "start_round/1" do
    @game Game.new("ABCD", Player.new("Player 1"))

    test "increments the current_round" do
      assert @game.current_round == 0
      {:ok, game} = Game.start_round(@game)
      assert game.current_round == 1
    end

    test "gives each player a hand with 10 cards" do
      assert @game.hands == %{}

      {:ok, game} = Game.put_player(@game, Player.new("Player 2"))
      {:ok, game} = Game.start_round(game)

      [player1, player2] = game.players

      assert length(game.hands[player1.id]) == 10
      assert length(game.hands[player2.id]) == 10
    end

    test "attaches a new deck with 108 cards - 20 (for 2 hands)" do
      assert @game.draw_pile == []

      {:ok, game} = Game.put_player(@game, Player.new("Player 2"))
      {:ok, game} = Game.start_round(game)

      assert length(game.draw_pile) == 88
    end
  end

  describe "complete_round/1" do
    @game Game.new("ABCD", Player.new("Player 1"))
    # @game Game.new([Player.new("Player 1"), Player.new("Player 2")])
    @hand_nothing [
      %Card{color: :blue, value: :one},
      %Card{color: :red, value: :one},
      %Card{color: :yellow, value: :three},
      %Card{color: :red, value: :five},
      %Card{color: :blue, value: :five},
      %Card{color: :green, value: :eight},
      %Card{color: :green, value: :eight},
      %Card{color: :yellow, value: :ten},
      %Card{color: :green, value: :wild},
      %Card{color: :blue, value: :skip}
    ]

    set = [
      %Card{color: :green, value: :two},
      %Card{color: :green, value: :two},
      %Card{color: :blue, value: :two},
      %Card{color: :red, value: :two}
    ]

    run = [
      %Card{color: :red, value: :two},
      %Card{color: :yellow, value: :two},
      %Card{color: :red, value: :two},
      %Card{color: :blue, value: :two},
      %Card{color: :green, value: :two},
      %Card{color: :green, value: :two}
    ]

    @level3 [set: set, run: run]

    test "correctly calculates the scoring and advances levels" do
      scoring = %{"Player 1" => {2, 45}, "Player 2" => {2, 0}}
      hands = %{"Player 1" => [], "Player 2" => @hand_nothing}
      table = %{"Player 1" => @level3}

      game = %{@game | current_round: 2, hands: hands, scoring: scoring, table: table}

      game = Game.complete_round(game)

      assert game.current_round == 2
      assert game.scoring["Player 1"] == {3, 45}
      assert game.scoring["Player 2"] == {2, 85}
    end

    test "clears the round artifacts" do
      scoring = %{"Player 1" => {2, 45}, "Player 2" => {2, 0}}
      hands = %{"Player 1" => [], "Player 2" => @hand_nothing}
      table = %{"Player 1" => @level3}

      game = %{@game | current_round: 2, hands: hands, scoring: scoring, table: table}

      game = Game.complete_round(game)

      assert game.discard_pile == []
      assert game.draw_pile == []
      assert game.hands == %{}
      assert game.table == %{}
    end

    test "determines whether the game was completed" do
      scoring = %{"Player 1" => {10, 45}, "Player 2" => {9, 0}}
      hands = %{"Player 1" => [], "Player 2" => @hand_nothing}
      table = %{"Player 1" => @level3}

      game = %{@game | current_round: 2, hands: hands, scoring: scoring, table: table}

      game = Game.complete_round(game)

      assert game.current_stage == :finish
    end
  end
end
