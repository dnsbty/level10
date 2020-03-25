defmodule Level10.Games do
  @moduledoc """
  This context module handles all of the work around running games. Most of the
  functions will take in a game struct and manipulate that struct and return
  it.
  """
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

  @spec join_game(Game.join_code(), String.t()) :: {:ok, Player.id()} | :already_started
  def join_game(join_code, player_name) do
    player = Player.new(player_name)

    Agent.get_and_update(via(join_code), fn game ->
      case Game.put_player(game, player) do
        {:ok, game} ->
          {{:ok, player.id}, game}

        :already_started ->
          {:already_started, game}
      end
    end)
  end

  @spec start_round(Game.join_code()) :: :ok | :game_over
  def start_round(join_code) do
    Agent.get_and_update(via(join_code), fn game ->
      case Game.start_round(game) do
        {:ok, game} ->
          {:ok, game}

        :game_over ->
          {:game_over, game}
      end
    end)
  end

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
