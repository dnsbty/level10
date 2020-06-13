defmodule Level10.Games.GameServer do
  @moduledoc """
  A server for holding game state
  """

  use GenServer

  @typedoc "The agent reference"
  @type agent :: pid | {atom, node} | name

  @typedoc "The agent name"
  @type name :: atom | {:global, term} | {:via, module, term}

  @typedoc "Return values of `start*` functions"
  @type on_start :: {:ok, pid} | {:error, {:already_started, pid} | term}

  @typedoc "The agent state"
  @type state :: term

  # Client Functions

  @spec start_link(module, atom, [any], GenServer.options()) :: on_start
  def start_link(module, fun, args, options \\ []) do
    GenServer.start_link(Agent.Server, {module, fun, args}, options)
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

  def init(fun) do
    _ = initial_call(fun)
    {:ok, run(fun, [])}
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

  defp initial_call(mfa) do
    _ = Process.put(:"$initial_call", get_initial_call(mfa))
    :ok
  end

  defp get_initial_call(fun) when is_function(fun, 0) do
    {:module, module} = Function.info(fun, :module)
    {:name, name} = Function.info(fun, :name)
    {module, name, 0}
  end

  defp get_initial_call({mod, fun, args}) do
    {mod, fun, length(args)}
  end

  defp run({m, f, a}, extra), do: apply(m, f, extra ++ a)
  defp run(fun, extra), do: apply(fun, extra)
end
