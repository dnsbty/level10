defmodule Level10.Games do
  @moduledoc """
  This context module handles all of the work around running games. Most of the
  functions will take in a game struct and manipulate that struct and return
  it.
  """
  # alias Level10.Games.{Card, Game}
  alias Level10.Games.{Game, GameRegistry, Player}

  @typep game_name :: Agent.name()

  @max_attempts 10

  @spec create_game(String.t()) :: {:ok, Game.join_code(), Player.id()} | :error
  def create_game(player_name) do
    player = Player.new(player_name)
    do_create_game(player, @max_attempts)
  end

  @spec do_create_game(Player.t(), non_neg_integer()) ::
          {:ok, Game.join_code(), Player.id()} | :error
  defp do_create_game(player, attempts_remaining)

  defp do_create_game(_player, 0) do
    :error
  end

  defp do_create_game(player, attempts_remaining) do
    join_code = Game.generate_join_code()

    case Agent.start_link(Game, :new, [join_code, player], name: via(join_code)) do
      {:ok, _pid} ->
        {:ok, join_code, player.id}

      {:error, {:already_started, _pid}} ->
        do_create_game(player, attempts_remaining - 1)
    end
  end

  @spec via(Game.join_code()) :: game_name()
  defp via(join_code) do
    {:via, Registry, {GameRegistry, join_code}}
  end

  # def new_agent(players) do
  #   code = generate_code()

  #   case Agent.start_link(__MODULE__, :new, [players], name: game_name(code)) do
  #     {:ok, _pid} ->
  #       {:ok, code}

  #     {:error, {:already_started, _pid}} ->
  #       new_agent(players)
  #   end
  # end

  # defp generate_code do
  #   <<:random.uniform(1_048_576)::40>>
  #   |> Base.encode32()
  #   |> binary_part(4, 4)
  # end

  # defp game_name(code) do
  #   {:via, Registry, {GameRegistry, code}}
  # end

  # @doc """
  # This function will make all of the necessary changes to start a round. It
  # will increment the current_round, shuffle a new deck of cards as the draw
  # pile, and deal out a new hand to each player.
  # """
  # @spec start_round(Game.t()) :: Game.t()
  # def start_round(game) do
  #   game
  #   |> increment_current_round()
  #   |> put_new_deck()
  #   |> put_new_hands()
  # end

  # @spec increment_current_round(Game.t()) :: Game.t()
  # defp increment_current_round(%{current_round: current_round} = game) do
  #   %{game | current_round: current_round + 1}
  # end

  # @spec put_new_deck(Game.t()) :: Game.t()
  # defp put_new_deck(game) do
  #   %{game | draw_pile: new_deck()}
  # end

  # @spec put_new_hands(Game.t()) :: Game.t()
  # defp put_new_hands(%{draw_pile: deck, players: players} = game) do
  #   {hands, draw_pile} =
  #     Enum.reduce(players, {%{}, deck}, fn %{name: player_name}, {hands, draw_pile} ->
  #       {player_hand, rest_of_pile} = Enum.split(draw_pile, 10)
  #       hands = Map.put(hands, player_name, player_hand)
  #       {hands, rest_of_pile}
  #     end)

  #   %{game | draw_pile: draw_pile, hands: hands}
  # end

  # @spec new_deck() :: Card.t()
  # defp new_deck do
  #   color_cards =
  #     for value <- ~W[one two three four five six seven eight nine ten eleven twelve wild]a,
  #         color <- ~W[blue green red yellow]a,
  #         card = Card.new(value, color),
  #         _repeat <- 1..2 do
  #       card
  #     end

  #   skips = for _repeat <- 1..4, do: Card.new(:skip, :blue)

  #   color_cards
  #   |> Stream.concat(skips)
  #   |> Enum.shuffle()
  # end

  # @doc """
  # At the end of a round, the game struct should be passed into this function.
  # It will update player scoring and levels, check if the game has been
  # complete, and reset the state for the next round.
  # """
  # @spec complete_round(Game.t()) :: Game.t()
  # def complete_round(game) do
  #   game
  #   |> update_scoring_and_levels()
  #   |> check_complete()
  #   |> clear_round()
  # end

  # @spec update_scoring_and_levels(Game.t()) :: Game.t()
  # defp update_scoring_and_levels(%{scoring: scoring, table: table, hands: hands} = game) do
  #   new_scoring =
  #     scoring
  #     |> Enum.map(fn {player, {level, score}} ->
  #       player_hand = hands[player]
  #       score_for_hand = player_hand |> Enum.map(&Card.score/1) |> Enum.sum()
  #       new_score = score + score_for_hand

  #       player_advanced = !is_nil(table[player])
  #       new_level = if player_advanced, do: level + 1, else: level

  #       {player, {new_level, new_score}}
  #     end)
  #     |> Enum.into(%{})

  #   %{game | scoring: new_scoring}
  # end

  # @spec check_complete(Game.t()) :: Game.t()
  # defp check_complete(%{scoring: scoring} = game) do
  #   complete = Enum.any?(scoring, fn {_, {level, _}} -> level == 11 end)
  #   %{game | complete: complete}
  # end

  # @spec clear_round(Game.t()) :: Game.t()
  # defp clear_round(game) do
  #   %{game | draw_pile: [], discard_pile: [], table: %{}, hands: %{}}
  # end

  # @doc """
  # Shuffles the discard pile to make a new draw pile. This should happen when
  # the current draw pile is empty.
  # """
  # @spec reshuffle_deck(Game.t()) :: Game.t()
  # def reshuffle_deck(game = %{discard_pile: discard_pile}) do
  #   %{game | discard_pile: [], draw_pile: Enum.shuffle(discard_pile)}
  # end
end
