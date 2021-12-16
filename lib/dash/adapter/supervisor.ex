defmodule Dash.Adapter.Supervisor do
  use DynamicSupervisor
  require Logger

  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_adapter!(adapter, adapter_config) do
    Logger.info("Dash.Adapter.Supervisor starting #{inspect adapter}")
    case DynamicSupervisor.start_child(__MODULE__, {adapter, adapter_config}) do
      {:ok, pid} -> pid
      {:ok, pid, _info} -> pid
      :ignore -> raise "Could not start adapter, :ignore"
      {:error, error} -> raise "Could not start adapter: #{inspect error}"
    end
  end
end
