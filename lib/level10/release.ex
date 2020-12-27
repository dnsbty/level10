defmodule Level10.Release do
  @moduledoc """
  Release tasks to be run manually or as externally controlled jobs.

  Typically these will be run through the release binary's eval or rpc
  commands:

  ```
  # Run the database migrations
  bin/level10 eval Level10.Release.migrate() 

  # Roll back a migration
  bin/level10 eval Level10.Release.rollback(Level10.Repo, 20201105040920) 
  ```
  """

  @app :level10

  @doc """
  Runs the database migrations.
  """
  @spec migrate :: no_return()
  def migrate do
    start_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  @doc """
  Rolls back the database migrations to the state prior to the provided version.
  """
  @spec rollback(module(), pos_integer()) :: no_return()
  def rollback(repo, version) do
    start_app()

    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  # PRIVATE

  @spec repos :: list(module())
  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  @spec start_app :: {:ok, [atom()]} | {:error, {atom(), term()}}
  defp start_app do
    Application.load(@app)
    Application.put_env(@app, :database_only, true)
    Application.ensure_all_started(@app)
  end
end
