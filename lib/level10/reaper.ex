defmodule Level10.Reaper do
  @moduledoc """
  The Reaper is responsible for deleting any games that haven't been updated in
  over 24 hours. This helps to save bandwidth between the machines because the
  CRDTs that manage the Registry have to sync over the network for all the
  games.
  """

  use GenServer

  alias Level10.Games
  alias Level10.Games.GameSupervisor
  alias Level10.StateHandoff
  require Logger

  @frequency 1000 * 60 * 60

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule()
    {:ok, state}
  end

  @impl true
  def handle_info(:perform_reaping, state) do
    perform_reaping()
    schedule()
    {:noreply, state}
  end

  @doc """
  Deletes all inactive games.
  """
  @spec perform_reaping(supervisor :: module) :: :ok
  def perform_reaping(supervisor \\ GameSupervisor) do
    deletion_tasks =
      for pid <- Games.list_inactive_games(supervisor) do
        Task.async(Games, :delete_game, [pid])
      end

    StateHandoff.reap()
    results = Task.await_many(deletion_tasks)
    Logger.info("Reaper deleted #{length(results)} inactive games")
  end

  # Private

  @spec schedule :: no_return
  defp schedule, do: Process.send_after(self(), :perform_reaping, @frequency)
end
