defmodule Level10.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    create_query = "create type user_role as enum ('admin', 'player')"
    drop_query = "drop type user_role"
    execute(create_query, drop_query)

    alter table(:users) do
      add :role, :user_role, null: false, default: "player"
    end
  end
end
