defmodule Level10Web.DisplayComponents do
  @moduledoc """
  Provides UI components for the game screen.
  """

  use Level10Web, :html
  alias Level10.Games.Card
  alias Level10.Games.Game
  alias Level10.Games.Player
  alias Level10Web.GameComponents

  @doc """
  Renders the game screen.
  """
  attr :discard_top, Card, default: nil
  attr :game, Game, required: true
  attr :hand_counts, :map, required: true
  attr :levels, :map, required: true
  attr :presence, :map, required: true

  @spec play(map) :: Phoenix.LiveView.Rendered.t()
  def play(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center h-screen w-full">
      <!-- Draw and Discard Piles -->
      <div class="w-1/3 flex flex-col items-center">
        <p class="text-center text-3xl mb-32 text-violet-200">
          Waiting for <%= @game.current_player.name %> to <%= if @game.current_turn_drawn?,
            do: "discard",
            else: "draw" %>...
        </p>
        <div class="flex flew-row">
          <div class="w-1/3 ml-auto mr-8 text-center rounded-lg">
            <GameComponents.card_back />
          </div>
          <div class={"w-1/3 mr-auto text-center #{discard_styles(@discard_top)} rounded-lg"}>
            <span :if={is_nil(@discard_top)}>Discard Pile</span>
            <GameComponents.card :if={!is_nil(@discard_top)} card={@discard_top} />
          </div>
        </div>
      </div>
      <!-- Player Display -->
      <div class="flex flex-col justify-around w-2/3 my-8 h-screen py-8">
        <%= for player <- @game.players do %>
          <div class="flex flex-row h-full items-center ml-4 mr-2 my-2">
            <div class="flex flex-col w-1/5">
              <div class="flex flex-row items-center">
                <.status_indicator
                  size={:xlarge}
                  online={player.id in Map.keys(@presence)}
                  class="mr-2 cursor-default"
                />
                <div class={[
                  "flex-1 text-white text-3xl font-bold",
                  player.id == @game.current_player.id &&
                    "text-white underline underline-offset-4 decoration-2 opacity-100",
                  player.id != @game.current_player.id && "opacity-60",
                  player.id in @game.skipped_players && "line-through"
                ]}>
                  <%= player.name %>
                </div>
              </div>
              <div class="flex flex-row items-center text-violet-300 text-xl">
                <div>
                  <%= player_score(@game.scoring, player.id) %> pts (L<%= level(
                    @game.scoring,
                    player.id
                  ) %>)
                </div>
                <div class="mx-2 mb-1">&#x1F02B;</div>
                <div><%= @hand_counts[player.id] %></div>
              </div>
            </div>
            <%= if is_nil(@game.table[player.id]) do %>
              <div class="flex flex-1 h-full flex-row">
                <%= for group <- @levels[player.id] do %>
                  <div class="flex flex-row items-center flex-1 mr-2 h-full bg-violet-900 rounded-lg py-2">
                    <p class="flex-1 text-violet-400 text-center text-4xl">
                      <%= level_group_name(group) %>
                    </p>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="flex flex-1 h-full">
                <%= for {group, position} <- Enum.with_index(@levels[player.id]) do %>
                  <div class="flex flex-col flex-1 h-full bg-violet-900 mr-2 rounded-lg p-1">
                    <p class="w-full text-violet-400 text-center text-lg">
                      <%= level_group_name(group) %>
                    </p>
                    <div class="flex flex-row flex-1 text-violet-400 items-center">
                      <%= for card <- @game.table[player.id][position] do %>
                        <div class="mr-1">
                          <GameComponents.card card={card} />
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders the join screen.
  """
  attr :join_code, :string, required: true

  @spec join(map) :: Phoenix.LiveView.Rendered.t()
  def join(assigns) do
    ~H"""
    <div class="flex-1 mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <.logo />
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <.form
          :let={f}
          for={%{}}
          as={:game}
          action="#"
          phx-change="validate"
          phx-submit="begin_observing"
        >
          <div class="mt-6">
            <.input label="Join code" field={{f, :join_code}} value={@join_code} class="uppercase" />
          </div>
          <div class="mt-6 mb-32">
            <.button level={:primary} type="submit">
              Observe Game
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @doc """
  Renders the lobby screen.
  """
  attr :game, Game, required: true
  attr :presence, :map, required: true

  @spec lobby(map) :: Phoenix.LiveView.Rendered.t()
  def lobby(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center h-screen w-full">
      <div class="flex flex-1 flex-col items-center">
        <div>
          <h3 class="text-center text-3xl text-violet-200 tracking-widest uppercase">
            Join Code
          </h3>
          <h2 class="text-center text-6xl mt-4 leading-9 font-black text-violet-100">
            <%= @game.join_code %>
          </h2>
        </div>
        <p class="text-center text-3xl my-32 text-violet-200">
          Waiting for <%= Level10.Games.Game.creator(@game).name %> to start the game...
        </p>
      </div>
      <div class="flex-1 pt-12 h-screen">
        <h2 class="text-center text-3xl text-violet-200 tracking-widest uppercase">
          Players
        </h2>
        <ul class="mt-8 px-4 list-decimal">
          <%= for player <- @game.players do %>
            <li class="flex px-4 py-2 font-extrabold tracking-wide text-5xl text-violet-100 items-center">
              <.status_indicator
                online={player.id in Map.keys(@presence)}
                class="mr-4 cursor-default"
              />
              <div><%= player.name %></div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  @doc """
  Renders the scoring screen.
  """
  attr :game, Game, required: true
  attr :presence, :map, required: true
  attr :round_winner, Player, required: true

  @spec score(map) :: Phoenix.LiveView.Rendered.t()
  def score(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-around h-screen mx-16">
      <div class="w-1/3 flex flex-col items-center">
        <p class="text-center text-6xl text-violet-200 font-black">
          <%= @round_winner.name %> wins the round!
        </p>
      </div>
      <!-- Player Display -->
      <div class="w-1/2">
        <h3 class="text-center text-3xl font-bold text-violet-200">
          Scores after round <%= @game.current_round %>
        </h3>
        <ol class="pl-12 list-decimal mt-16">
          <%= for player <- @players do %>
            <li class="px-4 py-2 font-extrabold tracking-wide text-4xl text-violet-100">
              <div class="flex items-center">
                <div class="flex-1">
                  <%= player.name %>
                </div>
                <div>
                  <%= player_score(@game.scoring, player.id) %> (<%= level(@game.scoring, player.id) %>)
                </div>
                <%= if MapSet.member?(@game.players_ready, player.id) do %>
                  <div>✓</div>
                <% else %>
                  <.status_indicator
                    size={:xlarge}
                    online={player.id in Map.keys(@presence)}
                    class="ml-2"
                  />
                <% end %>
              </div>
            </li>
          <% end %>
        </ol>
      </div>
    </div>
    """
  end

  # Returns the list of classes that should apply to the discard pile depending
  # on its color and whether or not there is a card present
  @spec discard_styles(Card.t() | nil) :: String.t()
  defp discard_styles(%Card{}), do: ""

  defp discard_styles(nil) do
    "text-xs py-5 border border-violet-400 text-violet-400"
  end

  @spec level(Game.scoring(), Player.id()) :: non_neg_integer()
  defp level(scores, player_id) do
    {level, _} = scores[player_id]
    level
  end

  @spec level_group_name(Levels.level()) :: String.t()
  defp level_group_name({:set, count}), do: "Set of #{count}"
  defp level_group_name({:run, count}), do: "Run of #{count}"
  defp level_group_name({:color, count}), do: "#{count} of one Color"

  @spec player_score(Game.scoring(), Player.id()) :: non_neg_integer()
  defp player_score(scores, player_id) do
    {_, score} = scores[player_id]
    score
  end
end
