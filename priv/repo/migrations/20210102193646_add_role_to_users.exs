defmodule Level10.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def up do
    execute("create type user_role as enum ('admin', 'player')")

    alter table(:users) do
      add :role, :user_role, null: false, default: "player"
    end
  end

  def down do
    alter table(:users) do
      remove :role, :user_role
    end

    execute("drop type user_role")
  end
end
