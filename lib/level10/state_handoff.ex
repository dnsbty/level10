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
    opts = [name: @crdt_name, sync_interval: 10]
    {:ok, crdt} = DeltaCrdt.start_link(DeltaCrdt.AWLWWMap, opts)

    # connect to the CRDTs on the other nodes
    nodes = Node.list()
    Logger.debug(fn -> "[StateHandoff] Connecting to nodes #{inspect(nodes)}" end)
    update_neighbours(crdt)
    for node <- nodes, do: GenServer.call({__MODULE__, node}, :update_neighbours)

    {:ok, crdt}
  end

  @doc false
  def handle_call(:get, _from, crdt) do
    state = DeltaCrdt.read(crdt)
    {:reply, state, crdt}
  end

  def handle_call(:update_neighbours, _from, crdt) do
    update_neighbours(crdt)
    {:reply, :ok, crdt}
  end

  def handle_call({:handoff, join_code, game}, _from, crdt) do
    DeltaCrdt.mutate(crdt, :add, [join_code, game])
    Logger.debug(fn -> "[StateHandoff] Added game #{join_code} to CRDT" end)
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

  defp update_neighbours(crdt) do
    neighbours = for node <- Node.list(), do: {@crdt_name, node}
    Logger.debug(fn -> "[StateHandoff] Setting neighbours to #{inspect(neighbours)}" end)
    DeltaCrdt.set_neighbours(crdt, neighbours)
  end
end
