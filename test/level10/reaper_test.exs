defmodule Level10.ReaperTest do
  use ExUnit.Case, async: true

  alias Level10.Games.GameServer
  alias Level10.Games.Player
  alias Level10.Games.Settings
  alias Level10.Reaper

  def game_spec(join_code) do
    player = %Player{id: "44de2003-f9ef-446e-951d-a2cea7f9bcef", name: "Dennis"}
    settings = %Settings{skip_next_player: false}

    %{
      id: join_code,
      start:
        {GameServer, :start_link,
         [
           {join_code, player, settings},
           [name: {:via, Horde.Registry, {ReapRegistry, join_code}}]
         ]},
      shutdown: 1000,
      restart: :temporary
    }
  end

  setup do
    {:ok, _} =
      Horde.DynamicSupervisor.start_link(
        name: ReapSupervisor,
        strategy: :one_for_one,
        members: :auto
      )

    {:ok, _} = Horde.Registry.start_link(name: ReapRegistry, keys: :unique, members: :auto)
    :ok
  end

  describe "perform_reaping/1" do
    @one_hour 60 * 60

    test "deletes any games that haven't been updated recently" do
      now = NaiveDateTime.utc_now()

      {:ok, one_min} = Horde.DynamicSupervisor.start_child(ReapSupervisor, game_spec("NOWW"))
      one_min_ago = NaiveDateTime.add(now, -60, :second)
      :sys.replace_state(one_min, fn game -> %{game | updated_at: one_min_ago} end)

      {:ok, twelve_hrs} = Horde.DynamicSupervisor.start_child(ReapSupervisor, game_spec("12HR"))
      twelve_hrs_ago = NaiveDateTime.add(now, @one_hour * -12, :second)
      :sys.replace_state(twelve_hrs, fn game -> %{game | updated_at: twelve_hrs_ago} end)

      {:ok, one_day} = Horde.DynamicSupervisor.start_child(ReapSupervisor, game_spec("24HR"))
      one_day_ago = NaiveDateTime.add(now, @one_hour * -24 - 1, :second)
      :sys.replace_state(one_day, fn game -> %{game | updated_at: one_day_ago} end)

      {:ok, thirty_hrs} = Horde.DynamicSupervisor.start_child(ReapSupervisor, game_spec("30HR"))
      thirty_hrs_ago = NaiveDateTime.add(now, @one_hour * -30, :second)
      :sys.replace_state(thirty_hrs, fn game -> %{game | updated_at: thirty_hrs_ago} end)

      {:ok, updated_nil} = Horde.DynamicSupervisor.start_child(ReapSupervisor, game_spec("NULL"))
      :sys.replace_state(updated_nil, fn game -> %{game | updated_at: nil} end)

      Reaper.perform_reaping(ReapSupervisor)

      assert Process.alive?(one_min)
      assert Process.alive?(twelve_hrs)
      refute Process.alive?(one_day)
      refute Process.alive?(thirty_hrs)
      refute Process.alive?(updated_nil)
    end
  end
end
