defmodule Level10Mailer.AccountsView do
  @moduledoc false

  use Phoenix.HTML
  import Phoenix.View

  alias Level10Web.Router.Helpers, as: Routes

  use Phoenix.View,
    root: "lib/level10_mailer/templates",
    namespace: Level10Mailer
end
