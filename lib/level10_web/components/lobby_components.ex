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
      <h2 class="pt-32 text-center text-4xl leading-9 font-extrabold text-gray-100">
        Level 10
      </h2>
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <.form let={f} for={:info} action="#" phx-change="validate" phx-submit="create_game">
          <div>
            <label for="name" class="block text-sm font-medium leading-5 text-gray-300">
              Display name
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <.input field={{f, :display_name}} required={true} value={@display_name} phx-hook="SelectOnMount" class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            </div>
          </div>
          <div class="flex items-center justify-between mt-6">
            <button type="button" phx-click="toggle_setting" phx-value-setting="skip_next_player" aria-pressed="false" aria-labelledby="toggleLabel" class={"#{if @settings.skip_next_player, do: "bg-red-600", else: "bg-gray-200"} relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"}>
              <span class="sr-only">Use setting</span>
              <span aria-hidden="true" class={"#{if @settings.skip_next_player, do: "translate-x-5", else: "translate-x-0"} inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0 transition ease-in-out duration-200"}></span>
            </button>
            <span class="flex-grow flex flex-col ml-4" id="toggleLabel">
              <span class="text-sm font-medium text-gray-300">Skip next player</span>
              <span class="text-sm leading-normal text-gray-400">When skip cards are played the next player will be skipped, rather than allowing the player who discarded the skip to choose.</span>
            </span>
          </div>
        </.form>
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <button type="submit" phx-click="create_game" class="w-full flex justify-center py-2 px-4 border border-transparent text-xl font-bold rounded-md text-white bg-red-600 hover:bg-red-500 focus:outline-none focus:border-red-700 focus:shadow-outline-red active:bg-red-700 transition duration-150 ease-in-out">
              Create Game
            </button>
          </span>
        </div>
        <div class="mt-4">
          <span class="block w-full rounded-md">
            <%= live_patch to: ~p"/", replace: true do %>
              <button type="cancel" phx-click="cancel" class="w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-gray-300 bg-violet-800 hover:bg-violet-700 focus:outline-none focus:border-violet-700 focus:shadow-outline-violet active:bg-violet-800 transition duration-150 ease-in-out">
                Nevermind
              </button>
            <% end %>
          </span>
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
      <h2 class="pt-32 text-center text-4xl leading-9 font-extrabold text-gray-100">
        Level 10
      </h2>
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <.form let={f} for={:info} action="#" phx-change="validate" phx-submit="join_game">
          <div>
            <label for="name" class="block text-sm font-medium leading-5 text-gray-300">
              Display name
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <.input field={{f, :display_name}} required={true} value={@display_name} phx-hook="SelectOnMount" class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            </div>
          </div>
          <div class="mt-6">
            <label for="join_code" class="block text-sm font-medium leading-5 text-gray-300">
              Join code
            </label>
            <div class="mt-1 rounded-md shadow-sm">
              <.input field={{f, :join_code}} required={true} value={@join_code} class="uppercase appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md placeholder-gray-400 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            </div>
          </div>
          <div class="mt-6">
            <span class="block w-full rounded-md shadow-sm">
              <button type="submit" class="w-full flex justify-center py-2 px-4 border border-transparent text-xl font-bold rounded-md text-white bg-red-600 hover:bg-red-500 focus:outline-none focus:border-red-700 focus:shadow-outline-red active:bg-red-700 transition duration-150 ease-in-out">
                Join Game
              </button>
            </span>
          </div>
        </.form>
        <div class="mt-4">
          <span class="block w-full rounded-md">
            <button type="cancel" phx-click="cancel" class="w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-gray-300 bg-violet-800 hover:bg-violet-700 focus:outline-none focus:border-violet-700 focus:shadow-outline-violet active:bg-violet-800 transition duration-150 ease-in-out">
              Nevermind
            </button>
          </span>
        </div>
      </div>
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
      <h2 class="pt-32 text-center text-4xl leading-9 font-extrabold text-gray-100">
        Level 10
      </h2>
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <%= live_patch to: ~p"/create", replace: true do %>
              <button class="w-full flex justify-center py-2 px-4 border border-transparent text-lg font-medium rounded-md text-white bg-violet-600 hover:bg-violet-500 focus:outline-none focus:border-violet-700 focus:shadow-outline-violet active:bg-violet-700 transition duration-150 ease-in-out">
                Create Game
              </button>
            <% end %>
          </span>
        </div>
        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm leading-5">
              <span class="px-2 bg-violet-800 text-gray-300">
                or
              </span>
            </div>
          </div>
        </div>
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <%= live_patch to: ~p"/join", replace: true do %>
              <button class="w-full flex justify-center py-2 px-4 border border-transparent text-xl font-bold rounded-md text-white bg-red-600 hover:bg-red-500 focus:outline-none focus:border-red-700 focus:shadow-outline-red active:bg-red-700 transition duration-150 ease-in-out">
                Join Game
              </button>
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

  @spec wait(map) :: Phoenix.LiveView.Rendered.t()
  def wait(assigns) do
    ~H"""
    <div class="flex-1 mt-10 sm:mx-auto sm:w-full sm:max-w-md">
      <h3 class="text-center text-sm text-gray-100 font-bold tracking-widest uppercase">
        Join Code
      </h3>
      <h2 class="text-center text-4xl leading-9 font-extrabold text-gray-100">
        <%= @join_code %>
      </h2>
      <div class="mt-12 sm:mx-auto sm:w-full sm:max-w-md">
        <h2 class="text-center text-sm text-gray-100 font-bold tracking-widest uppercase">
          Players
        </h2>
        <ul class="mt-6 px-4 list-decimal">
          <%= for player <- @players do %>
          <li class="flex px-4 py-2 font-bold tracking-wide text-2xl text-gray-100 items-center">
            <%= if player.id in Map.keys(@presence) do %>
              <div class="text-sm text-green-500 mr-2 cursor-default" title="online">
                ●
              </div>
              <% else %>
              <div class="text-sm text-violet-500 mr-2 cursor-default" title="offline">
                ○
              </div>
            <% end %>
            <div><%= player.name %></div>
          </li>
          <% end %>
        </ul>
      </div>
    </div>
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <div class="py-8 px-4 sm:rounded-lg sm:px-10">
        <%= if @is_creator do %>
        <div class="mt-6">
          <span class="block w-full rounded-md shadow-sm">
            <button type="submit" phx-click="start_game" disabled={assigns[:starting]} class="w-full flex justify-center py-2 px-4 border border-transparent text-xl font-bold rounded-md text-white bg-red-600 hover:bg-red-500 focus:outline-none focus:border-red-700 focus:shadow-outline-red active:bg-red-700 transition duration-150 ease-in-out">
              <%= if assigns[:starting], do: "Starting...", else: "Start Game" %>
            </button>
          </span>
        </div>
        <% end %>
        <div class="flex mt-4">
          <button type="cancel" phx-click="leave" class="w-1/2 flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-gray-300 bg-violet-800 hover:bg-violet-700 focus:outline-none focus:border-violet-700 focus:shadow-outline-violet active:bg-violet-800 transition duration-150 ease-in-out">
            Leave
          </button>
          <a href="#" onclick={"openSmsInvite('#{@join_code}')"} class="w-1/2 flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-gray-300 bg-violet-800 hover:bg-violet-700 focus:outline-none focus:border-violet-700 focus:shadow-outline-violet active:bg-violet-800 transition duration-150 ease-in-out">
            Invite
          </a>
        </div>
      </div>
    </div>
    """
  end
end
