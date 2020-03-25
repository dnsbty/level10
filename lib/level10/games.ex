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

    case Agent.start(Game, :new, [join_code, player], name: via(join_code)) do
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
end