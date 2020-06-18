defmodule Level10.TerminationMonitor do
  @moduledoc """
  This server runs with the sole purpose of notifying other processes when a
  SIGTERM has been received.
  """

  use GenServer
  require Logger
  alias Level10.StateHandoff
  alias Level10.Games.{GameServer, GameSupervisor}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, :running}
  end

  def terminate(_reason, _state) do
    Logger.debug(fn -> "[TerminationMonitor] SIGTERM received. Preparing for shutdown." end)
    StateHandoff.prepare_for_shutdown()
    :ok
  end
end
