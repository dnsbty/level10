defmodule Level10.GamesTest do
  use ExUnit.Case, async: true

  alias Level10.Games
  alias Level10.Games.GameServer
  alias Level10.Games.Player
  alias Level10.Games.Settings

  def game_spec(join_code) do
    player = %Player{id: "44de2003-f9ef-446e-951d-a2cea7f9bcef", name: "Dennis"}
    settings = %Settings{skip_next_player: false}

    %{
      id: join_code,
      start:
        {GameServer, :start_link,
         [
           {join_code, player, settings},
           [name: {:via, Horde.Registry, {TestRegistry, join_code}}]
         ]},
      shutdown: 1000,
      restart: :temporary
    }
  end

  setup do
    {:ok, _} =
      Horde.DynamicSupervisor.start_link(
        name: TestSupervisor,
        strategy: :one_for_one,
        members: :auto
      )

    {:ok, _} = Horde.Registry.start_link(name: TestRegistry, keys: :unique, members: :auto)
    :ok
  end

  describe "list_inactive_games/1" do
    @one_hour 60 * 60

    test "returns a list of games that haven't been updated recently" do
      now = NaiveDateTime.utc_now()

      {:ok, one_min_ago} = Horde.DynamicSupervisor.start_child(TestSupervisor, game_spec("NOWW"))

      :sys.replace_state(one_min_ago, fn game ->
        %{game | updated_at: NaiveDateTime.add(now, -60, :second)}
      end)

      {:ok, twelve_hrs_ago} =
        Horde.DynamicSupervisor.start_child(TestSupervisor, game_spec("12HR"))

      :sys.replace_state(twelve_hrs_ago, fn game ->
        %{game | updated_at: NaiveDateTime.add(now, @one_hour * -12, :second)}
      end)

      {:ok, twenty_four_hrs_ago} =
        Horde.DynamicSupervisor.start_child(TestSupervisor, game_spec("24HR"))

      :sys.replace_state(twenty_four_hrs_ago, fn game ->
        %{game | updated_at: NaiveDateTime.add(now, @one_hour * -24 - 1, :second)}
      end)

      {:ok, thirty_hrs_ago} =
        Horde.DynamicSupervisor.start_child(TestSupervisor, game_spec("30HR"))

      :sys.replace_state(thirty_hrs_ago, fn game ->
        %{game | updated_at: NaiveDateTime.add(now, @one_hour * -30, :second)}
      end)

      inactive_games = Games.list_inactive_games(TestSupervisor)
      refute one_min_ago in inactive_games
      refute twelve_hrs_ago in inactive_games
      assert twenty_four_hrs_ago in inactive_games
      assert thirty_hrs_ago in inactive_games
    end
  end
end
