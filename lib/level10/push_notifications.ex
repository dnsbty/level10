defmodule Level10.PushNotifications do
  @moduledoc """
  Responsible for sending push notifications.
  """

  defmodule APNS do
    @moduledoc """
    Push notifications adapter for Apple Push Notification service.
    """
    use Pigeon.Dispatcher, otp_app: :level10

    alias Pigeon.APNS.Notification

    @spec create(String.t(), String.t(), String.t() | nil) :: Notification.t()
    def create(device_token, message, collapse_id \\ nil) do
      topic = Application.get_env(:level10, :app_bundle_identifier)

      %Notification{
        collapse_id: collapse_id,
        device_token: device_token,
        payload: %{"aps" => %{"alert" => message, "sound" => "default"}},
        priority: 10,
        push_type: "alert",
        topic: topic
      }
    end
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    children = []

    apns_disabled = Application.get_env(:level10, APNS)[:disabled?]
    children = if apns_disabled, do: children, else: [APNS | children]

    opts = [name: __MODULE__, strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Send a push notification.
  """
  @spec push(String.t(), String.t(), String.t() | nil) :: no_return()
  def push(device_token, message, collapse_id \\ nil) do
    device_token
    |> APNS.create(message, collapse_id)
    |> APNS.push()
  end
end
