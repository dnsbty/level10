alias Level10.Games
alias Games.{Card, Game, GameRegistry, GameSupervisor, Levels, Player}

join_code = "ABCD"

defmodule Seeds do
  def chrome, do: __MODULE__.open(["-a", "Google Chrome"])

  def game do
    %Game{
      current_player: %Player{
        id: "98ba6988-15ab-4e83-82b1-00330fbcfec8",
        name: "Dennis"
      },
      current_round: 1,
      current_stage: :scoring,
      current_turn: 38,
      current_turn_drawn?: false,
      discard_pile: [
        %Card{color: :blue, value: :ten},
        %Card{color: :black, value: :skip},
        %Card{color: :green, value: :three},
        %Card{color: :blue, value: :three},
        %Card{color: :red, value: :one},
        %Card{color: :red, value: :seven},
        %Card{color: :blue, value: :three},
        %Card{color: :green, value: :seven},
        %Card{color: :yellow, value: :two},
        %Card{color: :green, value: :two},
        %Card{color: :green, value: :ten},
        %Card{color: :green, value: :three},
        %Card{color: :red, value: :three},
        %Card{color: :yellow, value: :eight},
        %Card{color: :green, value: :one},
        %Card{color: :blue, value: :five},
        %Card{color: :yellow, value: :eight},
        %Card{color: :yellow, value: :ten},
        %Card{color: :red, value: :one},
        %Card{color: :red, value: :ten},
        %Card{color: :yellow, value: :one},
        %Card{color: :yellow, value: :seven},
        %Card{color: :green, value: :seven},
        %Card{color: :yellow, value: :three},
        %Card{color: :red, value: :eight},
        %Card{color: :red, value: :eight},
        %Card{color: :green, value: :nine},
        %Card{color: :red, value: :four},
        %Card{color: :blue, value: :ten},
        %Card{color: :green, value: :eight},
        %Card{color: :blue, value: :five},
        %Card{color: :red, value: :five},
        %Card{color: :yellow, value: :six},
        %Card{color: :red, value: :nine}
      ],
      draw_pile: [
        %Card{color: :red, value: :seven},
        %Card{color: :yellow, value: :two},
        %Card{color: :green, value: :six},
        %Card{color: :yellow, value: :seven},
        %Card{color: :red, value: :two},
        %Card{color: :black, value: :wild},
        %Card{color: :green, value: :twelve},
        %Card{color: :yellow, value: :one},
        %Card{color: :blue, value: :two},
        %Card{color: :red, value: :nine},
        %Card{color: :red, value: :five},
        %Card{color: :yellow, value: :nine},
        %Card{color: :black, value: :skip},
        %Card{color: :blue, value: :twelve},
        %Card{color: :green, value: :four},
        %Card{color: :red, value: :two},
        %Card{color: :green, value: :one},
        %Card{color: :yellow, value: :five},
        %Card{color: :yellow, value: :nine},
        %Card{color: :green, value: :five},
        %Card{color: :blue, value: :four},
        %Card{color: :red, value: :six},
        %Card{color: :black, value: :skip},
        %Card{color: :green, value: :twelve},
        %Card{color: :black, value: :skip},
        %Card{color: :blue, value: :seven},
        %Card{color: :blue, value: :twelve},
        %Card{color: :blue, value: :seven},
        %Card{color: :red, value: :eleven},
        %Card{color: :yellow, value: :twelve},
        %Card{color: :black, value: :wild},
        %Card{color: :green, value: :five},
        %Card{color: :blue, value: :six},
        %Card{color: :blue, value: :eleven},
        %Card{color: :green, value: :nine},
        %Card{color: :blue, value: :one},
        %Card{color: :red, value: :ten}
      ],
      hands: %{
        "7ffd576b-28cd-4e4e-822c-fed41619483b" => [
          %Card{color: :yellow, value: :eleven},
          %Card{color: :blue, value: :eleven},
          %Card{color: :green, value: :eleven},
          %Card{color: :black, value: :wild},
          %Card{color: :black, value: :wild},
          %Card{color: :black, value: :wild},
          %Card{color: :green, value: :two},
          %Card{color: :blue, value: :three},
          %Card{color: :blue, value: :two},
          %Card{color: :red, value: :three}
        ],
        "98ba6988-15ab-4e83-82b1-00330fbcfec8" => [
          %Card{color: :black, value: :wild}
        ]
      },
      join_code: "ABCD",
      players: [
        %Player{
          id: "7ffd576b-28cd-4e4e-822c-fed41619483b",
          name: "Brett"
        },
        %Player{
          id: "98ba6988-15ab-4e83-82b1-00330fbcfec8",
          name: "Dennis"
        }
      ],
      players_ready: MapSet.new(),
      scoring: %{
        "7ffd576b-28cd-4e4e-822c-fed41619483b" => {10, 220},
        "98ba6988-15ab-4e83-82b1-00330fbcfec8" => {10, 200}
      },
      table: %{
        "98ba6988-15ab-4e83-82b1-00330fbcfec8" => %{
          0 => [
            %Card{color: :red, value: :four},
            %Card{color: :yellow, value: :four},
            %Card{color: :blue, value: :four},
            %Card{color: :yellow, value: :four},
            %Card{color: :black, value: :wild}
          ],
          1 => [
            %Card{color: :black, value: :wild},
            %Card{color: :green, value: :six},
            %Card{color: :yellow, value: :six},
            %Card{color: :red, value: :six}
          ]
        }
      }
    }
  end

  def open(app_args \\ []) do
    dennis_id = "98ba6988-15ab-4e83-82b1-00330fbcfec8"
    brett_id = "7ffd576b-28cd-4e4e-822c-fed41619483b"
    url = "http://localhost:4000/game/ABCD?player_id="

    System.cmd("open", app_args ++ [url <> dennis_id])
    System.cmd("open", app_args ++ [url <> brett_id])
  end

  def reset do
    Agent.update({:via, Registry, {GameRegistry, "ABCD"}}, fn _ -> game() end)
  end

  def safari, do: __MODULE__.open(["-a", "Safari"])

  def set(join_code \\ "ABCD", game) do
    Agent.update({:via, Registry, {GameRegistry, join_code}}, fn _ -> game end)
  end
end

Node.connect(:"node2@127.0.0.1")

# game = %{
#   id: join_code,
#   start:
#     {Agent, :start_link,
#      [Seeds, :game, [], [name: {:via, Horde.Registry, {GameRegistry, join_code}}]]},
#   restart: :temporary
# }

# Horde.DynamicSupervisor.start_child(GameSupervisor, game)
