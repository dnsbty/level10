defmodule Level10.StateHandoff do
  @moduledoc """
  Whenever a SIGTERM is received, this GenServer is used to store the state of
  the games on the local node across the entire cluster so that it can be
  replicated in new nodes once this one goes down.
  """

  use GenServer
  require Logger

  alias Level10.StateHandoff.Crdt

  @max_active_time 60 * 60

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Client (Public)

  @doc """
  Reset the current state of the CRDT
  """
  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @doc """
  Get the current state of the CRDT. Used mostly for debugging purposes.
  """
  def get do
    GenServer.call(__MODULE__, :get)
  end

  @doc """
  Store a game in the CRDT keyed by its join code
  """
  def handoff(join_code, game) do
    GenServer.call(__MODULE__, {:handoff, join_code, game})
  end

  @doc """
  Pick up the stored game for the given join code from within the CRDT
  """
  def pickup(join_code) do
    GenServer.call(__MODULE__, {:pickup, join_code})
  end

  @doc """
  Notify the CRDT that shutdown is imminent, and that new processes should no
  longer be picked up.
  """
  def prepare_for_shutdown do
    GenServer.cast(__MODULE__, :prepare_for_shutdown)
  end

  @doc """
  For some reason, games sometimes get stuck in the CRDT. This removes them if
  they've been waiting to be picked up for an hour or more.
  """
  def reap do
    GenServer.cast(__MODULE__, :reap)
  end

  @doc """
  Returns the number of games currently stored in the CRDT.
  """
  @spec size :: non_neg_integer
  def size do
    GenServer.call(__MODULE__, :size)
  catch
    :exit, _ -> 0
  end

  # Server (Private)

  @doc false
  def init(_) do
    opts = [name: Crdt, sync_interval: 300]
    DeltaCrdt.start_link(DeltaCrdt.AWLWWMap, opts)

    # Register to receive messages when nodes enter and leave the cluster
    :net_kernel.monitor_nodes(true, node_type: :visible)

    # connect to the CRDTs on the other nodes
    update_neighbors()

    {:ok, :running}
  end

  @doc false
  def handle_call(:get, _from, state) do
    crdt = DeltaCrdt.to_map(Crdt)
    {:reply, crdt, state}
  end

  def handle_call({:handoff, join_code, game}, _from, state) do
    Logger.info(
      "[StateHandoff] Adding game #{join_code} to the CRDT with current stage: #{game.current_stage}"
    )

    case DeltaCrdt.get(Crdt, join_code) do
      nil ->
        DeltaCrdt.put(Crdt, join_code, {game, NaiveDateTime.utc_now()})
        Logger.info("[StateHandoff] Added game #{join_code} to CRDT")
        :telemetry.execute([:level10, :state_handoff, :added], %{}, %{join_code: join_code})

      _game ->
        Logger.info("[StateHandoff] Game #{join_code} already exists in the CRDT")
    end

    {:reply, :ok, state}
  end

  def handle_call({:pickup, join_code}, _from, state) do
    game = DeltaCrdt.get(Crdt, join_code)

    cond do
      is_nil(game) ->
        {:reply, nil, state}

      state == :terminating ->
        Logger.info("[StateHandoff] Temporarily picked up game #{join_code}")
        event = [:level10, :state_handoff, :temporary_pickup]
        :telemetry.execute(event, %{}, %{join_code: join_code})
        {game, _} = game
        {:reply, game, state}

      true ->
        Logger.info("[StateHandoff] Picked up game #{join_code}")
        DeltaCrdt.delete(Crdt, join_code)
        :telemetry.execute([:level10, :state_handoff, :pickup], %{}, %{join_code: join_code})
        {game, _} = game
        {:reply, game, state}
    end
  end

  def handle_call(:size, _from, state) do
    size = Crdt |> DeltaCrdt.to_map() |> map_size()
    {:reply, size, state}
  end

  @doc false
  def handle_cast(:clear, state) do
    for {key, _} <- DeltaCrdt.to_map(Crdt) do
      DeltaCrdt.delete(Crdt, key)
    end

    {:noreply, state}
  end

  def handle_cast(:prepare_for_shutdown, _state) do
    {:noreply, :terminating}
  end

  def handle_cast(:reap, state) do
    oldest_active_time =
      NaiveDateTime.utc_now() |> NaiveDateTime.add(@max_active_time * -1, :second)

    for {join_code, {_, inserted_at}} <- DeltaCrdt.to_map(Crdt),
        :lt == NaiveDateTime.compare(inserted_at, oldest_active_time) do
      DeltaCrdt.delete(Crdt, join_code)
    end

    {:noreply, state}
  end

  # Handle the message received when a new node joins the cluster
  def handle_info({:nodeup, _node, _node_type}, state) do
    update_neighbors()
    {:noreply, state}
  end

  # Handle the message received when a node leaves the cluster
  def handle_info({:nodedown, _node, _node_type}, state) do
    update_neighbors()
    {:noreply, state}
  end

  @spec update_neighbors :: :ok
  defp update_neighbors do
    neighbors = for node <- Node.list(), do: {Crdt, node}
    Logger.debug(fn -> "[StateHandoff] Setting neighbors to #{inspect(neighbors)}" end)
    DeltaCrdt.set_neighbours(Crdt, neighbors)
  end
end
