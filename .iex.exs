alias Level10.Games
alias Games.{Card, Game, Levels, Player}

# {:ok, game, player1} = Games.create_game("Player 1")
# {:ok, player2} = Games.join_game(game, "Player 2")
# {:ok, player3} = Games.join_game(game, "Player 3")

dennis = Player.new("Dennis")
brett = Player.new("Brett")
{:ok, game} = "ABCD" |> Game.new(dennis) |> Game.put_player(brett)
{:ok, game} = Game.start_round(game)
