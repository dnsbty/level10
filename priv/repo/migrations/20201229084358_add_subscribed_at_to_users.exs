defmodule Level10.Repo.Migrations.AddSubscribedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :subscribed_at, :naive_datetime
    end
  end
end
