defmodule Level10Web.LobbyComponents do
  @moduledoc """
  Provides UI components for the game screen.
  """

  use Level10Web, :html
  alias Level10.Games.Settings

  @doc """
  The screen for creating a new game.
  """
  attr :display_name, :string, required: true
  attr :settings, Settings, required: true

  @spec create(map) :: Phoenix.LiveView.Rendered.t()
  def create(assigns) do
    ~H"""
    <div class="flex-1 mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <.logo />
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <.form :let={f} for={:info} action="#" phx-change="validate" phx-submit="create_game">
          <.input
            field={{f, :display_name}}
            label="Display name"
            value={@display_name}
            phx-hook="SelectOnMount"
          />
          <.input
            field={{f, :skip_next_player}}
            label="Skip next player"
            type="checkbox"
            value={@settings.skip_next_player}
            click="toggle_setting"
            setting="skip_next_player"
            description="When skip cards are played the next player will be skipped, rather than allowing the player who discarded the skip to choose."
          />
        </.form>
        <div class="mt-6">
          <.button type="submit" phx-click="create_game" level={:primary}>Create Game</.button>
        </div>
        <div class="mt-4">
          <%= live_patch to: ~p"/", replace: true do %>
            <.button type="cancel" phx-click="cancel" level={:ghost}>Nevermind</.button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  The screen for joining an existing game.
  """
  attr :display_name, :string, required: true
  attr :join_code, :string, required: true

  @spec join(map) :: Phoenix.LiveView.Rendered.t()
  def join(assigns) do
    ~H"""
    <div class="flex-1 mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <.logo />
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <.form
        :let={f}
        for={:info}
        action="#"
        phx-change="validate"
        phx-submit="join_game"
        class="py-8 px-4 sm:rounded-lg sm:px-10 space-y-6"
      >
        <.input
          field={{f, :display_name}}
          label="Display name"
          value={@display_name}
          phx-hook="SelectOnMount"
        />
        <.input field={{f, :join_code}} label="Join code" value={@join_code} class="uppercase" />
        <.button type="submit" level={:primary}>Join Game</.button>
        <.button type="button" phx-click="cancel" level={:ghost}>Nevermind</.button>
      </.form>
    </div>
    """
  end

  @doc """
  The screen for deciding whether to create a new game or join an existing one.
  """
  @spec lobby(map) :: Phoenix.LiveView.Rendered.t()
  def lobby(assigns) do
    ~H"""
    <div class="flex-1 mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <.logo />
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <%= live_patch to: ~p"/create", replace: true do %>
              <.button level={:secondary}>Create Game</.button>
            <% end %>
          </span>
        </div>
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <%= live_patch to: ~p"/join", replace: true do %>
              <.button level={:primary}>Join Game</.button>
            <% end %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Render the screen for waiting for the game to start.
  """
  attr :is_creator, :boolean, required: true
  attr :join_code, :string, required: true
  attr :players, :list, required: true
  attr :presence, :map, required: true
  attr :starting, :boolean, default: false

  @spec wait(map) :: Phoenix.LiveView.Rendered.t()
  def wait(assigns) do
    ~H"""
    <div class="flex-1 mt-10 sm:mx-auto sm:w-full sm:max-w-md">
      <h3 class="text-center text-xl text-violet-200 font-semibold tracking-wide">
        Join Code
      </h3>
      <h2 class="text-center text-4xl leading-9 font-extrabold text-white">
        <%= @join_code %>
      </h2>
      <div class="mt-12 sm:mx-auto sm:w-full sm:max-w-md">
        <h2 class="text-center text-xl text-violet-200 font-semibold tracking-wide">
          Players
        </h2>
        <ul class="py-2 px-4 list-decimal">
          <%= for player <- @players do %>
            <li class="flex px-4 py-2 font-bold text-3xl text-white items-center">
              <.status_indicator online={player.id in Map.keys(@presence)} class="mr-2" />
              <div><%= player.name %></div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <div :if={@is_creator} class="mt-6">
          <.button level={:primary} phx-click="start_game" disabled={@starting}>
            <%= if @starting, do: "Starting...", else: "Start Game" %>
          </.button>
        </div>
        <div class="flex mt-4">
          <.button level={:ghost} phx-click="leave" class="w-1/2">Leave</.button>
          <a href="#" onclick={"openSmsInvite('#{@join_code}')"} class="w-1/2">
            <.button level={:ghost} phx-click="leave">Invite</.button>
          </a>
        </div>
      </div>
    </div>
    """
  end
end
