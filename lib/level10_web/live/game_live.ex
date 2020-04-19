defmodule Level10Web.GameLive do
  @moduledoc """
  Live view for gameplay
  """
  use Phoenix.LiveView, layout: {Level10Web.LayoutView, "live.html"}
  alias Level10.Games
  alias Games.Levels
  alias Level10Web.GameView

  def mount(params, _session, socket) do
    join_code = params["join_code"]
    player_id = params["player_id"]

    with true <- Games.exists?(join_code),
         true <- Games.started?(join_code),
         true <- Games.player_exists?(join_code, player_id) do
      Games.subscribe(params["join_code"])
      players = Games.get_players(join_code)
      hand = Games.get_hand_for_player(join_code, player_id)
      scores = Games.get_scores(join_code)
      levels = levels_from_scores(scores)
      player_level = levels[player_id]
      discard_top = Games.get_top_discarded_card(join_code)
      turn = Games.get_current_turn(join_code)

      assigns = [
        discard_top: discard_top,
        hand: hand,
        join_code: params["join_code"],
        levels: levels,
        player_id: params["player_id"],
        player_level: player_level,
        players: players,
        turn: turn
      ]

      {:ok, assign(socket, assigns)}
    else
      _ ->
        {:ok, push_redirect(socket, to: "/")}
    end
  end

  def render(assigns) do
    GameView.render("game.html", assigns)
  end

  @spec levels_from_scores(Games.scores()) :: %{optional(Player.id()) => Levels.level()}
  defp levels_from_scores(scores) do
    levels_list =
      Enum.map(scores, fn {player_id, {level_number, _}} ->
        level = Levels.by_number(level_number)
        {player_id, level}
      end)

    Enum.into(levels_list, %{})
  end

  def handle_event("draw_card", %{"source" => source}, %{assigns: assigns} = socket) do
    player_id = assigns.player_id

    source =
      case source do
        "draw_pile" -> :draw_pile
        "discard_pile" -> :discard_pile
      end

    with ^player_id <- assigns.turn.id,
         hand when is_list(hand) <- Games.draw_card(assigns.join_code, assigns.player_id, source) do
      {:noreply, assign(socket, :hand, hand)}
    else
      _ ->
        {:noreply, socket}
    end
  end
end
