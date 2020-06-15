defmodule Level10.Games.GameServer do
  @moduledoc """
  A server for holding game state
  """

  use GenServer
  alias Level10.StateHandoff
  alias Level10.Games.{Game, Player}
  require Logger

  @typedoc "The agent reference"
  @type agent :: pid | {atom, node} | name

  @typedoc "The agent name"
  @type name :: atom | {:global, term} | {:via, module, term}

  @typedoc "Return values of `start*` functions"
  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  @typedoc "The agent state"
  @type state :: term

  # Client Functions

  @spec start_link({Game.join_code(), Player.t()}, GenServer.options()) :: on_start
  def start_link({join_code, player}, options \\ []) do
    GenServer.start_link(__MODULE__, {join_code, player}, options)
  end

  @spec get(agent, (state -> a), timeout) :: a when a: var
  def get(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:get, fun}, timeout)
  end

  @spec get(agent, module, atom, [term], timeout) :: any
  def get(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:get, {module, fun, args}}, timeout)
  end

  @spec get_and_update(agent, (state -> {a, state}), timeout) :: a when a: var
  def get_and_update(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:get_and_update, fun}, timeout)
  end

  @spec get_and_update(agent, module, atom, [term], timeout) :: any
  def get_and_update(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:get_and_update, {module, fun, args}}, timeout)
  end

  @spec update(agent, (state -> state), timeout) :: :ok
  def update(agent, fun, timeout \\ 5000) when is_function(fun, 1) do
    GenServer.call(agent, {:update, fun}, timeout)
  end

  @spec update(agent, module, atom, [term], timeout) :: :ok
  def update(agent, module, fun, args, timeout \\ 5000) do
    GenServer.call(agent, {:update, {module, fun, args}}, timeout)
  end

  @spec stop(agent, reason :: term, timeout) :: :ok
  def stop(agent, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(agent, reason, timeout)
  end

  # Server Functions (Internal Use Only)

  def init({join_code, player}) do
    Process.flag(:trap_exit, true)
    Process.put(:"$initial_call", {Game, :new, 2})

    game =
      case StateHandoff.pickup(join_code) do
        nil -> Game.new(join_code, player)
        game -> game
      end

    {:ok, game}
  end

  def handle_call({:get, fun}, _from, state) do
    {:reply, run(fun, [state]), state}
  end

  def handle_call({:get_and_update, fun}, _from, state) do
    case run(fun, [state]) do
      {reply, state} -> {:reply, reply, state}
      other -> {:stop, {:bad_return_value, other}, state}
    end
  end

  def handle_call({:update, fun}, _from, state) do
    {:reply, :ok, run(fun, [state])}
  end

  def handle_cast({:cast, fun}, state) do
    {:noreply, run(fun, [state])}
  end

  def code_change(_old, state, fun) do
    {:ok, run(fun, [state])}
  end

  defp run({m, f, a}, extra), do: apply(m, f, extra ++ a)
  defp run(fun, extra), do: apply(fun, extra)

  # Called when a SIGTERM is received to begin the handoff process for moving
  # game state to other nodes
  def terminate(:shutdown, %{join_code: join_code} = game) do
    StateHandoff.handoff(join_code, game)
    :ok
  end

  def terminate(_, _), do: :ok
end
