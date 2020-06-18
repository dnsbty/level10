defmodule Level10.StateHandoff do
  @moduledoc """
  Whenever a SIGTERM is received, this GenServer is used to store the state of
  the games on the local node across the entire cluster so that it can be
  replicated in new nodes once this one goes down.
  """

  use GenServer
  require Logger

  @crdt_name Level10.StateHandoff.Crdt

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Reset the current state of the CRDT
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
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

  @doc false
  def init(_) do
    opts = [name: @crdt_name, sync_interval: 3]
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap, opts)

    # Register to receive messages when nodes enter and leave the cluster
    :net_kernel.monitor_nodes(true, node_type: :visible)

    # connect to the CRDTs on the other nodes
    update_neighbours(crdt)

    {:ok, crdt}
  end

  @doc false
  def handle_call(:clear, _from, crdt) do
    for {key, _} <- DeltaCrdt.read(crdt) do
      DeltaCrdt.mutate(crdt, :remove, [key])
    end

    {:reply, :ok, crdt}
  end

  def handle_call(:get, _from, crdt) do
    state = DeltaCrdt.read(crdt)
    {:reply, state, crdt}
  end

  def handle_call({:handoff, join_code, game}, _from, crdt) do
    case DeltaCrdt.read(crdt) do
      %{^join_code => _game} ->
        Logger.debug(fn -> "[StateHandoff] Game #{join_code} already exists in the CRDT" end)

      _ ->
        DeltaCrdt.mutate(crdt, :add, [join_code, game])
        Logger.debug(fn -> "[StateHandoff] Added game #{join_code} to CRDT" end)
    end

    {:reply, :ok, crdt}
  end

  def handle_call({:pickup, join_code}, _from, crdt) do
    game =
      crdt
      |> DeltaCrdt.read()
      |> Map.get(join_code, nil)

    if !is_nil(game) do
      Logger.debug(fn -> "[StateHandoff] Picked up game #{join_code}" end)
      DeltaCrdt.mutate(crdt, :remove, [join_code])
    end

    {:reply, game, crdt}
  end

  # Handle the message received when a new node joins the cluster
  def handle_info({:nodeup, _node, _node_type}, crdt) do
    update_neighbours(crdt)
    {:noreply, crdt}
  end

  # Handle the message received when a node leaves the cluster
  def handle_info({:nodedown, _node, _node_type}, crdt) do
    update_neighbours(crdt)
    {:noreply, crdt}
  end

  defp update_neighbours(crdt) do
    neighbours = for node <- Node.list(), do: {@crdt_name, node}
    Logger.debug(fn -> "[StateHandoff] Setting neighbours to #{inspect(neighbours)}" end)
    DeltaCrdt.set_neighbours(crdt, neighbours)
  end
end
