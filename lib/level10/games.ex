defmodule Level10.Games do
  @moduledoc """
  This context module handles all of the work around running games. Most of the
  functions will take in a game struct and manipulate that struct and return
  it.
  """
  alias Level10.Games.{Game, GameRegistry, GameSupervisor, Player}

  @typep event_type :: atom()
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

    game = %{
      id: join_code,
      start: {Agent, :start_link, [Game, :new, [join_code, player], [name: via(join_code)]]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(GameSupervisor, game) do
      {:ok, _pid} ->
        {:ok, join_code, player.id}

      {:error, {:already_started, _pid}} ->
        do_create_game(player, attempts_remaining - 1)
    end
  end

  @spec exists?(Game.join_code()) :: boolean()
  def exists?(join_code) do
    case Registry.lookup(GameRegistry, join_code) do
      [] -> false
      _ -> true
    end
  end

  @spec via(Game.join_code()) :: game_name()
  defp via(join_code) do
    {:via, Registry, {GameRegistry, join_code}}
  end

  @doc """
  Get the hand of the specified player.

  ## Examples

      iex> get_hand_for_player("ABCD", "557489d0-1ef2-4763-9b0b-d2ea3c80fd99")
      [%Card{color: :green, value: :twelve}, %Card{color: :blue, value: :nine}, ...]
  """
  @spec get_hand_for_player(Game.join_code(), Player.id()) :: list(Card.t())
  def get_hand_for_player(join_code, player_id) do
    Agent.get(via(join_code), & &1.hands[player_id])
  end

  @spec get_players(Game.join_code()) :: list(Player.t())
  def get_players(join_code) do
    Agent.get(via(join_code), & &1.players)
  end

  @spec join_game(Game.join_code(), String.t()) ::
          {:ok, Player.id()} | :already_started | :not_found
  def join_game(join_code, player_name) do
    player = Player.new(player_name)

    if exists?(join_code) do
      Agent.get_and_update(via(join_code), fn game ->
        case Game.put_player(game, player) do
          {:ok, game} ->
            broadcast(game.join_code, :players_updated, game.players)
            {{:ok, player.id}, game}

          :already_started ->
            {:already_started, game}
        end
      end)
    else
      :not_found
    end
  end

  @spec leave_game(Game.join_code(), Player.id()) :: :ok | :already_started
  def leave_game(join_code, player_id) do
    Agent.get_and_update(via(join_code), fn game ->
      case Game.delete_player(game, player_id) do
        {:ok, game} ->
          broadcast(game.join_code, :players_updated, game.players)
          {:ok, game}

        :already_started ->
          {:already_started, game}
      end
    end)
  end

  @spec player_exists?(Game.join_code(), Player.id()) :: boolean()
  def player_exists?(join_code, player_id) do
    Agent.get(via(join_code), fn game ->
      Enum.any?(game.players, fn player -> player.id == player_id end)
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

  @spec start_game(Game.join_code()) :: :ok | :single_player
  def start_game(join_code) do
    Agent.get_and_update(via(join_code), fn game ->
      case Game.start_game(game) do
        {:ok, game} ->
          broadcast(game.join_code, :game_started, nil)
          {:ok, game}

        :single_player ->
          {:single_player, game}
      end
    end)
  end

  @doc """
  Check whether or not a game has started.

  ## Examples

      iex> started?("ABCD")
      true

      iex> started?("EFGH")
      false
  """
  @spec started?(Game.join_code()) :: boolean()
  def started?(join_code) do
    Agent.get(via(join_code), fn game ->
      game.current_stage != :lobby
    end)
  end

  @spec subscribe(String.t()) :: :ok | {:error, term()}
  def subscribe(game_code) do
    Phoenix.PubSub.subscribe(Level10.PubSub, "game:" <> game_code)
  end

  @spec unsubscribe(String.t()) :: :ok | {:error, term()}
  def unsubscribe(game_code) do
    Phoenix.PubSub.unsubscribe(Level10.PubSub, "game:" <> game_code)
  end

  @spec broadcast(Game.join_code(), event_type(), term()) :: :ok | {:error, term()}
  defp broadcast(join_code, event_type, event) do
    Phoenix.PubSub.broadcast(Level10.PubSub, "game:" <> join_code, {event_type, event})
  end
end
