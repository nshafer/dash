defmodule Dash.Adapter.Toggl do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    Logger.info("Dash.Adapter.Toggl started config: #{inspect config}")
    {:ok, %{config: config}}
  end


end
