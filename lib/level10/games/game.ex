defmodule Level10.Games.Game do
  @moduledoc """
  The game struct is used to represent the state for an entire game. It is a
  token that will be passed to different functions in order to modify the
  game's state, and then stored on the server to be updated or to serve data
  down to clients.
  """
  # alias Level10.Games.{Card, GameRegistry, Player}
  alias Level10.Games.Player

  @type join_code :: <<_::32>>
  @type t :: %__MODULE__{
          join_code: join_code(),
          players: [Player.t()]
        }

  #   @type t :: %__MODULE__{
  #           complete: boolean(),
  #           current_round: integer(),
  #           discard_pile: list(Card.t()),
  #           draw_pile: list(Card.t()),
  #           hands: map(),
  #           players: map(),
  #           scoring: map(),
  #           table: map()
  #         }

  defstruct [:join_code, :players]

  @spec generate_join_code() :: join_code()
  def generate_join_code do
    <<:random.uniform(1_048_576)::40>>
    |> Base.encode32()
    |> binary_part(4, 4)
  end

  #   defstruct [
  #     :complete,
  #     :current_round,
  #     :discard_pile,
  #     :draw_pile,
  #     :hands,
  #     :players,
  #     :scoring,
  #     :table
  #   ]

  @spec new(join_code(), Player.t()) :: t()
  def new(join_code, player) do
    %__MODULE__{
      join_code: join_code,
      players: [player]
    }
  end

  #   @doc """
  #   Takes a list of players and returns a new game struct with all values set to
  #   defaults.
  #   """
  #   @spec new(list(Player.t())) :: t()
  #   def new(players) do
  #     %__MODULE__{
  #       complete: false,
  #       current_round: 0,
  #       discard_pile: [],
  #       draw_pile: [],
  #       hands: %{},
  #       players: players,
  #       scoring: %{},
  #       table: %{}
  #     }
  #   end
end
