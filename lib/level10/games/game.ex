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
          current_round: non_neg_integer() | :pending | :completed,
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

  defstruct ~W[current_round join_code players]a

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
      current_round: :pending,
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

  @spec put_player(t(), Player.t()) :: {:ok, t()} | :already_started
  def put_player(game, player)

  def put_player(game = %{current_round: :pending, players: players}, player) do
    {:ok, %{game | players: players ++ [player]}}
  end

  def put_player(_game, _player) do
    :already_started
  end

  @spec start_round(t()) :: t()
  def start_round(game) do
    case increment_current_round(game) do
      {:ok, game} ->
        game
        |> put_new_deck()
        |> deal_hands()

      :game_over ->
        :game_over
    end
  end

  @spec increment_current_round(t()) :: t()
  defp increment_current_round(game)

  defp increment_current_round(%{current_round: :completed}) do
    :game_over
  end

  defp increment_current_round(game = %{current_round: :pending}) do
    %{game | current_round: 1}
  end

  defp increment_current_round(game = %{current_round: current_round}) do
    %{game | current_round: current_round + 1}
  end

  @spec put_new_deck(t()) :: t()
  defp put_new_deck(game) do
    %{game | draw_pile: new_deck()}
  end

  @spec new_deck() :: [Card.t()]
  defp new_deck do
    color_cards =
      for value <- ~W[one two three four five six seven eight nine ten eleven twelve wild]a,
          color <- ~W[blue green red yellow]a,
          card = Card.new(value, color),
          _repeat <- 1..2 do
        card
      end

    skips = for _repeat <- 1..4, do: Card.new(:skip, :blue)

    color_cards
    |> Stream.concat(skips)
    |> Enum.shuffle()
  end

  @spec deal_hands(t()) :: t()
  defp deal_hands(game = %{draw_pile: deck, players: players}) do
    {hands, deck} =
      Enum.reduce(players, {%{}, deck}, fn %{id: player_id}, {hands, deck} ->
        {hand, deck} = Enum.split(deck, 10)
        hands = Map.put(hands, player_id, hand)
        {hands, deck}
      end)

    %{game | draw_pile: deck, hands: hands}
  end
end
