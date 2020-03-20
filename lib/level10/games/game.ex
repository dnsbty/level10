defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """

  alias Level10.Games.{Card, GameRegistry, Player}

  @type t :: %__MODULE__{
          complete: boolean(),
          current_round: integer(),
          discard_pile: list(Card.t()),
          draw_pile: list(Card.t()),
          hands: map(),
          players: map(),
          scoring: map(),
          table: map()
        }

  defstruct [
    :complete,
    :current_round,
    :discard_pile,
    :draw_pile,
    :hands,
    :players,
    :scoring,
    :table
  ]

  def new_agent(players) do
    code = generate_code()

    case Agent.start_link(__MODULE__, :new, [players], name: game_name(code)) do
      {:ok, _pid} ->
        {:ok, code}

      {:error, {:already_started, _pid}} ->
        new_agent(players)
    end
  end

  defp generate_code do
    <<:random.uniform(1_048_576)::40>>
    |> Base.encode32()
    |> binary_part(4, 4)
  end

  defp game_name(code) do
    {:via, Registry, {GameRegistry, code}}
  end

  @doc """
  Takes a list of players and returns a new game struct with all values set to
  defaults.
  """
  @spec new(list(Player.t())) :: t()
  def new(players) do
    %__MODULE__{
      complete: false,
      current_round: 0,
      discard_pile: [],
      draw_pile: [],
      hands: %{},
      players: players,
      scoring: %{},
      table: %{}
    }
  end
end
