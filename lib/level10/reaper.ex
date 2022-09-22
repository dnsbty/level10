defmodule Level10.Reaper do
  @moduledoc """
  The Reaper is responsible for deleting any games that haven't been updated in
  over 24 hours. This helps to save bandwidth between the machines because the
  CRDTs that manage the Registry have to sync over the network for all the
  games.
  """

  alias Level10.Games
  alias Level10.Games.GameSupervisor
  require Logger

  @doc """
  Deletes all inactive games.
  """
  @spec perform_reaping(supervisor :: module) :: :ok
  def perform_reaping(supervisor \\ GameSupervisor) do
    deletion_tasks =
      for pid <- Games.list_inactive_games(supervisor) do
        Task.async(Games, :delete_game, [pid])
      end

    results = Task.await_many(deletion_tasks)
    Logger.info("Reaper deleted #{length(results)} inactive games")
  end
end
