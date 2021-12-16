defmodule Dash.Central do
  use GenServer
  require Logger
  alias Dash.Central.{State, Config}

  # Public interface

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end




  # Private functions

  @impl true
  def init([]) do
    state = %State{
      config: Config.load(),
    }

    Logger.info("Dash.Central started")

    {:ok, state, {:continue, :start_adapters}}
  end

  @impl true
  def handle_continue(:start_adapters, state) do
    adapter_pids =
      for {adapter, adapter_config} <- Config.get_adapters(state.config) do
        Dash.Adapter.Supervisor.start_adapter!(adapter, adapter_config)
      end

    {:noreply, %{state | adapter_pids: adapter_pids}}
  end
end
