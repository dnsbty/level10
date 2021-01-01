defmodule Level10.Games.GameTest do
  use ExUnit.Case, async: true
  alias Level10.Games.{Card, Game, Player, Settings}

  @player1 %Player{id: "cecd022f-25c2-4477-adef-07d8d824a0ed", name: "Player 1"}
  @player2 %Player{id: "ceeb95bd-3a23-4db8-a6a5-c278c470cae6", name: "Player 2"}
  @player3 %Player{id: "0cf7943e-3256-4493-bc22-0c230eb9208e", name: "Player 3"}

  @game Game.new("ABCD", @player1, Settings.default())

  describe "complete_round/1" do
    @hand_nothing [
      %Card{color: :blue, value: :one},
      %Card{color: :red, value: :one},
      %Card{color: :yellow, value: :three},
      %Card{color: :red, value: :five},
      %Card{color: :blue, value: :five},
      %Card{color: :green, value: :eight},
      %Card{color: :green, value: :eight},
      %Card{color: :yellow, value: :ten},
      %Card{color: :black, value: :wild},
      %Card{color: :black, value: :skip}
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

    test "determines whether the game was completed" do
      scoring = %{"Player 1" => {10, 45}, "Player 2" => {9, 0}}
      hands = %{"Player 1" => [], "Player 2" => @hand_nothing}
      table = %{"Player 1" => @level3}

      game = %{@game | current_round: 2, hands: hands, scoring: scoring, table: table}

      game = Game.complete_round(game)

      assert game.current_stage == :finish
    end
  end

  describe "discard/2" do
    setup do
      card = Card.new(:wild)
      hand = for _ <- 1..10, do: card
      players = [@player1, @player2, @player3]
      player_ids = Enum.map(players, & &1.id)

      hands =
        player_ids
        |> Enum.map(&{&1, hand})
        |> Enum.into(%{})
        |> Map.put(@player1.id, [card | hand])

      game = %Game{
        current_player: @player1,
        current_round: 2,
        current_turn: 1,
        discard_pile: [],
        hands: hands,
        players: players,
        remaining_players: MapSet.new(player_ids),
        skipped_players: MapSet.new()
      }

      %{card: card, game: game}
    end

    test "moves the given card from the player's hand to the discard pile", fixture do
      result = Game.discard(fixture.game, fixture.card)

      assert length(result.hands[@player1.id]) == 10
      assert result.discard_pile == [fixture.card]
    end

    test "updates to the next player's turn", fixture do
      result = Game.discard(fixture.game, fixture.card)

      assert result.current_turn == 2
      assert result.current_player == @player2
    end

    test "skips over players who have left the game", fixture do
      remaining_players = MapSet.new([@player1.id, @player3.id])
      game = Map.put(fixture.game, :remaining_players, remaining_players)
      result = Game.discard(game, fixture.card)

      assert result.current_turn == 3
      assert result.current_player == @player3
    end

    test "skips over players who have been skipped", fixture do
      game = Map.put(fixture.game, :skipped_players, MapSet.new([@player2.id]))
      result = Game.discard(game, fixture.card)

      assert result.current_turn == 3
      assert result.current_player == @player3
    end

    test "returns an error when the current user hasn't drawn yet" do
      game = %Game{current_turn_drawn?: false}
      card = Card.new(:wild)
      assert Game.discard(game, card) == :needs_to_draw
    end
  end

  describe "next_player/2" do
    setup do
      players = [@player1, @player2, @player3]
      remaining_players = players |> Enum.map(& &1.id) |> MapSet.new()
      game = %Game{players: players, remaining_players: remaining_players}
      %{game: game}
    end

    test "returns the player whose turn will be after the specified player", fixtures do
      assert Game.next_player(fixtures.game, @player1.id) == @player2
    end

    test "doesn't return players who have left the game", fixtures do
      remaining_players = MapSet.delete(fixtures.game.remaining_players, @player2.id)
      game = %{fixtures.game | remaining_players: remaining_players}
      assert Game.next_player(game, @player1.id) == @player3
    end
  end

  describe "skip_player/2" do
    test "adds the given player ID into the set of skipped players" do
      game = %Game{skipped_players: MapSet.new()}
      result = Game.skip_player(game, "4ebc0075-c609-49e3-9dcf-d5befff8fe72")
      assert result.skipped_players == MapSet.new(["4ebc0075-c609-49e3-9dcf-d5befff8fe72"])
    end

    test "returns :already_skipped if the player was already skipped" do
      game = %Game{skipped_players: MapSet.new(["4ebc0075-c609-49e3-9dcf-d5befff8fe72"])}
      result = Game.skip_player(game, "4ebc0075-c609-49e3-9dcf-d5befff8fe72")
      assert result == :already_skipped
    end
  end

  describe "start_game/1" do
    test "fails when the game only has a single player" do
      assert :single_player == Game.start_game(@game)
    end

    test "increments the current_round" do
      assert @game.current_round == 0

      {:ok, game} = Game.put_player(@game, @player2)
      {:ok, game} = Game.start_game(game)

      assert game.current_round == 1
    end

    test "gives each player a hand with 10 cards" do
      assert @game.hands == %{}

      {:ok, game} = Game.put_player(@game, @player2)
      {:ok, game} = Game.start_game(game)

      assert length(game.hands[@player1.id]) == 10
      assert length(game.hands[@player2.id]) == 10
    end

    test "attaches a new deck with 108 cards - 21 (for 2 hands and discard pile)" do
      assert @game.draw_pile == []

      {:ok, game} = Game.put_player(@game, @player2)
      {:ok, game} = Game.start_game(game)

      assert length(game.draw_pile) == 87
    end

    test "puts the top card in the discard pile" do
      assert @game.discard_pile == []

      {:ok, game} = Game.put_player(@game, @player2)
      {:ok, game} = Game.start_game(game)

      assert length(game.discard_pile) == 1
    end
  end
end
