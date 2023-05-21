defmodule Level10Web.CoreComponents do
  @moduledoc """
  Provides core UI components.

  The components in this module use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn how to
  customize the generated components in this module.

  Icons are provided by [heroicons](https://heroicons.com), using the
  [heroicons_elixir](https://github.com/mveytsman/heroicons_elixir) project.
  """
  use Phoenix.Component
  import Level10Web.Gettext
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :kind, :atom, values: [:info, :error, :warning], doc: "used for styling and flash lookup"
  attr :autoshow, :boolean, default: true, doc: "whether to auto show the flash on mount"
  attr :close, :boolean, default: true, doc: "whether the flash can be closed"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot(:inner_block, doc: "the optional inner block that renders the flash message")

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-mounted={@autoshow && show("##{@id}")}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("#flash")}
      role="alert"
      class={[
        "hidden z-10 fixed flex flex-row items-center top-0 inset-x-0 p-4 shadow-md text-lg text-white",
        @kind == :warning && "bg-yellow-500 shadow-yellow-600",
        @kind == :error && "bg-red-500 shadow-red-700"
      ]}
      {@rest}
    >
      <p class="text-lg leading-5"><%= msg %></p>
      <button
        :if={@close}
        type="button"
        class="group p-2 rounded-full focus:outline-none focus:ring-2 focus:ring-white focus:shadow-outline-red"
        aria-label={gettext("close")}
      >
        <Heroicons.x_mark solid class="h-5 w-5 stroke-current opacity-80 group-hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Render the game logo.
  """
  @spec logo(map) :: Phoenix.LiveView.Rendered.t()
  def logo(assigns) do
    ~H"""
    <h2 class="pt-32 text-center text-6xl leading-9 font-black text-gray-100">
      Level 10
    </h2>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :class, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :level, :atom, default: :primary
  attr :rest, :global, include: ~w(form name value)
  attr :type, :string, default: nil

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "w-full flex justify-center py-3 px-4 border border-transparent text-2xl rounded-2xl",
        "focus:outline-none transition duration-150 ease-in-out text-shadow-md",
        button_disabled_class(@disabled),
        button_hover_bg_color(@level, @disabled),
        button_level_styles(@level),
        @class
      ]}
      disabled={@disabled}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @spec button_level_styles(atom) :: list(String.t())
  defp button_level_styles(:primary) do
    [
      "bg-red-500 shadow-md shadow-red-700/25",
      "font-extrabold text-white text-shadow-red-600",
      "focus:ring-2 focus:ring-red-200 focus:shadow-outline-red active:bg-red-400"
    ]
  end

  defp button_level_styles(:secondary) do
    [
      "bg-violet-400 shadow-md shadow-violet-900/25",
      "font-bold text-white text-shadow-violet-400",
      "focus:ring-2 focus:ring-violet-100 focus:shadow-outline-violet active:bg-violet-300"
    ]
  end

  defp button_level_styles(:ghost) do
    [
      "font-bold text-violet-300 hover:text-violet-100 text-shadow-violet-300",
      "focus:ring-2 focus:ring-violet-300 focus:shadow-outline-violet active:text-violet-100"
    ]
  end

  @spec button_disabled_class(boolean) :: String.t()
  defp button_disabled_class(true), do: "opacity-40 line-through decoration-2"
  defp button_disabled_class(false), do: ""

  @spec button_hover_bg_color(atom, boolean) :: String.t()
  defp button_hover_bg_color(_, true), do: ""
  defp button_hover_bg_color(:primary, false), do: "hover:bg-red-400"
  defp button_hover_bg_color(:secondary, false), do: "hover:bg-violet-300"
  defp button_hover_bg_color(:ghost, false), do: "hover:bg-violet-700"

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string, default: nil
  attr :description, :string
  attr :class, :string, default: nil

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :click, :string, default: nil
  attr :setting, :string, default: nil
  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete disabled form max maxlength min minlength
                                   pattern placeholder readonly required size step)
  slot(:inner_block)

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = Form.input_name(f, field)
      if assigns.multiple, do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> Form.input_id(f, field) end)
    |> assign_new(:value, fn -> Form.input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> input_equals?(assigns.value, "true") end)

    ~H"""
    <div class="flex items-center justify-between mt-6">
      <button
        type="button"
        phx-click={@click}
        phx-value-setting={@setting}
        aria-pressed={!@checked}
        aria-labelledby="toggleLabel"
        class={[
          @checked && "bg-red-500",
          !@checked && "bg-violet-200",
          "relative inline-flex flex-shrink-0 h-6 w-11 border-2 border-transparent rounded-full",
          "cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none",
          "focus:ring-2 focus:ring-offset-2 focus:ring-violet-500"
        ]}
      >
        <span class="sr-only">Use setting</span>
        <span
          aria-hidden="true"
          class={[
            @checked && "translate-x-5",
            !@checked && "translate-x-0",
            "inline-block h-5 w-5 rounded-full bg-white shadow transform ring-0",
            "transition ease-in-out duration-200"
          ]}
        >
        </span>
      </button>
      <span class="flex-grow flex flex-col ml-4" id="toggleLabel">
        <span class="text-lg font-semibold text-white"><%= @label %></span>
        <span class="text-md text-violet-300 leading-normal"><%= @description %></span>
      </span>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[
          "appearance-none block w-full px-4 py-3 border border-violet-300 rounded-md",
          "placeholder-slate-400 focus:outline-none focus:shadow-outline-violet focus:ring-2 focus:ring-violet-500",
          "transition duration-150 ease-in-out bg-violet-200 rounded-lg text-2xl font-bold text-slate-700",
          input_border(@errors),
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400 focus:ring-zinc-800/5"

  defp input_border([_ | _] = _errors),
    do: "border-rose-400 focus:border-rose-400 focus:ring-rose-400/10"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-xl font-bold mb-2.5 text-white">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot(:inner_block, required: true)

  def error(assigns) do
    ~H"""
    <p class="phx-no-feedback:hidden mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-rose-500" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(Level10Web.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Level10Web.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  An indicator showing whether a user is currently online or not.
  """
  attr :class, :string, default: ""
  attr :online, :boolean, required: true
  attr :size, :atom, default: :medium

  @spec status_indicator(map) :: Phoenix.LiveView.Rendered.t()
  def status_indicator(assigns) do
    if assigns[:online] do
      ~H"""
      <div class={[indicator_size(@size), "text-green-400 cursor-default", @class]} title="online">
        ●
      </div>
      """
    else
      ~H"""
      <div class={[indicator_size(@size), "text-slate-400 cursor-default", @class]} title="offline">
        ○
      </div>
      """
    end
  end

  @spec indicator_size(:medium | :small) :: String.t()
  defp indicator_size(:small), do: "text-lg"
  defp indicator_size(:medium), do: "text-xl"
  defp indicator_size(:xlarge), do: "text-3xl"

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  @spec translate_errors(list, atom) :: list
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  @spec input_equals?(String.t(), String.t()) :: boolean
  defp input_equals?(val1, val2) do
    Phoenix.HTML.html_escape(val1) == Phoenix.HTML.html_escape(val2)
  end

  ## JS Commands

  @spec hide(Phoenix.LiveView.JS.t(), String.t()) :: Phoenix.LiveView.JS.t()
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      display: "flex",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @spec hide(Phoenix.LiveView.JS.t(), String.t()) :: Phoenix.LiveView.JS.t()
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @spec update_theme_color(Phoenix.LiveView.JS.t(), String.t()) :: Phoenix.LiveView.JS.t()
  def update_theme_color(js \\ %JS{}, color) do
    JS.dispatch(js, "phx:update-theme-color", detail: %{color: color})
  end
end
