alias Level10.{Accounts, Games, Repo, StateHandoff}
alias Accounts.{User, UserToken, UserAuth}
alias Games.{Card, Game, GameRegistry, GameServer, GameSupervisor, Levels, Player, Settings}

join_code = "ABCD"

player = %Player{
  id: "98ba6988-15ab-4e83-82b1-00330fbcfec8",
  name: "Dennis"
}

defmodule Seeds do
  def chrome, do: __MODULE__.open(["-a", "Google Chrome"])

  def game do
    %Level10.Games.Game{
      current_player: %Level10.Games.Player{
        id: "9762d8e9-7288-4010-b3be-468554b3319e",
        name: "Right"
      },
      current_round: 9,
      current_stage: :score,
      current_turn: 26,
      current_turn_drawn?: false,
      discard_pile: [],
      draw_pile: [],
      hands: %{
        "9762d8e9-7288-4010-b3be-468554b3319e" => [
          %Level10.Games.Card{color: :yellow, value: :one},
          %Level10.Games.Card{color: :yellow, value: :six},
          %Level10.Games.Card{color: :green, value: :one},
          %Level10.Games.Card{color: :red, value: :two}
        ],
        "1f98ecfe-eccf-42d5-b0fe-7023aba16357" => []
      },
      join_code: "ABCD",
      levels: %{
        "9762d8e9-7288-4010-b3be-468554b3319e" => 1,
        "1f98ecfe-eccf-42d5-b0fe-7023aba16357" => 1
      },
      players: [
        %Level10.Games.Player{
          id: "9762d8e9-7288-4010-b3be-468554b3319e",
          name: "Dennis"
        },
        %Level10.Games.Player{
          id: "1f98ecfe-eccf-42d5-b0fe-7023aba16357",
          name: "Kira"
        }
      ],
      players_ready: MapSet.new(),
      remaining_players:
        MapSet.new([
          "9762d8e9-7288-4010-b3be-468554b3319e",
          "1f98ecfe-eccf-42d5-b0fe-7023aba16357"
        ]),
      scoring: %{
        "9762d8e9-7288-4010-b3be-468554b3319e" => {10, 20},
        "1f98ecfe-eccf-42d5-b0fe-7023aba16357" => {10, 10}
      },
      settings: %Level10.Games.Settings{
        skip_next_player: false
      },
      skipped_players: MapSet.new(),
      table: %{
        "9762d8e9-7288-4010-b3be-468554b3319e" => %{
          0 => [
            %Level10.Games.Card{color: :yellow, value: :twelve},
            %Level10.Games.Card{color: :blue, value: :twelve},
            %Level10.Games.Card{color: :red, value: :twelve}
          ],
          1 => [
            %Level10.Games.Card{color: :yellow, value: :three},
            %Level10.Games.Card{color: :black, value: :three},
            %Level10.Games.Card{color: :blue, value: :three},
            %Level10.Games.Card{color: :green, value: :three},
            %Level10.Games.Card{color: :red, value: :three}
          ]
        },
        "1f98ecfe-eccf-42d5-b0fe-7023aba16357" => %{
          0 => [
            %Level10.Games.Card{color: :blue, value: :seven},
            %Level10.Games.Card{color: :blue, value: :seven},
            %Level10.Games.Card{color: :red, value: :seven}
          ],
          1 => [
            %Level10.Games.Card{color: :yellow, value: :eleven},
            %Level10.Games.Card{color: :red, value: :eleven},
            %Level10.Games.Card{color: :yellow, value: :eleven}
          ]
        }
      }
    }
  end

  def open(app_args \\ []) do
    port = System.get_env("PORT", "4000")
    url = "http://localhost:#{port}/game/ABCD?player_id="

    System.cmd("open", app_args ++ [url <> "9762d8e9-7288-4010-b3be-468554b3319e"])
    System.cmd("open", app_args ++ [url <> "1f98ecfe-eccf-42d5-b0fe-7023aba16357"])
  end

  def reset do
    Games.update("ABCD", fn _ -> game() end)
  end

  def safari, do: __MODULE__.open(["-a", "Safari"])

  def set(join_code \\ "ABCD", game) do
    Agent.update(join_code, fn _ -> game end)
  end

  def stack_deck(join_code \\ "ABCD", card) do
    Games.update(join_code, fn game ->
      deck = game.draw_pile
      %{game | draw_pile: [card | deck]}
    end)
  end

  def wild_hands(join_code \\ "ABCD") do
    hand = List.duplicate(Card.new(:wild, :black), 10)

    Games.update(join_code, fn game ->
      hands = %{
        "9762d8e9-7288-4010-b3be-468554b3319e" => hand,
        "1f98ecfe-eccf-42d5-b0fe-7023aba16357" => hand
      }

      %{game | hands: hands}
    end)
  end
end

settings = %Settings{skip_next_player: false}

game = %{
  id: join_code,
  start:
    {GameServer, :start_link,
     [{join_code, player, settings}, [name: {:via, Horde.Registry, {GameRegistry, join_code}}]]},
  shutdown: 1000,
  restart: :temporary
}

Horde.DynamicSupervisor.start_child(GameSupervisor, game)
Seeds.reset()
