defmodule Level10.Games.GameTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias Level10.Games.Card
  alias Level10.Games.Game
  alias Level10.Games.Player
  alias Level10.Games.Settings

  @player1 %Player{id: "cecd022f-25c2-4477-adef-07d8d824a0ed", name: "Player 1"}
  @player2 %Player{id: "ceeb95bd-3a23-4db8-a6a5-c278c470cae6", name: "Player 2"}
  @player3 %Player{id: "0cf7943e-3256-4493-bc22-0c230eb9208e", name: "Player 3"}

  @game Game.new("ABCD", @player1, Settings.default())

  describe "add_to_table/2" do
    @card %Card{color: :blue, value: :one}

    test "adds cards from player's hand to the table" do
      hands = %{
        @player1.id => [
          @card,
          %Card{color: :blue, value: :twelve},
          %Card{color: :red, value: :nine}
        ]
      }

      levels = %{@player1.id => 1, @player2.id => 1}

      table = %{
        @player1.id => %{
          0 => [
            %Card{color: :yellow, value: :twelve},
            %Card{color: :blue, value: :twelve},
            %Card{color: :red, value: :twelve}
          ],
          1 => [
            %Card{color: :yellow, value: :three},
            %Card{color: :black, value: :three},
            %Card{color: :blue, value: :three}
          ]
        },
        @player2.id => %{
          0 => [
            %Card{color: :yellow, value: :one},
            %Card{color: :green, value: :one},
            %Card{color: :red, value: :one}
          ],
          1 => [
            %Card{color: :yellow, value: :three},
            %Card{color: :black, value: :three},
            %Card{color: :blue, value: :three}
          ]
        }
      }

      params = %{
        current_player: @player1,
        current_turn_drawn?: true,
        hands: hands,
        levels: levels,
        table: table
      }

      game = Map.merge(@game, params)
      assert {:ok, game} = Game.add_to_table(game, @player1.id, @player2.id, 0, [@card])

      refute @card in game.hands[@player1.id]
      assert @card in game.table[@player2.id][0]
      assert %NaiveDateTime{} = game.updated_at
    end

    test "returns an error if the table group is invalid" do
      levels = %{@player1.id => 1, @player2.id => 1}

      table = %{
        @player1.id => %{
          0 => [
            %Card{color: :yellow, value: :twelve},
            %Card{color: :blue, value: :twelve},
            %Card{color: :red, value: :twelve}
          ],
          1 => [
            %Card{color: :yellow, value: :three},
            %Card{color: :black, value: :three},
            %Card{color: :blue, value: :three}
          ]
        },
        @player2.id => %{
          0 => [
            %Card{color: :yellow, value: :twelve},
            %Card{color: :blue, value: :twelve},
            %Card{color: :red, value: :twelve}
          ],
          1 => [
            %Card{color: :yellow, value: :three},
            %Card{color: :black, value: :three},
            %Card{color: :blue, value: :three}
          ]
        }
      }

      game = %{
        @game
        | current_player: @player1,
          current_turn_drawn?: true,
          levels: levels,
          table: table
      }

      assert :invalid_group == Game.add_to_table(game, @player1.id, @player2.id, 0, [@card])
    end

    test "returns an error if the player hasn't finished their level" do
      game = %{@game | current_player: @player1, current_turn_drawn?: true, table: %{}}
      assert :level_incomplete == Game.add_to_table(game, @player1.id, @player2.id, 0, [@card])
    end

    test "returns an error if the player hasn't drawn yet" do
      game = %{@game | current_player: @player1, current_turn_drawn?: false}
      assert :needs_to_draw == Game.add_to_table(game, @player1.id, @player2.id, 0, [@card])
    end

    test "returns an error if it's not the player's turn" do
      game = %{@game | current_player: @player2}
      assert :not_your_turn == Game.add_to_table(game, @player1.id, @player2.id, 0, [@card])
    end
  end

  describe "all_ready?/1" do
    @remaining_players MapSet.new([@player1, @player2])

    test "returns true if all remaining players have marked themselves as ready" do
      players_ready = MapSet.new([@player2, @player1])
      game = %{@game | players_ready: players_ready, remaining_players: @remaining_players}
      assert true == Game.all_ready?(game)
    end

    test "returns false if any players aren't ready yet" do
      players_ready = MapSet.new([@player2])
      game = %{@game | players_ready: players_ready, remaining_players: @remaining_players}
      assert false == Game.all_ready?(game)
    end
  end

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

    test "calculates the scoring, advances levels, and clears players_ready" do
      scoring = %{"Player 1" => {2, 45}, "Player 2" => {2, 0}}
      hands = %{"Player 1" => [], "Player 2" => @hand_nothing}
      table = %{"Player 1" => @level3}
      players_ready = MapSet.new(["Player 1", "Player 2"])

      params = %{
        current_round: 2,
        hands: hands,
        players_ready: players_ready,
        scoring: scoring,
        table: table
      }

      game =
        @game
        |> Map.merge(params)
        |> Game.complete_round()

      assert game.current_round == 2
      assert game.scoring["Player 1"] == {3, 45}
      assert game.scoring["Player 2"] == {2, 85}
      assert MapSet.size(game.players_ready) == 0
      assert %NaiveDateTime{} = game.updated_at
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

  describe "creator/1" do
    test "returns the first player in the game" do
      game = Game.new("ABCD", @player1, Settings.default())
      assert @player1 == Game.creator(game)
    end
  end

  describe "delete_player/2" do
    test "deletes a player from the game lobby" do
      game = %{@game | current_stage: :lobby, players: [@player3, @player2, @player1]}
      assert {:ok, game} = Game.delete_player(game, @player1.id)
      refute @player1 in game.players
      assert %NaiveDateTime{} = game.updated_at
    end

    test "returns an error if the game already started" do
      game = %{@game | current_stage: :play}

      logs =
        capture_log(fn ->
          assert :already_started == Game.delete_player(game, @player1.id)
        end)

      assert logs =~ "Player tried to leave game that has already started"
    end

    test "returns an error if there are no players left in the game" do
      game = %{@game | current_stage: :lobby, players: [@player1]}
      assert :empty_game == Game.delete_player(game, @player1.id)
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
      assert %NaiveDateTime{} = result.updated_at
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

  describe "draw_card/2" do
    setup do
      %{
        game: %Game{
          current_player: @player1,
          current_round: 2,
          current_turn: 1,
          current_turn_drawn?: false,
          discard_pile: [],
          draw_pile: [],
          hands: %{@player1.id => [], @player2.id => []},
          players: [@player1, @player2],
          remaining_players: MapSet.new([@player1.id, @player2.id]),
          skipped_players: MapSet.new()
        }
      }
    end

    test "moves the top card from the draw pile into the current player's hand", fixture do
      game = %{fixture.game | draw_pile: [%Card{color: :black, value: :wild}]}
      game = Game.draw_card(game, @player1.id, :draw_pile)
      assert game.draw_pile == []
      assert game.hands[@player1.id] == [%Card{color: :black, value: :wild}]
      assert %NaiveDateTime{} = game.updated_at
    end

    test "moves the top card from the discard pile into the current player's hand", fixture do
      game = %{fixture.game | discard_pile: [%Card{color: :black, value: :wild}]}
      game = Game.draw_card(game, @player1.id, :discard_pile)
      assert game.discard_pile == []
      assert game.hands[@player1.id] == [%Card{color: :black, value: :wild}]
    end

    test "reshuffles the discard pile when the draw pile is empty", fixture do
      discard_pile = [%Card{color: :red, value: :three}, %Card{color: :blue, value: :one}]
      game = %{fixture.game | discard_pile: discard_pile, draw_pile: []}
      game = Game.draw_card(game, @player1.id, :draw_pile)
      assert game.discard_pile == [%Card{color: :red, value: :three}]
      assert game.draw_pile == []
      assert game.hands[@player1.id] == [%Card{color: :blue, value: :one}]
    end

    test "returns an error if the player trying to draw isn't the current player", fixture do
      game = %{fixture.game | current_player: @player2}
      assert :not_your_turn == Game.draw_card(game, @player1.id, :draw_pile)
    end

    test "returns an error if the current player has already drawn a card", fixture do
      game = %{fixture.game | current_turn_drawn?: true}
      assert :already_drawn == Game.draw_card(game, @player1.id, :draw_pile)
    end

    test "returns an error if the discard pile is empty", fixture do
      assert :empty_discard_pile == Game.draw_card(fixture.game, @player1.id, :discard_pile)
    end

    test "returns an error if a skip card is on top of the discard pile", fixture do
      game = %{fixture.game | discard_pile: [%Card{color: :black, value: :skip}]}
      assert :skip == Game.draw_card(game, @player1.id, :discard_pile)
    end
  end

  describe "generate_join_code/0" do
    test "generates a random 4-character code" do
      assert Game.generate_join_code() =~ ~r"^[A-Z0-9]{4}$"
    end
  end

  describe "hand_counts/1" do
    test "returns the number of cards in each player's hand" do
      card = Card.new(:wild)

      hands = %{
        @player1.id => for(_ <- 1..10, do: card),
        @player2.id => for(_ <- 1..4, do: card),
        @player3.id => for(_ <- 1..11, do: card)
      }

      game = %{@game | hands: hands}
      counts = Game.hand_counts(game)

      assert counts[@player1.id] == 10
      assert counts[@player2.id] == 4
      assert counts[@player3.id] == 11
    end
  end

  describe "mark_player_ready/2" do
    test "marks a player as ready" do
      players = [@player1, @player2, @player3]
      game = %{@game | players: players, remaining_players: MapSet.new(players)}
      assert {:ok, game} = Game.mark_player_ready(game, @player1)
      assert @player1 in game.players_ready
      assert %NaiveDateTime{} = game.updated_at
    end

    test "returns the all ready status if all remaining players are ready" do
      params = %{
        players: [@player1, @player2, @player3],
        players_ready: MapSet.new([@player2, @player3]),
        remaining_players: MapSet.new([@player1, @player2, @player3])
      }

      game = Map.merge(@game, params)
      assert {:all_ready, _} = Game.mark_player_ready(game, @player1)
    end
  end

  describe "new/3" do
    test "returns a new game" do
      settings = %Settings{skip_next_player: true}
      game = Game.new("ABCD", @player1, settings)
      assert %NaiveDateTime{} = game.created_at
      assert game.current_player == @player1
      assert game.current_round == 0
      assert game.current_stage == :lobby
      assert game.current_turn == 0
      assert game.current_turn_drawn? == false
      assert game.device_tokens == %{}
      assert game.discard_pile == []
      assert game.draw_pile == []
      assert game.hands == %{}
      assert game.join_code == "ABCD"
      assert game.levels == %{}
      assert game.players == [@player1]
      assert game.players_ready == MapSet.new()
      assert game.scoring == %{}
      assert game.settings == settings
      assert game.table == %{}
      assert %NaiveDateTime{} = game.updated_at
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

  describe "player_exists?/2" do
    test "returns true if a player with the given id exists in the game" do
      game = %Game{players: [@player1, @player2, @player3]}
      assert true == Game.player_exists?(game, @player2.id)
    end

    test "returns false if a player with the given id does not exist in the game" do
      game = %Game{players: [@player1, @player2]}
      assert false == Game.player_exists?(game, @player3.id)
    end
  end

  describe "players_by_score/1" do
    setup do
      players = [@player1, @player2, @player3]
      %{game: %Game{players: players, remaining_players: MapSet.new(players)}}
    end

    test "returns the list of players sorted by score", fixture do
      scoring = %{
        @player1.id => {5, 150},
        @player2.id => {7, 140},
        @player3.id => {4, 290}
      }

      game = %{fixture.game | scoring: scoring}
      assert [@player2, @player1, @player3] == Game.players_by_score(game)
    end

    test "sorts remaining players above players who left the game", fixture do
      scoring = %{
        @player1.id => {6, 150},
        @player2.id => {6, 150},
        @player3.id => {5, 200}
      }

      params = %{
        remaining_players: MapSet.new([@player1.id, @player3.id]),
        scoring: scoring
      }

      game = Map.merge(fixture.game, params)
      assert [@player1, @player3, @player2] == Game.players_by_score(game)
    end

    test "sorts higher levels above lower levels", fixture do
      scoring = %{
        @player1.id => {5, 150},
        @player2.id => {6, 150},
        @player3.id => {7, 150}
      }

      game = %{fixture.game | scoring: scoring}
      assert [@player3, @player2, @player1] == Game.players_by_score(game)
    end

    test "sorts lower scores above higher scores", fixture do
      scoring = %{
        @player1.id => {5, 180},
        @player2.id => {5, 160},
        @player3.id => {5, 140}
      }

      game = %{fixture.game | scoring: scoring}
      assert [@player3, @player2, @player1] == Game.players_by_score(game)
    end
  end

  describe "put_player/2" do
    test "adds a player to the game lobby" do
      game = %Game{current_stage: :lobby, players: []}
      assert {:ok, game} = Game.put_player(game, @player1)
      assert game.players == [@player1]
      assert %NaiveDateTime{} = game.updated_at
    end

    test "returns an error if the game has already started" do
      game = %Game{current_stage: :play, players: []}
      assert :already_started == Game.put_player(game, @player1)
    end
  end

  describe "put_player_device_token/3" do
    test "stores a player's device token" do
      game = %Game{device_tokens: %{}}
      token = "5ea2db99-6d0a-4b75-b7bb-c708a2717d93"
      game = Game.put_player_device_token(game, @player1.id, token)
      assert game.device_tokens[@player1.id] == token
      assert %NaiveDateTime{} = game.updated_at
    end

    test "deletes a player's device token when set to nil" do
      game = %Game{device_tokens: %{@player1.id => "9b2598ec-e52b-4779-9a56-23f23cc123f4"}}
      game = Game.put_player_device_token(game, @player1.id, nil)
      assert game.device_tokens == %{}
    end
  end

  describe "remaining_player_count/1" do
    test "returns the number of players remaining in the game" do
      game = %Game{remaining_players: MapSet.new([@player1.id, @player2.id, @player3.id])}
      assert Game.remaining_player_count(game) == 3
    end

    test "returns the number of players in the lobby when the game hasn't started" do
      game = %Game{players: [@player1.id], remaining_players: nil}
      assert Game.remaining_player_count(game) == 1
    end
  end

  describe "remove_player/2" do
    test "removes the player from the list of remaining players" do
      players = MapSet.new([@player1.id, @player2.id, @player3.id])
      game = %Game{current_stage: :play, players_ready: players, remaining_players: players}
      game = Game.remove_player(game, @player1.id)
      refute @player1 in game.players_ready
      refute @player1.id in game.remaining_players
      assert game.current_stage == :play
      assert %NaiveDateTime{} = game.updated_at
    end

    test "marks the game as finished if only 1 player remains" do
      players = MapSet.new([@player1.id, @player2.id])
      game = %Game{current_stage: :play, players_ready: players, remaining_players: players}
      game = Game.remove_player(game, @player1.id)
      assert game.current_stage == :finish
    end
  end

  describe "round_finished?/1" do
    test "returns true if the specified player's hand is empty" do
      game = %Game{hands: %{@player1.id => []}}
      assert true == Game.round_finished?(game, @player1.id)
    end

    test "returns false if the specified player still has cards in their hand" do
      game = %Game{hands: %{@player1.id => [%Card{color: :red, value: :three}]}}
      assert false == Game.round_finished?(game, @player1.id)
    end
  end

  describe "round_winner/1" do
    test "returns the player whose hand is empty" do
      game = %Game{
        hands: %{@player1.id => [], @player2.id => [%Card{color: :red, value: :three}]},
        players: [@player1, @player2],
        remaining_players: MapSet.new([@player1.id, @player2.id])
      }

      assert @player1 == Game.round_winner(game)
    end

    test "returns last remaining player if no player's hand is empty" do
      game = %Game{
        hands: %{
          @player1.id => [%Card{color: :green, value: :two}],
          @player2.id => [%Card{color: :red, value: :three}]
        },
        players: [@player1, @player2],
        remaining_players: MapSet.new([@player2.id])
      }

      assert @player2 == Game.round_winner(game)
    end

    test "returns nil if no hand is empty and multiple players remain" do
      game = %Game{
        hands: %{
          @player1.id => [%Card{color: :green, value: :two}],
          @player2.id => [%Card{color: :red, value: :three}]
        },
        players: [@player1, @player2],
        remaining_players: MapSet.new([@player1.id, @player2.id])
      }

      assert nil == Game.round_winner(game)
    end
  end

  describe "set_player_table/3" do
    test "sets the player's table and removes the cards from their hand" do
      card = %Card{color: :black, value: :wild}
      set = for _ <- 1..3, do: card
      hands = %{@player1.id => for(_ <- 1..10, do: card)}
      scores = %{@player1.id => {1, 0}}
      game = %{@game | current_turn_drawn?: true, hands: hands, scoring: scores, table: %{}}
      game = Game.set_player_table(game, @player1.id, %{0 => set, 1 => set})
      assert length(game.table[@player1.id][0]) == 3
      assert length(game.table[@player1.id][1]) == 3
      assert length(game.hands[@player1.id]) == 4
      assert %NaiveDateTime{} = game.updated_at
    end

    test "returns an error if the player hasn't drawn yet" do
      game = %{@game | current_player: @player1, current_turn_drawn?: false}
      assert :needs_to_draw == Game.set_player_table(game, @player1.id, [@card])
    end

    test "returns an error if it's not the player's turn" do
      game = %{@game | current_player: @player2}
      assert :not_your_turn == Game.set_player_table(game, @player1.id, [@card])
    end

    test "returns an error if the player's table has already been set" do
      game = %{@game | current_turn_drawn?: true, table: %{@player1.id => %{0 => [], 1 => []}}}
      assert :already_set == Game.set_player_table(game, @player1.id, %{})
    end

    test "returns an error if the table provided isn't valid for the current level" do
      game = %{@game | current_turn_drawn?: true, scoring: %{@player1.id => {1, 0}}, table: %{}}
      assert :invalid_level == Game.set_player_table(game, @player1.id, %{0 => [], 1 => []})
    end
  end

  describe "skip_player/2" do
    test "adds the given player ID into the set of skipped players" do
      game = %Game{skipped_players: MapSet.new()}
      result = Game.skip_player(game, "4ebc0075-c609-49e3-9dcf-d5befff8fe72")
      assert MapSet.member?(result.skipped_players, "4ebc0075-c609-49e3-9dcf-d5befff8fe72")
      assert %NaiveDateTime{} = result.updated_at
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
      assert %NaiveDateTime{} = game.updated_at
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

  describe "start_round/1" do
    test "resets everything and increments the round number" do
      game = %Game{
        current_round: 4,
        current_stage: :score,
        levels: %{@player1.id => 2, @player2.id => 2, @player3.id => 3},
        players: [@player1, @player2, @player3],
        remaining_players: MapSet.new([@player1.id, @player2.id, @player3.id]),
        scoring: %{@player1.id => {3, 0}, @player2.id => {2, 0}, @player3.id => {4, 0}},
        skipped_players: MapSet.new([@player1.id]),
        table: %{"old" => ["table", "data"]}
      }

      assert {:ok, game} = Game.start_round(game)
      assert game.current_round == 5
      assert game.table == %{}
      assert Enum.empty?(game.skipped_players)
      assert length(game.draw_pile) == 77
      assert length(game.discard_pile) == 1
      assert length(game.hands[@player1.id]) == 10
      assert length(game.hands[@player2.id]) == 10
      assert length(game.hands[@player2.id]) == 10
      assert game.levels[@player1.id] == 3
      assert game.levels[@player2.id] == 2
      assert game.levels[@player3.id] == 4
      assert game.current_stage == :play
      assert %NaiveDateTime{} = game.updated_at
    end

    test "starts round 1 if the game is in the lobby" do
      game = %Game{
        current_stage: :lobby,
        players: [@player1, @player2, @player3],
        remaining_players: MapSet.new([@player1.id, @player2.id, @player3.id]),
        scoring: %{@player1.id => {1, 0}, @player2.id => {1, 0}, @player3.id => {1, 0}}
      }

      assert {:ok, game} = Game.start_round(game)
      assert game.current_round == 1
      assert game.current_stage == :play
    end

    test "returns :game_over if the game is finished" do
      game = %Game{current_stage: :finish}
      assert :game_over == Game.start_round(game)
    end
  end

  describe "top_discarded_card/1" do
    test "returns the top card in the discard pile" do
      game = %Game{
        discard_pile: [%Card{color: :green, value: :six}, %Card{color: :black, value: :wild}]
      }

      assert %Card{color: :green, value: :six} == Game.top_discarded_card(game)
    end

    test "returns nil when the discard pile is empty" do
      game = %Game{discard_pile: []}
      assert nil == Game.top_discarded_card(game)
    end
  end
end
