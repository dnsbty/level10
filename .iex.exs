alias Level10.{Games, StateHandoff}
alias Games.{Card, Game, GameRegistry, GameServer, GameSupervisor, Levels, Player}

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
        id: "0dbc7f1b-2ece-4c48-ae8e-72966dda0114",
        name: "Right"
      },
      current_round: 1,
      current_stage: :score,
      current_turn: 26,
      current_turn_drawn?: false,
      discard_pile: [],
      draw_pile: [],
      hands: %{
        "0dbc7f1b-2ece-4c48-ae8e-72966dda0114" => [
          %Level10.Games.Card{color: :yellow, value: :one},
          %Level10.Games.Card{color: :yellow, value: :six},
          %Level10.Games.Card{color: :green, value: :one},
          %Level10.Games.Card{color: :red, value: :two}
        ],
        "2fa9afae-9613-48dd-a100-af426ecc70ce" => [
          %Level10.Games.Card{color: :red, value: :two},
          %Level10.Games.Card{color: :red, value: :one}
        ],
        "6e6885fc-a2b1-4402-8b15-63575d399bee" => []
      },
      join_code: "ABCD",
      levels: %{
        "0dbc7f1b-2ece-4c48-ae8e-72966dda0114" => 1,
        "2fa9afae-9613-48dd-a100-af426ecc70ce" => 1,
        "6e6885fc-a2b1-4402-8b15-63575d399bee" => 1
      },
      players: [
        %Level10.Games.Player{
          id: "0dbc7f1b-2ece-4c48-ae8e-72966dda0114",
          name: "Right"
        },
        %Level10.Games.Player{
          id: "2fa9afae-9613-48dd-a100-af426ecc70ce",
          name: "Middle"
        },
        %Level10.Games.Player{
          id: "6e6885fc-a2b1-4402-8b15-63575d399bee",
          name: "Left"
        }
      ],
      players_ready: MapSet.new(),
      remaining_players:
        MapSet.new([
          "0dbc7f1b-2ece-4c48-ae8e-72966dda0114",
          "2fa9afae-9613-48dd-a100-af426ecc70ce",
          "6e6885fc-a2b1-4402-8b15-63575d399bee"
        ]),
      scoring: %{
        "0dbc7f1b-2ece-4c48-ae8e-72966dda0114" => {2, 20},
        "2fa9afae-9613-48dd-a100-af426ecc70ce" => {2, 10},
        "6e6885fc-a2b1-4402-8b15-63575d399bee" => {2, 0}
      },
      settings: %Level10.Games.Settings{
        skip_next_player: false
      },
      table: %{
        "0dbc7f1b-2ece-4c48-ae8e-72966dda0114" => %{
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
        "2fa9afae-9613-48dd-a100-af426ecc70ce" => %{
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
        },
        "6e6885fc-a2b1-4402-8b15-63575d399bee" => %{
          0 => [
            %Level10.Games.Card{color: :yellow, value: :ten},
            %Level10.Games.Card{color: :green, value: :ten},
            %Level10.Games.Card{color: :green, value: :ten},
            %Level10.Games.Card{color: :blue, value: :ten},
            %Level10.Games.Card{color: :black, value: :ten}
          ],
          1 => [
            %Level10.Games.Card{color: :black, value: :twelve},
            %Level10.Games.Card{color: :black, value: :twelve},
            %Level10.Games.Card{color: :green, value: :twelve},
            %Level10.Games.Card{color: :blue, value: :twelve},
            %Level10.Games.Card{color: :black, value: :twelve}
          ]
        }
      }
    }
  end

  def open(app_args \\ []) do
    port = System.get_env("PORT", "4000")
    url = "http://localhost:#{port}/game/ABCD?player_id="

    System.cmd("open", app_args ++ [url <> "0dbc7f1b-2ece-4c48-ae8e-72966dda0114"])
    System.cmd("open", app_args ++ [url <> "2fa9afae-9613-48dd-a100-af426ecc70ce"])
    System.cmd("open", app_args ++ [url <> "6e6885fc-a2b1-4402-8b15-63575d399bee"])
  end

  def reset do
    Games.update("ABCD", fn _ -> game() end)
  end

  def safari, do: __MODULE__.open(["-a", "Safari"])

  def set(join_code \\ "ABCD", game) do
    Agent.update(join_code, fn _ -> game end)
  end
end

game = %{
  id: join_code,
  start:
    {GameServer, :start_link,
     [{join_code, player}, [name: {:via, Horde.Registry, {GameRegistry, join_code}}]]},
  shutdown: 1000,
  restart: :temporary
}

Horde.DynamicSupervisor.start_child(GameSupervisor, game)
Seeds.reset()
