defmodule Dash.Central do
  use GenServer
  require Logger
  alias Dash.Central.{State, Config}
  alias Dash.Project

  @pubsub Dash.PubSub
  @topic "central"

  # TODO: store config in ETS

  # Public interface

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  def get_config() do
    GenServer.call(__MODULE__, :get_config)
  end

  def week_start() do
    GenServer.call(__MODULE__, :week_start)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

  def add_project(name, params \\ []) do
    GenServer.call(__MODULE__, {:add_project, name, params})
  end

  def update_project(id, params) do
    GenServer.call(__MODULE__, {:update_project, id, params})
  end

  def get_project(id) do
    GenServer.call(__MODULE__, {:get_project, id})
  end

  def die() do
    GenServer.cast(__MODULE__, :die)
  end

  # Server

  @impl true
  def init([]) do
    state = %State{
      config: Config.load(),
    }

    Logger.info("Dash.Central (#{inspect self()}) started")

    {:ok, state, {:continue, :start_adapters}}
  end

  @impl true
  def handle_continue(:start_adapters, state) do
    adapter_pids =
      for {adapter, adapter_config} <- Config.get_adapters(state.config) do
        Dash.Adapter.Supervisor.start_adapter!(adapter, adapter_config)
      end

    {:noreply, %{state | adapter_pids: adapter_pids}, {:continue, :first_fetch}}
  end

  def handle_continue(:first_fetch, state) do
    for {adapter, _adapter_config} <- Config.get_adapters(state.config) do
      adapter.fetch()
    end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:week_start, _from, state) do
    now = Dash.Time.now!()
    day = Timex.beginning_of_week(now, state.config.week_start_day)
    time = Time.from_iso8601!(state.config.week_start_time)

    {:reply, %DateTime{day | hour: time.hour, minute: time.minute, second: time.second}, state}
  end

  def handle_call({:add_project, name, params}, _from, state) do
    project = %Project{
      id: System.unique_integer([:positive]),
      name: name,
      client: Keyword.get(params, :client, nil),
      color: Keyword.get(params, :color, Dash.Project.random_color()) |> maybe_parse_color(),
      billable?: Keyword.get(params, :billable?, false)
    }

    state = %{state | projects: Map.put(state.projects, project.id, project)}

    {:reply, {:ok, project}, state}
  end

  def handle_call({:update_project, id, params}, _from, state) do
    case Map.fetch(state.projects, id) do
      {:ok, project} ->
        new_project = %Project{
          name: Keyword.get(params, :name, project.name),
          client: Keyword.get(params, :client, project.client),
          color: Keyword.get(params, :color, project.color) |> maybe_parse_color(),
          billable?: Keyword.get(params, :billable?, project.billable?),
        }

        state = %{state | projects: Map.put(state.projects, id, new_project)}

        {:reply, {:ok, new_project}, state}

      :error ->
        :error
    end
  end

  def handle_call({:get_project, id}, _from, state) do
    {:reply, Map.get(state.projects, id), state}
  end

  @impl true
  def handle_cast(:die, _state) do
    Logger.info("Dash.Central dying")
    raise "die"
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("Dash.Central.terminate: #{inspect reason}")
    :ok
  end

  defp maybe_parse_color(color) when is_binary(color) and byte_size(color) == 7 do
    if String.starts_with?(color, "#") do
      color
    else
      nil
    end
  end
  defp maybe_parse_color(color) when is_binary(color) and byte_size(color) == 6 do
    "##{color}"
  end
  defp maybe_parse_color(_), do: nil
end
