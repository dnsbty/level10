defmodule Level10.Games.LevelsTest do
  use ExUnit.Case, async: true

  alias Level10.Games.{Card, Levels}

  describe "valid_group?/2" do
    test "returns true for a valid set" do
      set = [Card.new(:twelve, :green), Card.new(:twelve, :blue), Card.new(:twelve, :red)]
      assert Levels.valid_group?({:set, 3}, set)
    end

    test "returns false for an invalid set" do
      # set has 2 twelves and an eleven
      set = [Card.new(:twelve, :green), Card.new(:twelve, :blue), Card.new(:eleven, :red)]
      refute Levels.valid_group?({:set, 3}, set)
    end

    test "returns true for a valid run" do
      run = [
        Card.new(:six, :green),
        Card.new(:seven, :green),
        Card.new(:eight, :blue),
        Card.new(:nine, :red),
        Card.new(:ten, :yellow),
        Card.new(:eleven, :blue),
        Card.new(:twelve, :green)
      ]

      assert Levels.valid_group?({:run, 7}, run)
    end

    test "returns false for an invalid run" do
      # run has 2 tens and no nine
      run = [
        Card.new(:six, :green),
        Card.new(:seven, :green),
        Card.new(:eight, :blue),
        Card.new(:ten, :red),
        Card.new(:ten, :yellow),
        Card.new(:eleven, :blue),
        Card.new(:twelve, :green)
      ]

      refute Levels.valid_group?({:run, 7}, run)
    end

    test "returns true for a valid color group" do
      color_group = [
        Card.new(:six, :green),
        Card.new(:twelve, :green),
        Card.new(:eight, :green),
        Card.new(:ten, :green),
        Card.new(:three, :green),
        Card.new(:one, :green),
        Card.new(:nine, :green)
      ]

      assert Levels.valid_group?({:color, 7}, color_group)
    end

    test "returns false for an invalid color group" do
      # color group has six green cards and one red
      color_group = [
        Card.new(:six, :green),
        Card.new(:twelve, :green),
        Card.new(:eight, :red),
        Card.new(:ten, :green),
        Card.new(:three, :green),
        Card.new(:one, :green),
        Card.new(:nine, :green)
      ]

      refute Levels.valid_group?({:color, 7}, color_group)
    end

    test "returns false when the group doesn't have enough cards" do
      set = [Card.new(:twelve, :green), Card.new(:twelve, :red)]
      refute Levels.valid_group?({:set, 3}, set)
    end
  end
end
